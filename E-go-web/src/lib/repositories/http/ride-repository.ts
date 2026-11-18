/**
 * HTTP stub of the ride repository.
 *
 * The stub exists so the swap to a real API is additive: implement this class
 * and change `createRepositories()` - no screen changes (architecture §6).
 */

import type { CancellationReason, Rating, Result, Ride } from '@/lib/domain/types';
import type { RideRepository } from '@/lib/repositories/types';
import { NOT_IMPLEMENTED_ERROR } from '@/lib/repositories/http/auth-repository';

export class HttpRideRepository implements RideRepository {
  protected readonly baseUrl: string;

  protected readonly fetchImpl: typeof fetch;

  constructor(baseUrl: string, fetchImpl: typeof fetch = fetch) {
    this.baseUrl = baseUrl;
    this.fetchImpl = fetchImpl;
  }

  async create(input: {
    userId: string;
    pickup: Ride['pickup'];
    destination: Ride['destination'];
    vehicle: Ride['vehicle'];
    fare: Ride['fare'];
    paymentMethodId: string;
  }): Promise<Result<Ride>> {
    void input;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async save(ride: Ride): Promise<Result<Ride>> {
    void ride;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async getActive(userId: string): Promise<Result<Ride | null>> {
    void userId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async getById(rideId: string): Promise<Result<Ride>> {
    void rideId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async list(userId: string, filter?: 'all' | 'completed' | 'cancelled'): Promise<Result<Ride[]>> {
    void userId;
    void filter;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async cancel(rideId: string, reason: CancellationReason): Promise<Result<Ride>> {
    void rideId;
    void reason;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async rate(rideId: string, rating: Rating): Promise<Result<Ride>> {
    void rideId;
    void rating;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }
}
