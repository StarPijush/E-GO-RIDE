import { describe, expect, it } from 'vitest';

import { TRANSITIONS } from '@/lib/domain/booking-fsm';
import {
  advanceRide,
  FALLBACK_DRIVERS,
  finalizeIfTerminal,
  resumeRide,
  scheduleNextTransition,
  selectDriver,
  stableHash,
} from '@/lib/domain/ride-orchestrator';
import { BOOKING_STATUSES, type Driver, type Ride } from '@/lib/domain/types';

const T0 = '2026-01-01T00:00:00.000Z';
const at = (seconds: number): string => new Date(Date.parse(T0) + seconds * 1000).toISOString();

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
    createdAt: T0,
    phaseStartedAt: T0,
    nextTransitionAt: at(6),
    timeline: [{ status: 'searchingDriver', at: T0 }],
    ...overrides,
  };
}

const POOL: readonly Driver[] = [
  { id: 'bike-a', name: 'Bike A', rating: 4.5, ridesCompleted: 100, vehicleType: 'bike', vehicleModel: 'Splendor', vehicleNumber: 'WB 1 A 1', location: { lat: 22.45, lng: 86.9 }, etaMinutes: 3 },
  { id: 'bike-b', name: 'Bike B', rating: 4.7, ridesCompleted: 200, vehicleType: 'bike', vehicleModel: 'Pulsar', vehicleNumber: 'WB 1 A 2', location: { lat: 22.45, lng: 86.9 }, etaMinutes: 3 },
  { id: 'toto-a', name: 'Toto A', rating: 4.6, ridesCompleted: 300, vehicleType: 'toto', vehicleModel: 'E-Rickshaw', vehicleNumber: 'WB 1 T 1', location: { lat: 22.45, lng: 86.9 }, etaMinutes: 5 },
];

describe('scheduleNextTransition', () => {
  it('schedules the documented deadlines', () => {
    const cases: Array<[Ride['status'], string]> = [
      ['searchingDriver', at(6)],
      ['driverAssigned', at(4)],
      ['driverArriving', at(12)],
      ['driverArrived', at(30)],
      ['tripInProgress', at(15)],
      ['tripCompleted', at(0.5)],
    ];
    for (const [status, expected] of cases) {
      expect(scheduleNextTransition(makeRide({ status }), T0), status).toBe(expected);
    }
  });

  it('schedules nothing for manual or terminal statuses', () => {
    for (const status of ['idle', 'rated', 'cancelled', 'failed', 'awaitingRating'] as const) {
      expect(scheduleNextTransition(makeRide({ status }), T0), status).toBeUndefined();
    }
  });
});

describe('advanceRide', () => {
  it('is a no-op before the deadline', () => {
    const ride = makeRide();
    const result = advanceRide(ride, at(5));
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data).toBe(ride);
    expect(result.data.status).toBe('searchingDriver');
    expect(result.data.timeline).toHaveLength(1);
  });

  it('assigns a matching driver after the 6 s search', () => {
    const result = advanceRide(makeRide(), at(6), { drivers: POOL });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('driverAssigned');
    expect(result.data.driver).toBeDefined();
    expect(result.data.driver?.vehicleType).toBe('bike');
    expect(result.data.phaseStartedAt).toBe(at(6));
    expect(result.data.nextTransitionAt).toBe(at(10));
    expect(result.data.timeline.at(-1)).toEqual({ status: 'driverAssigned', at: at(6) });
  });

  it('moves to driver arriving 4 s later', () => {
    const assigned = advanceRide(makeRide(), at(6), { drivers: POOL });
    expect(assigned.ok).toBe(true);
    if (!assigned.ok) return;

    const result = advanceRide(assigned.data, at(10), { drivers: POOL });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('driverArriving');
    expect(result.data.nextTransitionAt).toBe(at(22));
  });

  it('moves to driver arrived 12 s later', () => {
    const assigned = advanceRide(makeRide(), at(6), { drivers: POOL });
    if (!assigned.ok) throw new Error('advance failed');
    const arriving = advanceRide(assigned.data, at(10), { drivers: POOL });
    if (!arriving.ok) throw new Error('advance failed');

    const result = advanceRide(arriving.data, at(22), { drivers: POOL });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('driverArrived');
    expect(result.data.nextTransitionAt).toBe(at(52));
  });

  it('auto starts the trip 30 s after the driver arrived', () => {
    const arrived = makeRide({
      status: 'driverArrived',
      phaseStartedAt: at(22),
      nextTransitionAt: at(52),
      timeline: [
        { status: 'searchingDriver', at: T0 },
        { status: 'driverArrived', at: at(22) },
      ],
    });

    const result = advanceRide(arrived, at(52));
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('tripInProgress');
    expect(result.data.nextTransitionAt).toBe(at(67));
  });

  it('completes the trip 15 s after it started', () => {
    const running = makeRide({
      status: 'tripInProgress',
      phaseStartedAt: at(52),
      nextTransitionAt: at(67),
      timeline: [{ status: 'tripInProgress', at: at(52) }],
    });

    const result = advanceRide(running, at(67));
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('tripCompleted');
    expect(result.data.completedAt).toBe(at(67));
    expect(result.data.nextTransitionAt).toBe(at(67.5));
  });

  it('moves to awaiting rating 500 ms after the trip completed', () => {
    const completed = makeRide({
      status: 'tripCompleted',
      nextTransitionAt: at(0.5),
      timeline: [{ status: 'tripCompleted', at: at(67) }],
    });

    const result = advanceRide(completed, at(67.5));
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('awaitingRating');
    expect(result.data.nextTransitionAt).toBeUndefined();
  });

  it('never moves to a status outside the transition map', () => {
    for (const status of BOOKING_STATUSES) {
      const scheduled = scheduleNextTransition(makeRide({ status }), T0) !== undefined;
      const result = advanceRide(makeRide({ status, nextTransitionAt: at(0) }), at(1));
      expect(result.ok, status).toBe(scheduled);
      if (!result.ok || result.data.status === status) continue;
      expect(TRANSITIONS[status], `${status} -> ${result.data.status}`).toContain(result.data.status);
    }
  });
});

describe('resumeRide', () => {
  it('catches up through several phases after 60 s without duplicating timeline events', () => {
    const resumed = resumeRide(makeRide(), at(60), { drivers: POOL });

    expect(resumed.status).toBe('tripInProgress');
    expect(resumed.timeline.map((event) => event.status)).toEqual([
      'searchingDriver',
      'driverAssigned',
      'driverArriving',
      'driverArrived',
      'tripInProgress',
    ]);
    expect(resumed.timeline.map((event) => event.at)).toEqual([T0, at(6), at(10), at(22), at(52)]);
    expect(resumed.driver?.vehicleType).toBe('bike');
    expect(resumed.nextTransitionAt).toBe(at(67));
  });

  it('is idempotent: resuming again does not append duplicate events', () => {
    const first = resumeRide(makeRide(), at(60), { drivers: POOL });
    const second = resumeRide(first, at(60), { drivers: POOL });

    expect(second.timeline).toHaveLength(first.timeline.length);
    expect(second.status).toBe(first.status);
  });

  it('completes the ride when the catch-up covers the whole trip', () => {
    const resumed = resumeRide(makeRide(), at(70), { drivers: POOL });

    expect(resumed.status).toBe('awaitingRating');
    expect(resumed.completedAt).toBe(at(67));
    expect(resumed.timeline.map((event) => event.status)).toEqual([
      'searchingDriver',
      'driverAssigned',
      'driverArriving',
      'driverArrived',
      'tripInProgress',
      'tripCompleted',
      'awaitingRating',
    ]);
    const keys = resumed.timeline.map((event) => `${event.status}@${event.at}`);
    expect(new Set(keys).size).toBe(keys.length);
  });
});

describe('driver selection', () => {
  it('ships a demo pool of five drivers with unique ids', () => {
    expect(FALLBACK_DRIVERS).toHaveLength(5);
    expect(FALLBACK_DRIVERS.filter((driver) => driver.vehicleType === 'bike')).toHaveLength(2);
    expect(FALLBACK_DRIVERS.filter((driver) => driver.vehicleType === 'toto')).toHaveLength(3);
    expect(new Set(FALLBACK_DRIVERS.map((driver) => driver.id)).size).toBe(FALLBACK_DRIVERS.length);
  });

  it('is deterministic for the same ride id', () => {
    const first = selectDriver('ride-1', 'bike', POOL);
    const second = selectDriver('ride-1', 'bike', POOL);
    expect(first?.id).toBe(second?.id);
  });

  it('picks the same driver for the same ride id from the demo pool', () => {
    const ids = ['ride-a', 'ride-b', 'ride-c', 'ride-d'].map(
      (rideId) => selectDriver(rideId, 'toto', FALLBACK_DRIVERS)?.id,
    );
    for (const rideId of ['ride-a', 'ride-b', 'ride-c', 'ride-d']) {
      expect(selectDriver(rideId, 'toto', FALLBACK_DRIVERS)?.id).toBe(
        selectDriver(rideId, 'toto', FALLBACK_DRIVERS)?.id,
      );
    }
    // The pool holds three totos, so different rides may land on different drivers.
    expect(new Set(ids).size).toBeGreaterThan(1);
  });

  it('only picks drivers of the requested vehicle type', () => {
    for (const id of ['a', 'b', 'c', 'd', 'e', 'f']) {
      expect(selectDriver(id, 'toto', POOL)?.vehicleType).toBe('toto');
      expect(selectDriver(id, 'bike', POOL)?.vehicleType).toBe('bike');
    }
  });

  it('returns undefined when the given pool has no matching vehicle', () => {
    expect(selectDriver('ride-1', 'toto', [POOL[0]])).toBeUndefined();
  });

  it('fails instead of borrowing a driver when the supplied pool has no match', () => {
    const result = advanceRide(makeRide(), at(6), {
      drivers: POOL.filter((driver) => driver.vehicleType === 'toto'),
    });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('failed');
    expect(result.data.driver).toBeUndefined();
    expect(result.data.nextTransitionAt).toBeUndefined();
  });

  it('fails the search when the simulation says so', () => {
    const result = advanceRide(makeRide(), at(6), { drivers: POOL, shouldFail: () => true });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('failed');
    expect(result.data.driver).toBeUndefined();
    expect(result.data.nextTransitionAt).toBeUndefined();
    expect(result.data.timeline.at(-1)).toEqual({ status: 'failed', at: at(6) });
  });

  it('assigns a driver when the simulation does not fail the search', () => {
    const result = advanceRide(makeRide(), at(6), { drivers: POOL, shouldFail: () => false });
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.status).toBe('driverAssigned');
    expect(result.data.driver?.vehicleType).toBe('bike');
    expect(result.data.nextTransitionAt).toBe(at(10));
  });

  it('hashes stably', () => {
    expect(stableHash('ride-1')).toBe(stableHash('ride-1'));
    expect(stableHash('ride-1')).not.toBe(stableHash('ride-2'));
    expect(stableHash('ride-1')).toBeGreaterThanOrEqual(0);
  });

  it('attaches a demo driver when no pool is supplied', () => {
    const result = advanceRide(makeRide(), at(6));
    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(FALLBACK_DRIVERS.some((driver) => driver.id === result.data.driver?.id)).toBe(true);
  });
});

describe('corrupt rides', () => {
  it('does not throw on an unknown status', () => {
    const corrupt = { ...makeRide(), status: 'bogus' } as unknown as Ride;

    expect(scheduleNextTransition(corrupt, T0)).toBeUndefined();

    const result = advanceRide(corrupt, at(60));
    expect(result.ok).toBe(false);
    if (result.ok) return;
    expect(result.error.code).toBe('invalid_transition');

    const resumed = resumeRide(corrupt, at(60));
    expect(resumed.status).toBe('bogus');
    expect(resumed.timeline).toHaveLength(1);
  });
});

describe('finalizeIfTerminal', () => {
  it('is idempotent and only adds the missing stamp', () => {
    const completed = makeRide({
      status: 'awaitingRating',
      timeline: [{ status: 'tripCompleted', at: at(67) }],
    });

    const finalized = finalizeIfTerminal(completed);
    expect(finalized.completedAt).toBe(at(67));
    expect(finalizeIfTerminal(finalized)).toEqual(finalized);
  });

  it('stamps cancelled rides', () => {
    const cancelled = makeRide({ status: 'cancelled', phaseStartedAt: at(3) });
    expect(finalizeIfTerminal(cancelled).cancelledAt).toBe(at(3));
  });
});
