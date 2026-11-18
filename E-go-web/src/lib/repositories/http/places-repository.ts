/**
 * HTTP stub of the places repository.
 *
 * The stub exists so the swap to a real API is additive: implement this class
 * and change `createRepositories()` - no screen changes (architecture §6).
 */

import type { Place, Result, SavedPlace } from '@/lib/domain/types';
import type { PlacesRepository } from '@/lib/repositories/types';
import { NOT_IMPLEMENTED_ERROR } from '@/lib/repositories/http/auth-repository';

export class HttpPlacesRepository implements PlacesRepository {
  protected readonly baseUrl: string;

  protected readonly fetchImpl: typeof fetch;

  constructor(baseUrl: string, fetchImpl: typeof fetch = fetch) {
    this.baseUrl = baseUrl;
    this.fetchImpl = fetchImpl;
  }

  async search(query: string): Promise<Result<Place[]>> {
    void query;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async listSaved(userId: string): Promise<Result<SavedPlace[]>> {
    void userId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async save(userId: string, place: Place, tag: SavedPlace['tag']): Promise<Result<SavedPlace>> {
    void userId;
    void place;
    void tag;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async remove(userId: string, savedId: string): Promise<Result<null>> {
    void userId;
    void savedId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }
}
