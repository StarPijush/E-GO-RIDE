/**
 * Pure, timer-free ride lifecycle orchestrator.
 *
 * The orchestrator never creates a timer and never touches storage: it turns
 * "the wall clock says it is time" into "the ride is in its next state". The
 * store owns the clock (`tick`), the orchestrator owns the rules.
 *
 * Deadlines are absolute (`nextTransitionAt`), so a refresh or a hidden tab
 * recovers the correct phase by calling `resumeRide`.
 */

import { RIDE_TIMINGS } from '@/lib/config/constants';
import { transitionRide } from '@/lib/domain/booking-fsm';
import type { BookingStatus, Driver, Result, Ride, VehicleType } from '@/lib/domain/types';

/** Maximum number of advances a single `resumeRide` call may perform. */
export const MAX_RESUME_STEPS = 8;

/** The single automatic step each live status performs. */
const SCHEDULED_TRANSITIONS: Partial<Record<BookingStatus, BookingStatus>> = {
  searchingDriver: 'driverAssigned',
  driverAssigned: 'driverArriving',
  driverArriving: 'driverArrived',
  driverArrived: 'tripInProgress',
  tripInProgress: 'tripCompleted',
  tripCompleted: 'awaitingRating',
};

/** Duration of each scheduled step, in milliseconds. */
const SCHEDULED_DURATIONS: Partial<Record<BookingStatus, number>> = {
  searchingDriver: RIDE_TIMINGS.searchingDriverMs,
  driverAssigned: RIDE_TIMINGS.driverAssignedMs,
  driverArriving: RIDE_TIMINGS.driverArrivingMs,
  driverArrived: RIDE_TIMINGS.driverArrivedAutoStartMs,
  tripInProgress: RIDE_TIMINGS.tripInProgressMs,
  tripCompleted: RIDE_TIMINGS.tripCompletedMs,
};

/**
 * The demo driver pool, used when the caller does not supply one.
 *
 * Five drivers around Jhargram (2 bike, 3 toto). The app passes its own pool
 * through `AdvanceOptions.drivers`; this pool keeps the pure module runnable
 * on its own.
 */
export const FALLBACK_DRIVERS: readonly Driver[] = [
  {
    id: 'driver-001',
    name: 'Rajan Kumar',
    rating: 4.8,
    ridesCompleted: 324,
    vehicleType: 'bike',
    vehicleModel: 'Hero Splendor',
    vehicleNumber: 'WB 32 D 1234',
    location: { lat: 22.455, lng: 86.902 },
    etaMinutes: 3,
  },
  {
    id: 'driver-002',
    name: 'Suresh Das',
    rating: 4.6,
    ridesCompleted: 211,
    vehicleType: 'toto',
    vehicleModel: 'E-Rickshaw',
    vehicleNumber: 'WB 32 E 5678',
    location: { lat: 22.455, lng: 86.902 },
    etaMinutes: 5,
  },
  {
    id: 'driver-003',
    name: 'Imran Ali',
    rating: 4.7,
    ridesCompleted: 158,
    vehicleType: 'bike',
    vehicleModel: 'Bajaj Pulsar',
    vehicleNumber: 'WB 32 D 7788',
    location: { lat: 22.4571, lng: 86.9038 },
    etaMinutes: 3,
  },
  {
    id: 'driver-004',
    name: 'Madan Mahato',
    rating: 4.9,
    ridesCompleted: 402,
    vehicleType: 'toto',
    vehicleModel: 'E-Rickshaw',
    vehicleNumber: 'WB 32 E 2211',
    location: { lat: 22.4512, lng: 86.8987 },
    etaMinutes: 5,
  },
  {
    id: 'driver-005',
    name: 'Bapi Roy',
    rating: 4.5,
    ridesCompleted: 97,
    vehicleType: 'toto',
    vehicleModel: 'E-Rickshaw',
    vehicleNumber: 'WB 32 E 9090',
    location: { lat: 22.4602, lng: 86.9075 },
    etaMinutes: 5,
  },
];

/** Options for {@link advanceRide} / {@link resumeRide}. */
export interface AdvanceOptions {
  /** Driver pool to pick the assigned driver from. Defaults to {@link FALLBACK_DRIVERS}. */
  drivers?: readonly Driver[];
  /** Offset applied to the deterministic driver selection. */
  seed?: number;
  /**
   * Simulates a failed driver search for the given ride.
   * A ride is never assigned without a driver, so a `true` result (or a pool
   * without a matching vehicle) moves the ride to `failed`.
   */
  shouldFail?: (rideId: string) => boolean;
}

/** Stable, non-cryptographic 32 bit hash (FNV-1a) of a string. */
export function stableHash(value: string): number {
  let hash = 0x811c9dc5;
  for (let index = 0; index < value.length; index += 1) {
    hash ^= value.charCodeAt(index);
    hash = Math.imul(hash, 0x01000193) >>> 0;
  }
  return hash >>> 0;
}

/**
 * Deterministic driver for a ride: the pool is filtered by vehicle type and
 * the ride id decides which candidate is picked, so the same ride always
 * gets the same driver.
 */
export function selectDriver(
  rideId: string,
  vehicleType: VehicleType,
  pool: readonly Driver[],
  seed = 0,
): Driver | undefined {
  const candidates = pool.filter((driver) => driver.vehicleType === vehicleType);
  if (candidates.length === 0) return undefined;
  const index = ((stableHash(rideId) + seed) % candidates.length + candidates.length) % candidates.length;
  return candidates[index];
}

/**
 * The deadline of the next automatic step for a ride, or `undefined` when the
 * status has no automatic step (manual / terminal).
 */
export function scheduleNextTransition(ride: Ride, now: string): string | undefined {
  const duration = SCHEDULED_DURATIONS[ride.status];
  if (duration === undefined) return undefined;
  const start = Date.parse(now);
  if (Number.isNaN(start)) return undefined;
  return new Date(start + duration).toISOString();
}

function resolveDriver(rideId: string, vehicle: VehicleType, options?: AdvanceOptions): Driver | undefined {
  const seed = options?.seed ?? 0;
  return selectDriver(rideId, vehicle, options?.drivers ?? FALLBACK_DRIVERS, seed);
}

/**
 * Advance a ride by at most one scheduled step.
 *
 * Returns the ride unchanged when the deadline has not been reached yet.
 * The transition is stamped with the deadline (not with `now`) so a catch-up
 * after a hidden tab produces an accurate timeline, and the next deadline is
 * derived from that same instant.
 */
export function advanceRide(ride: Ride, now: string, options?: AdvanceOptions): Result<Ride> {
  const deadline = ride.nextTransitionAt;
  if (!deadline) return { ok: true, data: ride };

  const nowMs = Date.parse(now);
  const deadlineMs = Date.parse(deadline);
  if (Number.isNaN(nowMs) || Number.isNaN(deadlineMs)) {
    return {
      ok: false,
      error: { code: 'unknown', message: `Cannot advance ride "${ride.id}": invalid timestamp.` },
    };
  }
  if (nowMs < deadlineMs) return { ok: true, data: ride };

  const scheduled = SCHEDULED_TRANSITIONS[ride.status];
  if (!scheduled) {
    return {
      ok: false,
      error: {
        code: 'invalid_transition',
        message: `Ride status "${ride.status}" has no scheduled transition.`,
      },
    };
  }

  // A ride is never assigned without a driver: when the search fails (or the
  // pool has no matching vehicle) the ride moves to `failed` instead.
  if (ride.status === 'searchingDriver') {
    const driver = resolveDriver(ride.id, ride.vehicle, options);
    const simulatedFailure = options?.shouldFail?.(ride.id) ?? false;

    if (simulatedFailure || !driver) {
      const failed = transitionRide(ride, 'failed', deadline);
      if (!failed.ok) return failed;
      return { ok: true, data: { ...failed.data, nextTransitionAt: undefined } };
    }

    const assigned = transitionRide(ride, scheduled, deadline);
    if (!assigned.ok) return assigned;
    return {
      ok: true,
      data: {
        ...assigned.data,
        driver,
        nextTransitionAt: scheduleNextTransition(assigned.data, deadline),
      },
    };
  }

  const transitioned = transitionRide(ride, scheduled, deadline);
  if (!transitioned.ok) return transitioned;

  return {
    ok: true,
    data: { ...transitioned.data, nextTransitionAt: scheduleNextTransition(transitioned.data, deadline) },
  };
}

/**
 * Catch a ride up with the wall clock after a refresh or a hidden tab.
 * Performs at most {@link MAX_RESUME_STEPS} advances and never repeats a
 * timeline event.
 */
export function resumeRide(ride: Ride, now: string, options?: AdvanceOptions): Ride {
  let current = ride;
  for (let step = 0; step < MAX_RESUME_STEPS; step += 1) {
    const result = advanceRide(current, now, options);
    if (!result.ok) break;
    if (result.data === current) break;
    current = result.data;
  }
  return finalizeIfTerminal(current);
}

/**
 * Idempotent finalization: makes sure a finished ride carries the matching
 * `completedAt` / `cancelledAt` stamp. It never changes the status.
 */
export function finalizeIfTerminal(ride: Ride): Ride {
  let next = ride;

  if (isCompleted(ride.status) && !ride.completedAt) {
    const completedEvent = [...ride.timeline].reverse().find((event) => event.status === 'tripCompleted');
    next = { ...next, completedAt: completedEvent?.at ?? ride.phaseStartedAt };
  }
  if (ride.status === 'cancelled' && !ride.cancelledAt) {
    next = { ...next, cancelledAt: ride.phaseStartedAt };
  }
  return next;
}

function isCompleted(status: BookingStatus): boolean {
  return status === 'tripCompleted' || status === 'awaitingRating' || status === 'rated';
}
