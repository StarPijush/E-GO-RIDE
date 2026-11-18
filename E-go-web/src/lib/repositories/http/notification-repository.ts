/**
 * HTTP stub of the notification repository.
 *
 * The stub exists so the swap to a real API is additive: implement this class
 * and change `createRepositories()` - no screen changes (architecture §6).
 */

import type { AppNotification, Result } from '@/lib/domain/types';
import type { NotificationRepository } from '@/lib/repositories/types';
import { NOT_IMPLEMENTED_ERROR } from '@/lib/repositories/http/auth-repository';

export class HttpNotificationRepository implements NotificationRepository {
  protected readonly baseUrl: string;

  protected readonly fetchImpl: typeof fetch;

  constructor(baseUrl: string, fetchImpl: typeof fetch = fetch) {
    this.baseUrl = baseUrl;
    this.fetchImpl = fetchImpl;
  }

  async list(userId: string): Promise<Result<AppNotification[]>> {
    void userId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async markRead(userId: string, id: string): Promise<Result<AppNotification[]>> {
    void userId;
    void id;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async markAllRead(userId: string): Promise<Result<AppNotification[]>> {
    void userId;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }
}
