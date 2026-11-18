/**
 * Mock places repository.
 *
 * DEVELOPMENT ONLY - the places are the seeded points of interest of
 * Jhargram (`lib/mock/seeds.ts`), the saved places live in the browser
 * database (`ego:db:v1`).
 *
 * The repository never returns the internal `userId` of a saved place: it is
 * an implementation detail of the storage.
 */

import { distanceKm } from '@/lib/domain/geo';
import type { AppErrorCode, LatLng, Place, Result, SavedPlace } from '@/lib/domain/types';
import { loadDb, storedSavedPlaceSchema, updateDb, type StoredSavedPlace } from '@/lib/mock/db';
import { mockDelay, resolveLatency } from '@/lib/mock/mock-delay';
import { PLACES } from '@/lib/mock/seeds';
import type { PlacesRepository } from '@/lib/repositories/types';
import { newId } from '@/lib/utils/id';

/** Options of the mock repository (used to make tests deterministic). */
export interface MockPlacesOptions {
  /** Simulated latency in milliseconds. `0` disables the delay. */
  latencyMs?: number;
  /** Injectable clock, epoch milliseconds. */
  now?: () => number;
}

/** The maximum number of places a search returns. */
const MAX_RESULTS = 8;

/** The order the saved places are listed in. */
const TAG_ORDER: readonly SavedPlace['tag'][] = ['home', 'work', 'other'];

function failure(code: AppErrorCode, message: string, field?: string): Result<never> {
  return { ok: false, error: field ? { code, message, field } : { code, message } };
}

/** The public shape of a saved place (without the internal `userId`). */
function toSavedPlace(stored: StoredSavedPlace): SavedPlace {
  return {
    id: stored.id,
    label: stored.label,
    address: stored.address,
    kind: stored.kind,
    lat: stored.lat,
    lng: stored.lng,
    savedId: stored.savedId,
    tag: stored.tag,
  };
}

/** The mock places repository. */
export class MockPlacesRepository implements PlacesRepository {
  private readonly latencyMs: number;

  private readonly clock: () => number;

  constructor(options: MockPlacesOptions = {}) {
    this.latencyMs = resolveLatency({ latencyMs: options.latencyMs });
    this.clock = options.now ?? (() => Date.now());
  }

  /** Simulated network latency. */
  private async simulateLatency(): Promise<void> {
    await mockDelay(this.latencyMs);
  }

  async search(query: string): Promise<Result<Place[]>> {
    await this.simulateLatency();

    const normalized = query.trim().toLowerCase();
    const matches =
      normalized === ''
        ? PLACES
        : PLACES.filter(
            (place) =>
              place.label.toLowerCase().includes(normalized) ||
              place.address.toLowerCase().includes(normalized),
          );

    return { ok: true, data: matches.slice(0, MAX_RESULTS) };
  }

  async listSaved(userId: string): Promise<Result<SavedPlace[]>> {
    await this.simulateLatency();

    const places = loadDb()
      .savedPlaces.filter((place) => place.userId === userId)
      .map(toSavedPlace)
      .sort((left, right) => {
        const tagDifference = TAG_ORDER.indexOf(left.tag) - TAG_ORDER.indexOf(right.tag);
        if (tagDifference !== 0) return tagDifference;
        return left.label.localeCompare(right.label);
      });

    return { ok: true, data: places };
  }

  async save(
    userId: string,
    place: Place,
    tag: SavedPlace['tag'],
  ): Promise<Result<SavedPlace>> {
    await this.simulateLatency();

    const saved: StoredSavedPlace = {
      id: place.id,
      label: place.label,
      address: place.address,
      kind: 'saved',
      lat: place.lat,
      lng: place.lng,
      savedId: newId('saved'),
      tag,
      userId,
    };

    const validated = storedSavedPlaceSchema.safeParse(saved);
    if (!validated.success) {
      return failure('unknown', 'The place could not be saved: the data is not valid.');
    }

    let stored: StoredSavedPlace | undefined;
    updateDb((db) => {
      const index = db.savedPlaces.findIndex(
        (candidate) => candidate.userId === userId && candidate.tag === tag,
      );
      if (index === -1) {
        db.savedPlaces.push(saved);
        stored = saved;
        return;
      }
      // Home and work are unique per user: the old entry is replaced.
      const replaced: StoredSavedPlace = { ...saved, savedId: db.savedPlaces[index].savedId };
      db.savedPlaces[index] = replaced;
      stored = replaced;
    });

    if (!stored) return failure('unknown', 'The place could not be saved.');
    return { ok: true, data: toSavedPlace(stored) };
  }

  async remove(userId: string, savedId: string): Promise<Result<null>> {
    await this.simulateLatency();

    const exists = loadDb().savedPlaces.some(
      (candidate) => candidate.savedId === savedId && candidate.userId === userId,
    );
    if (!exists) return failure('not_found', 'The saved place was not found.');

    updateDb((db) => {
      const index = db.savedPlaces.findIndex(
        (candidate) => candidate.savedId === savedId && candidate.userId === userId,
      );
      if (index !== -1) db.savedPlaces.splice(index, 1);
    });

    return { ok: true, data: null };
  }
}

/**
 * The seeded place closest to a location.
 *
 * Used by the map: a tap resolves to the nearest point of interest (the mock
 * reverse geocode). The result is a copy, so the caller may change it.
 */
export function findNearestPlace(location: LatLng): Place {
  let nearest: Place | undefined;
  let nearestDistance = Number.POSITIVE_INFINITY;

  for (const place of PLACES) {
    const distance = distanceKm(location, place);
    if (distance < nearestDistance) {
      nearestDistance = distance;
      nearest = place;
    }
  }

  if (!nearest) {
    return {
      id: 'place-000',
      label: 'Jhargram',
      address: 'Jhargram, West Bengal',
      kind: 'poi',
      lat: location.lat,
      lng: location.lng,
    };
  }

  return { ...nearest, kind: 'poi' };
}

/** Create a repository, e.g. with a deterministic clock for tests. */
export function createMockPlacesRepository(options?: MockPlacesOptions): MockPlacesRepository {
  return new MockPlacesRepository(options);
}
