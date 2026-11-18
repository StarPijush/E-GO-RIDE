import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

import { transitionRide } from '@/lib/domain/booking-fsm';
import { calculateFare } from '@/lib/domain/fare';
import type { Place } from '@/lib/domain/types';
import type { useBookingStore } from '@/stores/booking-store';

type BookingStoreApi = typeof useBookingStore;

const PICKUP: Place = {
  id: 'place-001',
  label: 'Jhargram Railway Station',
  address: 'Jhargram, West Bengal',
  kind: 'pickup',
  lat: 22.4529,
  lng: 86.9003,
};

const DESTINATION: Place = {
  id: 'place-006',
  label: 'Jhargram College',
  address: 'Jhargram, West Bengal',
  kind: 'destination',
  lat: 22.461,
  lng: 86.912,
};

const USER = {
  id: 'demo-ego-001',
  fullName: 'E-GO Demo User',
  phone: '+919000000001',
  profileComplete: true,
  createdAt: '2026-01-01T00:00:00.000Z',
};

const SESSION = {
  userId: 'demo-ego-001',
  token: 'token',
  issuedAt: '2026-01-01T00:00:00.000Z',
  expiresAt: '2099-01-01T00:00:00.000Z',
};

/** Load the stores and the repositories freshly. */
async function setup() {
  vi.resetModules();
  vi.stubEnv('NEXT_PUBLIC_ENABLE_DEMO_AUTH', 'true');

  const repositories = await import('@/lib/repositories');
  const bookingModule = await import('@/stores/booking-store');
  const authModule = await import('@/stores/auth-store');
  const db = await import('@/lib/mock/db');

  repositories.setRepositoriesForTests(repositories.createRepositories({ latencyMs: 0 }));
  db.resetDb();

  bookingModule.useBookingStore.setState({
    status: 'idle',
    draft: {},
    activeRide: null,
    now: '',
    hasHydrated: false,
    pending: false,
    lastError: null,
  });
  authModule.useAuthStore.setState({
    user: USER,
    session: SESSION,
    onboardingSeen: true,
    hasHydrated: true,
    pending: null,
    lastError: null,
    otpCooldownUntil: null,
  });

  return { booking: bookingModule.useBookingStore, db };
}

/** Run the tick exactly at the deadline of the active ride. */
async function tickNext(booking: BookingStoreApi): Promise<void> {
  const deadline = booking.getState().activeRide?.nextTransitionAt;
  if (!deadline) throw new Error('The ride has no deadline.');
  await booking.getState().tick(deadline);
}

/** Walk the draft up to the confirmation. */
async function driveToConfirmation(booking: BookingStoreApi): Promise<void> {
  booking.getState().startBooking('pickup');
  booking.getState().choosePickup(PICKUP);
  booking.getState().chooseDestination(DESTINATION);
  booking.getState().chooseVehicle('bike');
  booking.getState().reviewFare();
  booking.getState().beginConfirmation();
}

/** Book a ride and wait for the driver. */
async function driveToSearchingDriver(booking: BookingStoreApi): Promise<void> {
  await driveToConfirmation(booking);
  const result = await booking.getState().confirmBooking();
  if (!result.ok) throw new Error('The booking could not be confirmed.');
}

/** Book a ride and run it until the passenger may rate it. */
async function driveToAwaitingRating(booking: BookingStoreApi): Promise<void> {
  await driveToSearchingDriver(booking);
  await tickNext(booking);
  await tickNext(booking);
  await tickNext(booking);
  await booking.getState().startTrip();
  await tickNext(booking);
  await tickNext(booking);
}

beforeEach(() => {
  window.localStorage.clear();
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.resetModules();
});

describe('the back actions', () => {
  it('goes back to the pickup and clears the later steps', async () => {
    const { booking } = await setup();

    booking.getState().startBooking('pickup');
    booking.getState().choosePickup(PICKUP);
    booking.getState().chooseDestination(DESTINATION);
    booking.getState().chooseVehicle('bike');
    booking.getState().reviewFare();

    // Walk back to the destination - it keeps the chosen destination.
    expect(booking.getState().backToVehicle()).toBe(true);
    expect(booking.getState().backToDestination()).toBe(true);
    expect(booking.getState().status).toBe('selectingDestination');
    expect(booking.getState().draft.destination).toBeDefined();

    expect(booking.getState().backToPickup()).toBe(true);

    const state = booking.getState();
    expect(state.status).toBe('selectingPickup');
    expect(state.draft.destination).toBeUndefined();
    expect(state.draft.vehicle).toBeUndefined();
    expect(state.draft.fare).toBeUndefined();
    expect(state.draft.pickup).toBeDefined();
  });

  it('goes back to the destination and clears the vehicle', async () => {
    const { booking } = await setup();

    booking.getState().startBooking('pickup');
    booking.getState().choosePickup(PICKUP);
    booking.getState().chooseDestination(DESTINATION);
    booking.getState().chooseVehicle('bike');

    expect(booking.getState().backToDestination()).toBe(true);

    const state = booking.getState();
    expect(state.status).toBe('selectingDestination');
    expect(state.draft.vehicle).toBeUndefined();
    expect(state.draft.fare).toBeUndefined();
    expect(state.draft.pickup).toBeDefined();
    expect(state.draft.destination).toBeDefined();
  });

  it('goes back to the vehicle and keeps the choice', async () => {
    const { booking } = await setup();

    booking.getState().startBooking('pickup');
    booking.getState().choosePickup(PICKUP);
    booking.getState().chooseDestination(DESTINATION);
    booking.getState().chooseVehicle('bike');
    booking.getState().reviewFare();

    expect(booking.getState().backToVehicle()).toBe(true);

    const state = booking.getState();
    expect(state.status).toBe('selectingVehicle');
    expect(state.draft.vehicle).toBe('bike');
    expect(state.draft.fare).toBeDefined();
  });

  it('goes back to the fare review', async () => {
    const { booking } = await setup();
    await driveToConfirmation(booking);

    expect(booking.getState().backToFare()).toBe(true);
    expect(booking.getState().status).toBe('reviewingFare');
  });

  it('refuses a back action from the wrong status', async () => {
    const { booking } = await setup();

    expect(booking.getState().backToPickup()).toBe(false);
    expect(booking.getState().lastError?.code).toBe('invalid_transition');

    expect(booking.getState().backToDestination()).toBe(false);
    expect(booking.getState().lastError?.code).toBe('invalid_transition');

    expect(booking.getState().backToVehicle()).toBe(false);
    expect(booking.getState().lastError?.code).toBe('invalid_transition');

    expect(booking.getState().backToFare()).toBe(false);
    expect(booking.getState().lastError?.code).toBe('invalid_transition');

    expect(booking.getState().status).toBe('idle');
  });
});

describe('proceedToRating', () => {
  it('moves a finished trip to the rating', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);
    await tickNext(booking);
    await tickNext(booking);
    await tickNext(booking);
    await booking.getState().startTrip();
    await tickNext(booking);
    expect(booking.getState().status).toBe('tripCompleted');

    expect(booking.getState().proceedToRating()).toBe(true);

    const state = booking.getState();
    expect(state.status).toBe('awaitingRating');
    expect(state.activeRide?.nextTransitionAt).toBeUndefined();
  });

  it('refuses to rate a ride that is not finished', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);

    expect(booking.getState().proceedToRating()).toBe(false);
    expect(booking.getState().lastError?.code).toBe('invalid_transition');
    expect(booking.getState().status).toBe('searchingDriver');
  });
});

describe('trackDriver', () => {
  it('moves an assigned driver to the arriving phase', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);
    await tickNext(booking);

    expect(booking.getState().status).toBe('driverAssigned');

    const result = await booking.getState().trackDriver();
    expect(result.ok).toBe(true);

    const state = booking.getState();
    expect(state.status).toBe('driverArriving');
    expect(state.activeRide?.nextTransitionAt).toBeDefined();
    expect(Date.parse(state.activeRide?.nextTransitionAt ?? '')).toBeGreaterThan(Date.now());
  });

  it('refuses to track from the wrong status', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);

    const result = await booking.getState().trackDriver();
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('invalid_transition');
    expect(booking.getState().status).toBe('searchingDriver');
  });
});

describe('the booking flow', () => {
  it('walks from the pickup to the rating', async () => {
    const { booking } = await setup();

    booking.getState().startBooking('pickup');
    expect(booking.getState().status).toBe('selectingPickup');

    expect(booking.getState().choosePickup(PICKUP)).toBe(true);
    expect(booking.getState().status).toBe('selectingDestination');
    expect(booking.getState().draft.pickup).toEqual(PICKUP);

    expect(booking.getState().chooseDestination(DESTINATION)).toBe(true);
    expect(booking.getState().status).toBe('selectingVehicle');

    expect(booking.getState().chooseVehicle('bike')).toBe(true);
    expect(booking.getState().draft.fare).toEqual(calculateFare('bike', PICKUP, DESTINATION));

    expect(booking.getState().reviewFare()).toBe(true);
    expect(booking.getState().status).toBe('reviewingFare');

    expect(booking.getState().beginConfirmation()).toBe(true);
    expect(booking.getState().status).toBe('confirmingBooking');

    const confirmed = await booking.getState().confirmBooking();
    expect(confirmed.ok).toBe(true);
    expect(booking.getState().status).toBe('searchingDriver');
    expect(booking.getState().activeRide?.status).toBe('searchingDriver');
    expect(booking.getState().activeRide?.driver).toBeUndefined();
    expect(booking.getState().activeRide?.nextTransitionAt).toBeDefined();
    expect(booking.getState().pending).toBe(false);

    await tickNext(booking);
    expect(booking.getState().status).toBe('driverAssigned');
    expect(booking.getState().activeRide?.driver?.vehicleType).toBe('bike');

    await tickNext(booking);
    expect(booking.getState().status).toBe('driverArriving');

    await tickNext(booking);
    expect(booking.getState().status).toBe('driverArrived');

    const started = await booking.getState().startTrip();
    expect(started.ok).toBe(true);
    expect(booking.getState().status).toBe('tripInProgress');

    await tickNext(booking);
    expect(booking.getState().status).toBe('tripCompleted');

    await tickNext(booking);
    expect(booking.getState().status).toBe('awaitingRating');

    const rated = await booking.getState().submitRating({
      stars: 5,
      comment: 'Great driver',
      tags: ['On time'],
    });
    expect(rated.ok).toBe(true);
    expect(booking.getState().status).toBe('rated');
    expect(booking.getState().activeRide?.rating?.stars).toBe(5);

    booking.getState().resetBooking();
    expect(booking.getState().status).toBe('idle');
    expect(booking.getState().activeRide).toBeNull();
    expect(booking.getState().draft).toEqual({});
  });

  it('refuses a destination before the flow started', async () => {
    const { booking } = await setup();

    expect(booking.getState().chooseDestination(DESTINATION)).toBe(false);
    expect(booking.getState().status).toBe('idle');
    expect(booking.getState().lastError?.code).toBe('invalid_transition');
  });

  it('creates only one ride for two concurrent confirmations', async () => {
    const { booking, db } = await setup();
    await driveToConfirmation(booking);

    const [first, second] = await Promise.all([
      booking.getState().confirmBooking(),
      booking.getState().confirmBooking(),
    ]);

    expect(first.ok).toBe(true);
    expect(second.ok).toBe(false);
    if (!second.ok) expect(second.error.code).toBe('unknown');
    expect(db.loadDb().rides).toHaveLength(1);
  });

  it('cancels a ride that is still cancelable', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);

    const cancelled = await booking.getState().cancelBooking('changed_plan');

    expect(cancelled.ok).toBe(true);
    expect(booking.getState().status).toBe('cancelled');
    expect(booking.getState().activeRide?.cancellationReason).toBe('changed_plan');
    expect(booking.getState().activeRide?.cancelledAt).toBeDefined();

    expect(booking.getState().acknowledgeCancellation()).toBe(true);
    expect(booking.getState().status).toBe('idle');
    expect(booking.getState().activeRide).toBeNull();
  });

  it('refuses to cancel a ride that is already on its way', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);
    await tickNext(booking);
    await tickNext(booking);
    await tickNext(booking);
    await booking.getState().startTrip();
    expect(booking.getState().status).toBe('tripInProgress');

    const result = await booking.getState().cancelBooking('changed_plan');

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('invalid_transition');
    expect(booking.getState().status).toBe('tripInProgress');
  });

  it('retries a failed search and schedules a new deadline', async () => {
    const { booking } = await setup();
    await driveToSearchingDriver(booking);

    const ride = booking.getState().activeRide;
    if (!ride) throw new Error('There is no active ride.');
    const failed = transitionRide(ride, 'failed', new Date().toISOString());
    if (!failed.ok) throw new Error('The ride could not fail.');
    booking.setState({ activeRide: failed.data, status: 'failed' });

    const retried = await booking.getState().retrySearch();

    expect(retried.ok).toBe(true);
    expect(booking.getState().status).toBe('searchingDriver');
    expect(booking.getState().activeRide?.nextTransitionAt).toBeDefined();
  });

  it('keeps the ride in the history when the rating is skipped', async () => {
    const { booking, db } = await setup();
    await driveToAwaitingRating(booking);
    const rideId = booking.getState().activeRide?.id;

    expect(booking.getState().skipRating()).toBe(true);
    expect(booking.getState().status).toBe('idle');
    expect(booking.getState().activeRide).toBeNull();

    const stored = db.loadDb().rides.find((ride) => ride.id === rideId);
    expect(stored?.status).toBe('awaitingRating');
  });

  it('persists only the status, the draft and the active ride', async () => {
    const { booking } = await setup();

    booking.getState().startBooking('pickup');

    const raw = window.localStorage.getItem('ego:booking:v1');
    expect(raw).not.toBeNull();
    const stored = JSON.parse(raw ?? '{}') as {
      schemaVersion: number;
      data: Record<string, unknown>;
    };
    expect(stored.schemaVersion).toBe(1);
    expect(Object.keys(stored.data).sort()).toEqual(['activeRide', 'draft', 'status']);
  });

  it('resets the booking on logout but keeps the ride history', async () => {
    const { booking, db } = await setup();
    await driveToSearchingDriver(booking);
    const rideId = booking.getState().activeRide?.id;

    booking.getState().resetForLogout();

    expect(booking.getState().status).toBe('idle');
    expect(booking.getState().activeRide).toBeNull();
    expect(db.loadDb().rides.some((ride) => ride.id === rideId)).toBe(true);
  });
});
