import { beforeEach, describe, expect, it } from 'vitest';

import type { Place } from '@/lib/domain/types';
import { resetDb } from '@/lib/mock/db';
import { createMockPlacesRepository, findNearestPlace } from '@/lib/mock/places-mock';
import { PLACES } from '@/lib/mock/seeds';

const station: Place = {
  id: 'place-001',
  label: 'Jhargram Railway Station',
  address: 'Jhargram, West Bengal',
  kind: 'poi',
  lat: 22.4529,
  lng: 86.9003,
};

const college: Place = {
  id: 'place-006',
  label: 'Jhargram College',
  address: 'Jhargram, West Bengal',
  kind: 'poi',
  lat: 22.461,
  lng: 86.912,
};

function repository() {
  return createMockPlacesRepository({ latencyMs: 0 });
}

beforeEach(() => {
  window.localStorage.clear();
  resetDb();
});

describe('search', () => {
  it('returns at most eight places for an empty query', async () => {
    const repo = repository();

    const result = await repo.search('');

    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.length).toBeGreaterThan(0);
    expect(result.data.length).toBeLessThanOrEqual(8);
  });

  it('matches the label and the address case insensitively', async () => {
    const repo = repository();

    const result = await repo.search('jhargram');

    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data.length).toBeGreaterThan(0);
    for (const place of result.data) {
      const matches =
        place.label.toLowerCase().includes('jhargram') ||
        place.address.toLowerCase().includes('jhargram');
      expect(matches, place.label).toBe(true);
    }
  });

  it('returns nothing for an unknown query', async () => {
    const repo = repository();

    const result = await repo.search('zzzz');

    expect(result.ok).toBe(true);
    if (!result.ok) return;
    expect(result.data).toEqual([]);
  });
});

describe('saved places', () => {
  it('starts empty and lists the places of the user only', async () => {
    const repo = repository();

    const empty = await repo.listSaved('user-a');
    expect(empty.ok).toBe(true);
    if (!empty.ok) return;
    expect(empty.data).toHaveLength(0);

    const home = await repo.save('user-a', station, 'home');
    expect(home.ok).toBe(true);

    const work = await repo.save('user-a', college, 'work');
    expect(work.ok).toBe(true);

    const other = await repo.save('user-b', college, 'home');
    expect(other.ok).toBe(true);

    const list = await repo.listSaved('user-a');
    expect(list.ok).toBe(true);
    if (!list.ok) return;
    expect(list.data).toHaveLength(2);
    expect(list.data.map((place) => place.tag)).toEqual(['home', 'work']);
    for (const place of list.data) {
      expect('userId' in place).toBe(false);
    }

    const otherList = await repo.listSaved('user-b');
    expect(otherList.ok).toBe(true);
    if (!otherList.ok) return;
    expect(otherList.data).toHaveLength(1);
    expect(otherList.data[0].tag).toBe('home');
  });

  it('replaces the place of a tag and keeps its id', async () => {
    const repo = repository();

    const first = await repo.save('user-a', station, 'home');
    expect(first.ok).toBe(true);
    if (!first.ok) return;

    const replaced = await repo.save('user-a', college, 'home');
    expect(replaced.ok).toBe(true);
    if (!replaced.ok) return;
    expect(replaced.data.savedId).toBe(first.data.savedId);
    expect(replaced.data.label).toBe(college.label);

    const list = await repo.listSaved('user-a');
    expect(list.ok).toBe(true);
    if (!list.ok) return;
    expect(list.data).toHaveLength(1);
  });

  it('refuses to remove the place of another user', async () => {
    const repo = repository();

    const mine = await repo.save('user-a', station, 'home');
    expect(mine.ok).toBe(true);
    if (!mine.ok) return;

    const foreign = await repo.remove('user-b', mine.data.savedId);
    expect(foreign.ok).toBe(false);
    if (!foreign.ok) expect(foreign.error.code).toBe('not_found');
  });

  it('removes a place once', async () => {
    const repo = repository();

    const saved = await repo.save('user-a', station, 'home');
    expect(saved.ok).toBe(true);
    if (!saved.ok) return;

    const removed = await repo.remove('user-a', saved.data.savedId);
    expect(removed.ok).toBe(true);

    const list = await repo.listSaved('user-a');
    expect(list.ok).toBe(true);
    if (!list.ok) return;
    expect(list.data).toHaveLength(0);

    const again = await repo.remove('user-a', saved.data.savedId);
    expect(again.ok).toBe(false);
    if (!again.ok) expect(again.error.code).toBe('not_found');
  });
});

describe('findNearestPlace', () => {
  it('returns a copy of the closest seeded place', () => {
    const nearest = findNearestPlace({ lat: 22.4529, lng: 86.9003 });

    expect(nearest.kind).toBe('poi');
    expect(nearest.label.trim().length).toBeGreaterThan(0);

    const original = PLACES.find((place) => place.id === nearest.id);
    expect(original?.label).not.toBe('mutated');

    nearest.label = 'mutated';
    expect(PLACES.find((place) => place.id === nearest.id)?.label).not.toBe('mutated');
  });
});
