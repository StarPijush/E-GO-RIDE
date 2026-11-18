/**
 * The booking store.
 *
 * The store owns the draft, the active ride and the status of the booking.
 * Two rules are absolute:
 * - a status never changes by hand: the draft steps use `canTransition`, a
 *   ride always changes through `transitionRide`;
 * - the persisted state is always valid: the status of the active ride and
 *   the status of the booking are the same.
 *
 * The store never imports `lib/mock/*` - the repositories (and the simulation
 * options) are the only way out of the app.
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import { RIDE_TIMINGS, STORAGE_KEYS } from '@/lib/config/constants';
import {
  canTransition,
  isCancelableStatus,
  transitionRide,
} from '@/lib/domain/booking-fsm';
import { calculateFare } from '@/lib/domain/fare';
import { advanceRide, resumeRide } from '@/lib/domain/ride-orchestrator';
import { persistedBookingSchema, rideSchema } from '@/lib/domain/schemas';
import type {
  AppError,
  AppErrorCode,
  BookingDraft,
  BookingStatus,
  CancellationReason,
  Place,
  Rating,
  Result,
  Ride,
  VehicleType,
} from '@/lib/domain/types';
import { getRepositories, getRideSimulationOptions } from '@/lib/repositories';
import { useAuthStore } from '@/stores/auth-store';
import { createEgoPersistStorage } from '@/stores/persist-storage';

/** The state of the booking. */
export interface BookingState {
  status: BookingStatus;
  draft: BookingDraft;
  activeRide: Ride | null;
  /** The ISO timestamp of the last tick (ephemeral, never persisted). */
  now: string;
  /** True once the persisted state was read. */
  hasHydrated: boolean;
  /** True while a repository call is running. */
  pending: boolean;
  lastError: AppError | null;
}

/** The rating a passenger gives. */
export interface RatingInput {
  stars: 1 | 2 | 3 | 4 | 5;
  comment?: string;
  tags?: string[];
}

/** The actions of the booking store. */
export interface BookingActions {
  startBooking(target: 'pickup' | 'destination'): void;
  choosePickup(place: Place): boolean;
  chooseDestination(place: Place): boolean;
  chooseVehicle(vehicle: VehicleType): boolean;
  choosePaymentMethod(paymentMethodId: string): void;
  reviewFare(): boolean;
  beginConfirmation(): boolean;
  /** Back to the pickup point (from the destination step). */
  backToPickup(): boolean;
  /** Back to the destination (from the vehicle step). */
  backToDestination(): boolean;
  /** Back to the vehicle (from the fare review). */
  backToVehicle(): boolean;
  /** Back to the fare review (from the confirmation). */
  backToFare(): boolean;
  confirmBooking(): Promise<Result<Ride>>;
  cancelBooking(reason: CancellationReason): Promise<Result<Ride>>;
  acknowledgeCancellation(): boolean;
  startTrip(): Promise<Result<Ride>>;
  /** The driver starts to approach the pickup point. */
  trackDriver(): Promise<Result<Ride>>;
  completeTrip(): Promise<Result<Ride>>;
  submitRating(rating: RatingInput): Promise<Result<Ride>>;
  /** The finished trip waits for the rating of the passenger. */
  proceedToRating(): boolean;
  skipRating(): boolean;
  retrySearch(): Promise<Result<Ride>>;
  resetBooking(): void;
  resetForLogout(): void;
  /** True once the persisted state was read. */
  setHasHydrated(value: boolean): void;
  tick(now?: string): Promise<void>;
  resume(): Promise<void>;
}

/** The complete store. */
export type BookingStore = BookingState & BookingActions;

/** Only one tick may run at a time. */
let tickInFlight: Promise<void> | null = null;

/** The statuses that belong to a ride that is on its way. */
const LIVE_STATUSES: readonly BookingStatus[] = [
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
  'tripInProgress',
  'tripCompleted',
  'awaitingRating',
];

export const useBookingStore = create<BookingStore>()(
  persist(
    (set, get) => {
      /** True when the FSM allows the step. */
      const canMove = (from: BookingStatus, to: BookingStatus): boolean =>
        canTransition(from, to);

      /** Remember an error and report the failure to the caller. */
      const fail = (code: AppErrorCode, message: string): false => {
        set({ lastError: { code, message } });
        return false;
      };

      /** The current time as an ISO timestamp. */
      const nowIso = (): string => new Date().toISOString();

      /** The deadline of the next step of a ride. */
      const deadlineOf = (from: string, durationMs: number): string =>
        new Date(Date.parse(from) + durationMs).toISOString();

      return {
        status: 'idle',
        draft: {},
        activeRide: null,
        now: '',
        hasHydrated: false,
        pending: false,
        lastError: null,

        startBooking: (target) => {
          const status = get().status;
          if (status !== 'idle') return;

          const to: BookingStatus = target === 'pickup' ? 'selectingPickup' : 'selectingDestination';
          if (!canMove(status, to)) {
            fail('invalid_transition', `The booking cannot start from "${status}".`);
            return;
          }

          set({ status: to, draft: {}, lastError: null });
        },

        choosePickup: (place) => {
          const status = get().status;
          if (status !== 'idle' && status !== 'selectingPickup' && status !== 'selectingDestination') {
            fail('invalid_transition', `A pickup point cannot be chosen in "${status}".`);
            return false;
          }

          if (status === 'idle') {
            // Two legal edges: idle -> selectingPickup -> selectingDestination.
            if (!canMove('idle', 'selectingPickup') || !canMove('selectingPickup', 'selectingDestination')) {
              fail('invalid_transition', 'The booking cannot start from "idle".');
              return false;
            }
          } else if (!canMove(status, 'selectingDestination')) {
            fail('invalid_transition', `A pickup point cannot be chosen in "${status}".`);
            return false;
          }

          set({
            draft: { ...get().draft, pickup: place },
            status: 'selectingDestination',
            lastError: null,
          });
          return true;
        },

        chooseDestination: (place) => {
          const status = get().status;
          if (status !== 'selectingPickup' && status !== 'selectingDestination') {
            fail('invalid_transition', `A destination cannot be chosen in "${status}".`);
            return false;
          }
          if (!canMove(status, 'selectingVehicle')) {
            fail('invalid_transition', `A destination cannot be chosen in "${status}".`);
            return false;
          }

          set({
            draft: { ...get().draft, destination: place },
            status: 'selectingVehicle',
            lastError: null,
          });
          return true;
        },

        chooseVehicle: (vehicle) => {
          const { status, draft } = get();
          if (status !== 'selectingDestination' && status !== 'selectingVehicle') {
            fail('invalid_transition', `A vehicle cannot be chosen in "${status}".`);
            return false;
          }
          if (!draft.pickup || !draft.destination) {
            fail('invalid_transition', 'Pickup and destination are needed to price a vehicle.');
            return false;
          }

          const fare = calculateFare(vehicle, draft.pickup, draft.destination);
          set({
            draft: { ...draft, vehicle, fare },
            status: 'selectingVehicle',
            lastError: null,
          });
          return true;
        },

        choosePaymentMethod: (paymentMethodId) => {
          set({ draft: { ...get().draft, paymentMethodId } });
        },

        reviewFare: () => {
          const { status, draft } = get();
          if (status !== 'selectingVehicle') {
            fail('invalid_transition', `The fare cannot be reviewed in "${status}".`);
            return false;
          }
          if (!draft.vehicle || !draft.fare) {
            fail('invalid_transition', 'A vehicle and a fare are needed to review the fare.');
            return false;
          }
          if (!canMove(status, 'reviewingFare')) {
            fail('invalid_transition', `The fare cannot be reviewed in "${status}".`);
            return false;
          }

          set({ status: 'reviewingFare', lastError: null });
          return true;
        },

        beginConfirmation: () => {
          const { status, draft } = get();
          if (status !== 'reviewingFare') {
            fail('invalid_transition', `The booking cannot be confirmed in "${status}".`);
            return false;
          }
          if (!draft.fare) {
            fail('invalid_transition', 'A fare is needed to confirm the booking.');
            return false;
          }
          if (!canMove(status, 'confirmingBooking')) {
            fail('invalid_transition', `The booking cannot be confirmed in "${status}".`);
            return false;
          }

          set({ status: 'confirmingBooking', lastError: null });
          return true;
        },

        backToPickup: () => {
          const status = get().status;
          if (status !== 'selectingDestination' || !canMove(status, 'selectingPickup')) {
            fail('invalid_transition', `The pickup point cannot be changed in "${status}".`);
            return false;
          }

          const draft = { ...get().draft };
          delete draft.destination;
          delete draft.vehicle;
          delete draft.fare;

          set({ status: 'selectingPickup', draft, lastError: null });
          return true;
        },

        backToDestination: () => {
          const status = get().status;
          if (status !== 'selectingVehicle' || !canMove(status, 'selectingDestination')) {
            fail('invalid_transition', `The destination cannot be changed in "${status}".`);
            return false;
          }

          const draft = { ...get().draft };
          delete draft.vehicle;
          delete draft.fare;

          set({ status: 'selectingDestination', draft, lastError: null });
          return true;
        },

        backToVehicle: () => {
          const status = get().status;
          if (status !== 'reviewingFare' || !canMove(status, 'selectingVehicle')) {
            fail('invalid_transition', `The vehicle cannot be changed in "${status}".`);
            return false;
          }

          // The vehicle and its fare stay - the card keeps its selection.
          set({ status: 'selectingVehicle', lastError: null });
          return true;
        },

        backToFare: () => {
          const status = get().status;
          if (status !== 'confirmingBooking' || !canMove(status, 'reviewingFare')) {
            fail('invalid_transition', `The fare cannot be reviewed in "${status}".`);
            return false;
          }

          set({ status: 'reviewingFare', lastError: null });
          return true;
        },

        confirmBooking: async () => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The booking is already being confirmed.' } };
          }
          if (state.status !== 'confirmingBooking') {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `The booking cannot be confirmed in "${state.status}".`,
              },
            };
          }

          const user = useAuthStore.getState().user;
          if (!user) {
            return { ok: false, error: { code: 'not_found', message: 'Please log in to book a ride.' } };
          }

          const { pickup, destination, vehicle, fare } = state.draft;
          if (!pickup || !destination || !vehicle || !fare) {
            return {
              ok: false,
              error: { code: 'invalid_transition', message: 'The booking is incomplete.' },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const repositories = getRepositories();

            let paymentMethodId = state.draft.paymentMethodId;
            if (!paymentMethodId) {
              const methods = await repositories.payments.list(user.id);
              if (methods.ok) {
                const preferred = methods.data.find((method) => method.isDefault) ?? methods.data[0];
                paymentMethodId = preferred?.id ?? 'cash-demo-001';
              } else {
                paymentMethodId = 'cash-demo-001';
              }
            }

            const created = await repositories.rides.create({
              userId: user.id,
              pickup,
              destination,
              vehicle,
              fare,
              paymentMethodId,
            });
            if (!created.ok) {
              set({ lastError: created.error });
              return created;
            }

            const now = nowIso();
            const transitioned = transitionRide(created.data, 'searchingDriver', now);
            if (!transitioned.ok) {
              set({ lastError: transitioned.error });
              return transitioned;
            }

            const ride: Ride = {
              ...transitioned.data,
              nextTransitionAt: deadlineOf(now, RIDE_TIMINGS.searchingDriverMs),
            };
            const saved = await repositories.rides.save(ride);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return saved;
            }

            set({
              activeRide: saved.data,
              status: 'searchingDriver',
              draft: { ...state.draft, paymentMethodId },
              lastError: null,
            });
            return saved;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The booking could not be confirmed. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        cancelBooking: async (reason) => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The ride is already being cancelled.' } };
          }
          const ride = state.activeRide;
          if (!ride) {
            return { ok: false, error: { code: 'not_found', message: 'There is no ride to cancel.' } };
          }
          if (!isCancelableStatus(state.status)) {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `A ride in "${state.status}" cannot be cancelled.`,
              },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const result = await getRepositories().rides.cancel(ride.id, reason);
            if (!result.ok) {
              set({ lastError: result.error });
              return result;
            }

            set({ activeRide: result.data, status: 'cancelled', lastError: null });
            return result;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The ride could not be cancelled. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        acknowledgeCancellation: () => {
          const status = get().status;
          if (!canMove(status, 'idle')) {
            fail('invalid_transition', `The cancellation cannot be acknowledged in "${status}".`);
            return false;
          }

          set({ status: 'idle', activeRide: null, draft: {}, lastError: null });
          return true;
        },

        startTrip: async () => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The ride is busy.' } };
          }
          const ride = state.activeRide;
          if (!ride) {
            return { ok: false, error: { code: 'not_found', message: 'There is no ride to start.' } };
          }
          if (state.status !== 'driverArrived') {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `The trip cannot start in "${state.status}".`,
              },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const now = nowIso();
            const transitioned = transitionRide(ride, 'tripInProgress', now);
            if (!transitioned.ok) {
              set({ lastError: transitioned.error });
              return transitioned;
            }

            const updated: Ride = {
              ...transitioned.data,
              nextTransitionAt: deadlineOf(now, RIDE_TIMINGS.tripInProgressMs),
            };
            const saved = await getRepositories().rides.save(updated);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return saved;
            }

            set({ activeRide: saved.data, status: 'tripInProgress' });
            return saved;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The trip could not be started. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        trackDriver: async () => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The ride is busy.' } };
          }
          const ride = state.activeRide;
          if (!ride) {
            return { ok: false, error: { code: 'not_found', message: 'There is no ride to track.' } };
          }
          if (state.status !== 'driverAssigned') {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `The driver cannot be tracked in "${state.status}".`,
              },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const now = nowIso();
            const transitioned = transitionRide(ride, 'driverArriving', now);
            if (!transitioned.ok) {
              set({ lastError: transitioned.error });
              return transitioned;
            }

            const updated: Ride = {
              ...transitioned.data,
              nextTransitionAt: deadlineOf(now, RIDE_TIMINGS.driverArrivingMs),
            };
            const saved = await getRepositories().rides.save(updated);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return saved;
            }

            set({ activeRide: saved.data, status: 'driverArriving' });
            return saved;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The driver could not be tracked. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        completeTrip: async () => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The ride is busy.' } };
          }
          const ride = state.activeRide;
          if (!ride) {
            return { ok: false, error: { code: 'not_found', message: 'There is no ride to complete.' } };
          }
          if (state.status !== 'tripInProgress') {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `The trip cannot be completed in "${state.status}".`,
              },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const now = nowIso();
            const transitioned = transitionRide(ride, 'tripCompleted', now);
            if (!transitioned.ok) {
              set({ lastError: transitioned.error });
              return transitioned;
            }

            const updated: Ride = {
              ...transitioned.data,
              nextTransitionAt: deadlineOf(now, RIDE_TIMINGS.tripCompletedMs),
            };
            const saved = await getRepositories().rides.save(updated);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return saved;
            }

            set({ activeRide: saved.data, status: 'tripCompleted' });
            return saved;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The trip could not be completed. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        submitRating: async ({ stars, comment, tags }) => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The ride is busy.' } };
          }
          const ride = state.activeRide;
          if (!ride) {
            return { ok: false, error: { code: 'not_found', message: 'There is no ride to rate.' } };
          }
          if (state.status !== 'awaitingRating') {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `A ride in "${state.status}" cannot be rated.`,
              },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const rating: Rating = {
              rideId: ride.id,
              stars,
              comment,
              tags: tags ?? [],
              createdAt: nowIso(),
            };
            const result = await getRepositories().rides.rate(ride.id, rating);
            if (!result.ok) {
              set({ lastError: result.error });
              return result;
            }

            set({ activeRide: result.data, status: 'rated', lastError: null });
            return result;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The rating could not be saved. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        proceedToRating: () => {
          const state = get();
          const ride = state.activeRide;
          if (!ride) {
            fail('invalid_transition', 'There is no ride to rate.');
            return false;
          }
          if (state.status !== 'tripCompleted') {
            fail(
              'invalid_transition',
              `The rating can only be given after the trip (this ride is "${state.status}").`,
            );
            return false;
          }

          // The transition clears the deadline of the finished trip.
          const transitioned = transitionRide(ride, 'awaitingRating', nowIso());
          if (!transitioned.ok) {
            fail('invalid_transition', transitioned.error.message);
            return false;
          }

          set({ activeRide: transitioned.data, status: 'awaitingRating', lastError: null });
          return true;
        },

        skipRating: () => {
          const status = get().status;
          if (status !== 'awaitingRating') {
            fail('invalid_transition', `The rating can only be skipped in "awaitingRating".`);
            return false;
          }

          // The ride stays in the history and can still be rated later.
          set({ status: 'idle', activeRide: null, draft: {}, lastError: null });
          return true;
        },

        retrySearch: async () => {
          const state = get();
          if (state.pending) {
            return { ok: false, error: { code: 'unknown', message: 'The ride is busy.' } };
          }
          const ride = state.activeRide;
          if (!ride) {
            return { ok: false, error: { code: 'not_found', message: 'There is no ride to retry.' } };
          }
          if (state.status !== 'failed') {
            return {
              ok: false,
              error: {
                code: 'invalid_transition',
                message: `Only a failed search can be retried (this one is "${state.status}").`,
              },
            };
          }

          set({ pending: true, lastError: null });
          try {
            const now = nowIso();
            const transitioned = transitionRide(ride, 'searchingDriver', now);
            if (!transitioned.ok) {
              set({ lastError: transitioned.error });
              return transitioned;
            }

            const updated: Ride = {
              ...transitioned.data,
              nextTransitionAt: deadlineOf(now, RIDE_TIMINGS.searchingDriverMs),
            };
            const saved = await getRepositories().rides.save(updated);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return saved;
            }

            set({ activeRide: saved.data, status: 'searchingDriver' });
            return saved;
          } catch {
            const error: AppError = {
              code: 'unknown',
              message: 'The search could not be retried. Please try again.',
            };
            set({ lastError: error });
            return { ok: false, error };
          } finally {
            set({ pending: false });
          }
        },

        resetBooking: () => {
          set({
            status: 'idle',
            draft: {},
            activeRide: null,
            lastError: null,
            pending: false,
          });
        },

        resetForLogout: () => {
          // The rides stay in the mock database - only the booking is reset.
          set({
            status: 'idle',
            draft: {},
            activeRide: null,
            lastError: null,
            pending: false,
          });
        },

        setHasHydrated: (value: boolean) => {
          set({ hasHydrated: value });
        },

        tick: async (nowInput) => {
          const now = nowInput ?? new Date().toISOString();
          set({ now });

          if (tickInFlight) {
            await tickInFlight;
            return;
          }

          const ride = get().activeRide;
          if (!ride || !ride.nextTransitionAt) return;
          if (Date.parse(now) < Date.parse(ride.nextTransitionAt)) return;

          const task = (async () => {
            const current = get().activeRide;
            // A newer request changed the ride in the meantime.
            if (!current || current.id !== ride.id || current.status !== ride.status) return;

            const advanced = advanceRide(current, now, getRideSimulationOptions());
            if (!advanced.ok) {
              set({ lastError: advanced.error });
              return;
            }
            if (advanced.data === current) return;

            const saved = await getRepositories().rides.save(advanced.data);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return;
            }

            // The booking follows the ride - also for the terminal states
            // (cancelled, rated) and for a failed search.
            set({ activeRide: saved.data, status: saved.data.status, lastError: null });
          })();

          tickInFlight = task;
          try {
            await task;
          } finally {
            if (tickInFlight === task) tickInFlight = null;
          }
        },

        resume: async () => {
          const state = get();
          const ride = state.activeRide;

          if (!ride) {
            if (LIVE_STATUSES.includes(state.status)) {
              set({ status: 'idle', draft: {} });
            }
            return;
          }

          const parsed = rideSchema.safeParse(ride);
          if (!parsed.success) {
            // A ride that cannot be read is dropped.
            set({ status: 'idle', draft: {}, activeRide: null, lastError: null });
            return;
          }

          if (state.status === 'rated' || state.status === 'cancelled') {
            set({ status: 'idle', draft: {}, activeRide: null, lastError: null });
            return;
          }
          if (state.status === 'awaitingRating') {
            // The ride waits for the rating of the passenger.
            set({ activeRide: parsed.data, status: 'awaitingRating' });
            return;
          }

          const now = nowIso();
          const resumed = resumeRide(parsed.data, now, getRideSimulationOptions());
          if (resumed !== parsed.data) {
            const saved = await getRepositories().rides.save(resumed);
            if (!saved.ok) {
              set({ lastError: saved.error });
              return;
            }
            set({ activeRide: saved.data, status: saved.data.status, now });
            return;
          }

          set({ activeRide: resumed, status: resumed.status, now });
        },
      };
    },
    {
      name: STORAGE_KEYS.booking,
      storage: createEgoPersistStorage(STORAGE_KEYS.booking, persistedBookingSchema),
      skipHydration: true,
      partialize: (state) => ({
        status: state.status,
        draft: state.draft,
        activeRide: state.activeRide,
      }),
      version: 1,
    },
  ),
);
