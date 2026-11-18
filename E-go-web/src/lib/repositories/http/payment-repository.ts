/**
 * HTTP stub of the payment repository.
 *
 * The stub exists so the swap to a real API is additive: implement this class
 * and change `createRepositories()` - no screen changes (architecture §6).
 */

import type { PaymentMethod, Result } from '@/lib/domain/types';
import type { PaymentRepository } from '@/lib/repositories/types';
import { NOT_IMPLEMENTED_ERROR } from '@/lib/repositories/http/auth-repository';

export class HttpPaymentRepository implements PaymentRepository {
  protected readonly baseUrl: string;

  protected readonly fetchImpl: typeof fetch;

  constructor(baseUrl: string, fetchImpl: typeof fetch = fetch) {
    this.baseUrl = baseUrl;
    this.fetchImpl = fetchImpl;
  }

  async list(userId: string): Promise<Result<PaymentMethod[]>> {
    void userId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async add(userId: string, method: Omit<PaymentMethod, 'id'>): Promise<Result<PaymentMethod>> {
    void userId;
    void method;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async remove(userId: string, id: string): Promise<Result<null>> {
    void userId;
    void id;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async setDefault(userId: string, id: string): Promise<Result<PaymentMethod[]>> {
    void userId;
    void id;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }
}
