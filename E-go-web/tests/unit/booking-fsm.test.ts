import { describe, expect, it } from 'vitest';

import {
  allowedTransitions,
  bookingStatusLabels,
  canTransition,
  cancelableStatuses,
  completedStatuses,
  isCancelableStatus,
  isCompletedStatus,
  isTerminalStatus,
  terminalStatuses,
  transitionRide,
  TRANSITIONS,
} from '@/lib/domain/booking-fsm';
import { BOOKING_STATUSES, type BookingStatus, type Ride } from '@/lib/domain/types';

/**
 * Independent copy of the Dart `_allowedTransitions` map
 * (`E-go/lib/core/booking_state.dart`). The test compares the shipped table
 * against this expectation, so a change in one of them fails the suite.
 */
const EXPECTED_TRANSITIONS: Record<BookingStatus, readonly BookingStatus[]> = {
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

const EXPECTED_LABELS: Record<BookingStatus, string> = {
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

const CREATED_AT = '2026-01-01T00:00:00.000Z';

function makeRide(overrides: Partial<Ride> = {}): Ride {
  return {
    id: 'ride-1',
    userId: 'user-1',
    pickup: { id: 'p1', label: 'Pickup', address: 'Station road', kind: 'pickup', lat: 22.4529, lng: 86.9003 },
    destination: { id: 'd1', label: 'Destination', address: 'College road', kind: 'destination', lat: 22.4629, lng: 86.9103 },
    vehicle: 'bike',
    fare: {
      vehicle: 'bike',
      baseFare: 20,
      distanceFare: 20,
      platformFee: 3,
      total: 43,
      distanceKm: 2,
      estimatedMinutes: 9,
      estimatedArrivalMinutes: 3,
      currency: 'INR',
    },
    status: 'searchingDriver',
    paymentMethodId: 'cash-default',
    createdAt: CREATED_AT,
    phaseStartedAt: CREATED_AT,
    timeline: [{ status: 'searchingDriver', at: CREATED_AT }],
    ...overrides,
  };
}

describe('transition table', () => {
  it('matches the ported Dart map exactly', () => {
    expect(TRANSITIONS).toEqual(EXPECTED_TRANSITIONS);
  });

  it('covers all 16 statuses', () => {
    expect(BOOKING_STATUSES).toHaveLength(16);
    expect(Object.keys(TRANSITIONS).sort()).toEqual([...BOOKING_STATUSES].sort());
  });

  it('proves the full 16 x 16 matrix', () => {
    for (const from of BOOKING_STATUSES) {
      for (const to of BOOKING_STATUSES) {
        expect(canTransition(from, to), `${from} -> ${to}`).toBe(
          EXPECTED_TRANSITIONS[from].includes(to),
        );
      }
    }
  });

  it('exposes the allowed targets of a status', () => {
    expect(allowedTransitions('searchingDriver')).toEqual(['driverAssigned', 'failed', 'cancelled', 'idle']);
    expect(allowedTransitions('tripInProgress')).toEqual(['tripCompleted']);
  });
});

describe('transitionRide', () => {
  it('applies a valid transition and appends a timeline event', () => {
    const result = transitionRide(makeRide(), 'driverAssigned', '2026-01-01T00:00:06.000Z');
    expect(result.ok).toBe(true);
    if (!result.ok) return;

    expect(result.data.status).toBe('driverAssigned');
    expect(result.data.phaseStartedAt).toBe('2026-01-01T00:00:06.000Z');
    expect(result.data.timeline).toEqual([
      { status: 'searchingDriver', at: CREATED_AT },
      { status: 'driverAssigned', at: '2026-01-01T00:00:06.000Z' },
    ]);
    expect(result.data.createdAt).toBe(CREATED_AT);
  });

  it('rejects invalid transitions without throwing', () => {
    const result = transitionRide(makeRide({ status: 'tripInProgress' }), 'cancelled', CREATED_AT);
    expect(result.ok).toBe(false);
    if (result.ok) return;
    expect(result.error.code).toBe('invalid_transition');
  });

  it('rejects every transition that is not in the map', () => {
    for (const from of BOOKING_STATUSES) {
      for (const to of BOOKING_STATUSES) {
        const result = transitionRide(makeRide({ status: from }), to, CREATED_AT);
        expect(result.ok, `${from} -> ${to}`).toBe(EXPECTED_TRANSITIONS[from].includes(to));
      }
    }
  });

  it('stamps cancelled rides', () => {
    const result = transitionRide(makeRide(), 'cancelled', '2026-01-01T00:00:02.000Z');
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.cancelledAt).toBe('2026-01-01T00:00:02.000Z');
    expect(result.data.completedAt).toBeUndefined();
  });

  it('stamps completed rides', () => {
    const result = transitionRide(makeRide({ status: 'tripInProgress' }), 'tripCompleted', '2026-01-01T00:00:20.000Z');
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.completedAt).toBe('2026-01-01T00:00:20.000Z');
  });

  it('rejects an invalid timestamp', () => {
    const result = transitionRide(makeRide(), 'driverAssigned', 'not-a-date');
    expect(result.ok).toBe(false);
    if (result.ok) return;
    expect(result.error.code).toBe('unknown');
  });

  it('never duplicates a timeline event', () => {
    const at = '2026-01-01T00:00:06.000Z';
    const ride = makeRide({
      status: 'driverAssigned',
      timeline: [
        { status: 'searchingDriver', at: CREATED_AT },
        { status: 'driverAssigned', at },
        { status: 'driverArriving', at },
      ],
    });
    const result = transitionRide(ride, 'driverArriving', at);
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.timeline).toHaveLength(3);
  });
});

describe('cancellation whitelist', () => {
  it('lists exactly the four live cancel edges', () => {
    expect(cancelableStatuses).toEqual([
      'searchingDriver',
      'driverAssigned',
      'driverArriving',
      'driverArrived',
    ]);
  });

  it('only allows cancelling from those statuses', () => {
    for (const from of BOOKING_STATUSES) {
      expect(canTransition(from, 'cancelled'), from).toBe(cancelableStatuses.includes(from));
      expect(isCancelableStatus(from), from).toBe(cancelableStatuses.includes(from));
    }
  });

  it('never allows cancelling a running trip', () => {
    expect(isCancelableStatus('tripInProgress')).toBe(false);
    expect(isCancelableStatus('tripCompleted')).toBe(false);
  });
});

describe('status labels', () => {
  it('matches the ported Dart labels', () => {
    expect(bookingStatusLabels).toEqual(EXPECTED_LABELS);
  });
});

describe('terminal helpers', () => {
  it('classifies terminal and completed statuses', () => {
    expect(terminalStatuses).toEqual(['rated', 'cancelled', 'failed']);
    expect(completedStatuses).toEqual(['tripCompleted', 'awaitingRating', 'rated']);

    expect(isTerminalStatus('rated')).toBe(true);
    expect(isTerminalStatus('cancelled')).toBe(true);
    expect(isTerminalStatus('failed')).toBe(true);
    expect(isTerminalStatus('tripInProgress')).toBe(false);

    expect(isCompletedStatus('tripCompleted')).toBe(true);
    expect(isCompletedStatus('awaitingRating')).toBe(true);
    expect(isCompletedStatus('rated')).toBe(true);
    expect(isCompletedStatus('cancelled')).toBe(false);
  });
});
