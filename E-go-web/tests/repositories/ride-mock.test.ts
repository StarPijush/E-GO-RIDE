import { beforeEach, describe, expect, it } from 'vitest';

import { calculateFare } from '@/lib/domain/fare';
import type { Place } from '@/lib/domain/types';
import { createEmptyDb, loadDb, resetDb, saveDb } from '@/lib/mock/db';
import { createMockRideRepository } from '@/lib/mock/ride-mock';
import { ensureDemoSeedData } from '@/lib/mock/seeds';

const NOW = '2026-11-15T10:00:00.000Z';
const NOW_MS = Date.parse(NOW);
const DEMO_USER_ID = 'demo-ego-001';

const pickup: Place = {
  id: 'place-001',
  label: 'Jhargram Railway Station',
  address: 'Jhargram, West Bengal',
  kind: 'pickup',
  lat: 22.4529,
  lng: 86.9003,
};

const destination: Place = {
  id: 'place-006',
  label: 'Jhargram College',
  address: 'Jhargram, West Bengal',
  kind: 'destination',
  lat: 22.461,
  lng: 86.912,
};

const input = {
  userId: 'user-1',
  pickup,
  destination,
  vehicle: 'bike' as const,
  fare: calculateFare('bike', pickup, destination),
  paymentMethodId: 'cash-1',
};

function repository() {
  return createMockRideRepository({ latencyMs: 0, now: () => NOW_MS });
}

beforeEach(() => {
  window.localStorage.clear();
  resetDb();
});

describe('create', () => {
  it('creates a ride in the confirming state and finds it by id', async () => {
    const repo = repository();

    const created = await repo.create(input);
    expect(created.ok).toBe(true);
    if (!created.ok) return;

    expect(created.data.status).toBe('confirmingBooking');
    expect(created.data.timeline.length).toBeGreaterThan(0);
    expect(created.data.userId).toBe('user-1');
    expect(created.data.createdAt).toBe(NOW);
    expect(created.data.phaseStartedAt).toBe(NOW);
    expect(created.data.nextTransitionAt).toBeUndefined();

    const fetched = await repo.getById(created.data.id);
    expect(fetched.ok).toBe(true);
    if (fetched.ok) expect(fetched.data.id).toBe(created.data.id);
  });

  it('fails for an unknown ride id', async () => {
    const repo = repository();

    const result = await repo.getById('does-not-exist');

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('not_found');
  });
});

describe('getActive', () => {
  it('returns the newest live ride of the user only', async () => {
    const repo = repository();

    const mine = await repo.create(input);
    expect(mine.ok).toBe(true);
    if (!mine.ok) return;

    const other = await repo.create({ ...input, userId: 'user-2' });
    expect(other.ok).toBe(true);

    const live = {
      ...mine.data,
      status: 'searchingDriver' as const,
      timeline: [
        ...mine.data.timeline,
        { status: 'searchingDriver' as const, at: NOW },
      ],
    };
    await repo.save(live);

    const active = await repo.getActive('user-1');
    expect(active.ok).toBe(true);
    if (!active.ok) return;
    expect(active.data?.id).toBe(mine.data.id);

    const activeOfOther = await repo.getActive('user-2');
    expect(activeOfOther.ok).toBe(true);
    if (!activeOfOther.ok) return;
    expect(activeOfOther.data?.id).toBe(other.ok ? other.data.id : undefined);
  });

  it('returns null once the ride is cancelled', async () => {
    const repo = repository();

    const created = await repo.create(input);
    if (!created.ok) throw new Error('create failed');

    await repo.save({
      ...created.data,
      status: 'searchingDriver',
      timeline: [...created.data.timeline, { status: 'searchingDriver', at: NOW }],
    });

    const cancelled = await repo.cancel(created.data.id, 'changed_plan');
    expect(cancelled.ok).toBe(true);

    const active = await repo.getActive('user-1');
    expect(active.ok).toBe(true);
    if (!active.ok) return;
    expect(active.data).toBeNull();
  });
});

describe('save', () => {
  it('upserts the ride', async () => {
    const repo = repository();

    const created = await repo.create(input);
    if (!created.ok) throw new Error('create failed');

    const saved = await repo.save({
      ...created.data,
      status: 'driverAssigned',
      timeline: [...created.data.timeline, { status: 'driverAssigned', at: NOW }],
    });

    expect(saved.ok).toBe(true);
    const stored = loadDb().rides.filter((ride) => ride.id === created.data.id);
    expect(stored).toHaveLength(1);
    expect(stored[0].status).toBe('driverAssigned');
  });

  it('rejects an invalid ride and does not persist it', async () => {
    const repo = repository();

    const created = await repo.create(input);
    if (!created.ok) throw new Error('create failed');

    const invalid = { ...created.data, status: 'rated' as const };
    const result = await repo.save(invalid);

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('unknown');

    const stored = loadDb().rides.find((ride) => ride.id === created.data.id);
    expect(stored?.status).toBe('confirmingBooking');
  });
});

describe('notifications', () => {
  it('creates exactly one notification for a rated ride', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const rated = await repo.rate('ride-demo-002', {
      rideId: 'ride-demo-002',
      stars: 5,
      tags: [],
      createdAt: NOW,
    });
    expect(rated.ok).toBe(true);

    const notifications = loadDb().notifications.filter(
      (notification) => notification.id === 'notif-ride-demo-002-rated',
    );
    expect(notifications).toHaveLength(1);

    const again = await repo.rate('ride-demo-002', {
      rideId: 'ride-demo-002',
      stars: 4,
      tags: [],
      createdAt: NOW,
    });
    expect(again.ok).toBe(false);
    if (!again.ok) expect(again.error.code).toBe('invalid_transition');

    expect(
      loadDb().notifications.filter((notification) => notification.id === 'notif-ride-demo-002-rated'),
    ).toHaveLength(1);
  });
});

describe('list', () => {
  it('filters the history and sorts it by creation date', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();

    const all = await repo.list(DEMO_USER_ID);
    expect(all.ok).toBe(true);
    if (!all.ok) return;
    expect(all.data).toHaveLength(3);
    expect(all.data.map((ride) => ride.status)).toEqual([
      'cancelled',
      'awaitingRating',
      'rated',
    ]);

    const completed = await repo.list(DEMO_USER_ID, 'completed');
    expect(completed.ok).toBe(true);
    if (!completed.ok) return;
    expect(completed.data).toHaveLength(2);

    const cancelled = await repo.list(DEMO_USER_ID, 'cancelled');
    expect(cancelled.ok).toBe(true);
    if (!cancelled.ok) return;
    expect(cancelled.data).toHaveLength(1);
  });

  it('excludes a live ride from the history', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const created = await repo.create({ ...input, userId: DEMO_USER_ID });
    expect(created.ok).toBe(true);

    const history = await repo.list(DEMO_USER_ID);
    expect(history.ok).toBe(true);
    if (!history.ok) return;
    expect(history.data).toHaveLength(3);
  });
});

describe('cancel', () => {
  it('cancels a live ride and notifies once', async () => {
    const repo = repository();

    const created = await repo.create(input);
    if (!created.ok) throw new Error('create failed');

    await repo.save({
      ...created.data,
      status: 'driverAssigned',
      timeline: [...created.data.timeline, { status: 'driverAssigned', at: NOW }],
    });

    const cancelled = await repo.cancel(created.data.id, 'waiting_too_long');
    expect(cancelled.ok).toBe(true);
    if (!cancelled.ok) return;
    expect(cancelled.data.status).toBe('cancelled');
    expect(cancelled.data.cancelledAt).toBe(NOW);
    expect(cancelled.data.cancellationReason).toBe('waiting_too_long');

    expect(
      loadDb().notifications.filter(
        (notification) => notification.id === `notif-${created.data.id}-cancelled`,
      ),
    ).toHaveLength(1);
  });

  it('refuses to cancel a ride that is already on its way', async () => {
    const repo = repository();

    const created = await repo.create(input);
    if (!created.ok) throw new Error('create failed');

    await repo.save({
      ...created.data,
      status: 'tripInProgress',
      timeline: [...created.data.timeline, { status: 'tripInProgress', at: NOW }],
    });

    const result = await repo.cancel(created.data.id, 'changed_plan');
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('invalid_transition');
  });

  it('fails for an unknown ride', async () => {
    const repo = repository();

    const result = await repo.cancel('does-not-exist', 'changed_plan');
    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe('not_found');
  });
});

describe('rate', () => {
  it('rates an unrated ride and forces the ride id', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const rated = await repo.rate('ride-demo-002', {
      rideId: 'a-different-id',
      stars: 4,
      tags: ['On time'],
      createdAt: NOW,
    });

    expect(rated.ok).toBe(true);
    if (!rated.ok) return;
    expect(rated.data.status).toBe('rated');
    expect(rated.data.rating?.rideId).toBe('ride-demo-002');
    expect(rated.data.rating?.stars).toBe(4);
  });

  it('refuses to rate a ride twice', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const first = await repo.rate('ride-demo-002', {
      rideId: 'ride-demo-002',
      stars: 5,
      tags: [],
      createdAt: NOW,
    });
    expect(first.ok).toBe(true);

    const second = await repo.rate('ride-demo-002', {
      rideId: 'ride-demo-002',
      stars: 3,
      tags: [],
      createdAt: NOW,
    });
    expect(second.ok).toBe(false);
    if (!second.ok) expect(second.error.code).toBe('invalid_transition');
  });

  it('rejects an invalid rating', async () => {
    const db = createEmptyDb();
    ensureDemoSeedData(db);
    saveDb(db);

    const repo = repository();
    const result = await repo.rate('ride-demo-002', {
      rideId: 'ride-demo-002',
      stars: 0 as unknown as 5,
      tags: [],
      createdAt: NOW,
    });

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.message).toContain('rating');
  });
});
