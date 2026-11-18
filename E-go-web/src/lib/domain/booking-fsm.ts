/**
 * Booking finite state machine.
 *
 * The transition table is a **line-for-line port** of
 * `E-go/lib/core/booking_state.dart` (`_allowedTransitions`). Do not
 * "improve" it: there is deliberately no cancel edge from `tripInProgress`,
 * `tripCompleted` only goes to `awaitingRating`, skipping a rating goes to
 * `idle`, and the early selection steps may jump straight to
 * `selectingVehicle` / `confirmingBooking`.
 *
 * Every status change in the app goes through `transitionRide` (rides) or
 * `canTransition` (guards) - never by assigning `ride.status` directly.
 */

import type { BookingStatus, Result, Ride, RideStatus } from '@/lib/domain/types';

/**
 * Allowed next statuses per status.
 * Ported verbatim from the Dart `_allowedTransitions` map.
 */
export const TRANSITIONS: Record<BookingStatus, readonly BookingStatus[]> = {
  idle: ['selectingPickup', 'selectingDestination', 'selectingVehicle'],
  selectingPickup: ['idle', 'selectingDestination', 'selectingVehicle'],
  selectingDestination: ['idle', 'selectingPickup', 'selectingVehicle'],
  selectingVehicle: ['selectingDestination', 'reviewingFare', 'confirmingBooking', 'idle'],
  reviewingFare: ['selectingVehicle', 'confirmingBooking', 'idle'],
  confirmingBooking: ['reviewingFare', 'searchingDriver', 'idle'],
  searchingDriver: ['driverAssigned', 'failed', 'cancelled', 'idle'],
  driverAssigned: ['driverArriving', 'cancelled'],
  driverArriving: ['driverArrived', 'cancelled'],
  driverArrived: ['tripInProgress', 'cancelled'],
  tripInProgress: ['tripCompleted'],
  tripCompleted: ['awaitingRating'],
  awaitingRating: ['rated', 'idle'],
  rated: ['idle'],
  cancelled: ['idle'],
  failed: ['idle', 'searchingDriver'],
};

/**
 * Statuses that end a ride. `failed` can still be retried (back to
 * `searchingDriver`) or reset, but no automatic progress happens from it.
 */
export const terminalStatuses: readonly BookingStatus[] = ['rated', 'cancelled', 'failed'];

/** Statuses that mean the passenger has arrived (the trip itself completed). */
export const completedStatuses: readonly BookingStatus[] = ['tripCompleted', 'awaitingRating', 'rated'];

/**
 * Statuses a ride may be cancelled from - the only cancel edges in the
 * ported FSM. `tripInProgress` and later are deliberately excluded.
 */
export const cancelableStatuses: readonly BookingStatus[] = [
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
];

/**
 * Human readable status labels, ported verbatim from the Dart
 * `bookingStatusLabel` function. The wording of these titles is frozen.
 */
export const bookingStatusLabels: Record<BookingStatus, string> = {
  idle: 'Ready',
  selectingPickup: 'Select pickup',
  selectingDestination: 'Select destination',
  selectingVehicle: 'Choose vehicle',
  reviewingFare: 'Review fare',
  confirmingBooking: 'Confirm booking',
  searchingDriver: 'Finding driver',
  driverAssigned: 'Driver assigned',
  driverArriving: 'Driver arriving',
  driverArrived: 'Driver arrived',
  tripInProgress: 'Trip in progress',
  tripCompleted: 'Trip completed',
  awaitingRating: 'Rate your ride',
  rated: 'Rated',
  cancelled: 'Cancelled',
  failed: 'Search failed',
};

/** True when `from -> to` is an edge of the FSM. Unknown statuses are rejected. */
export function canTransition(from: BookingStatus, to: BookingStatus): boolean {
  return TRANSITIONS[from]?.includes(to) ?? false;
}

/** The statuses reachable from `from` (empty for unknown statuses). */
export function allowedTransitions(from: BookingStatus): readonly BookingStatus[] {
  return TRANSITIONS[from] ?? [];
}

/** True when the status ends the ride (no automatic progress follows). */
export function isTerminalStatus(status: BookingStatus): boolean {
  return terminalStatuses.includes(status);
}

/** True when the trip itself is finished (receipt / history write). */
export function isCompletedStatus(status: BookingStatus): boolean {
  return completedStatuses.includes(status);
}

/** True when the ride may still be cancelled. */
export function isCancelableStatus(status: BookingStatus): boolean {
  return cancelableStatuses.includes(status);
}

/** Appends a timeline event, ignoring an exact duplicate of the last state. */
function appendTimelineEvent(
  timeline: Ride['timeline'],
  status: RideStatus,
  at: string,
): Ride['timeline'] {
  const duplicate = timeline.some((event) => event.status === status && event.at === at);
  if (duplicate) return timeline;
  return [...timeline, { status, at }];
}

/**
 * Apply a status change to a ride.
 *
 * The new ride carries the new status, a refreshed `phaseStartedAt`, the
 * appended timeline event and the matching `completedAt` / `cancelledAt`
 * stamp. `nextTransitionAt` is cleared because the previous deadline belongs
 * to the finished phase - the orchestrator schedules the next one.
 *
 * Invalid transitions return `{ ok: false, error: { code: 'invalid_transition' } }`
 * and never throw.
 */
export function transitionRide(ride: Ride, to: BookingStatus, at: string): Result<Ride> {
  const from = ride.status;
  if (!canTransition(from, to)) {
    return {
      ok: false,
      error: {
        code: 'invalid_transition',
        message: `Cannot move a ride from "${from}" to "${to}".`,
      },
    };
  }
  if (Number.isNaN(Date.parse(at))) {
    return {
      ok: false,
      error: {
        code: 'unknown',
        message: `Invalid transition timestamp "${at}".`,
      },
    };
  }

  const next: Ride = {
    ...ride,
    status: to,
    phaseStartedAt: at,
    nextTransitionAt: undefined,
    timeline: appendTimelineEvent(ride.timeline, to, at),
  };

  if (to === 'cancelled') {
    next.cancelledAt = at;
  } else if (to === 'tripCompleted' && !next.completedAt) {
    // The trip completion time is the moment the trip finished - not the
    // later receipt/rating phases. Never overwrite it once set.
    next.completedAt = at;
  }

  return { ok: true, data: next };
}
