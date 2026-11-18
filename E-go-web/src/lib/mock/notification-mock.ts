/**
 * Mock notification repository.
 *
 * DEVELOPMENT ONLY - the notifications live in the browser database
 * (`ego:db:v1`). They are produced by the ride repository (a status change)
 * and by the demo seed data.
 *
 * Every expected failure is returned as a `Result` error, never thrown.
 */

import type { AppErrorCode, AppNotification, Result } from '@/lib/domain/types';
import { loadDb, updateDb, type StoredNotification } from '@/lib/mock/db';
import { mockDelay, resolveLatency } from '@/lib/mock/mock-delay';
import type { NotificationRepository } from '@/lib/repositories/types';

/** Options of the mock repository (used to make tests deterministic). */
export interface MockNotificationOptions {
  /** Simulated latency in milliseconds. `0` disables the delay. */
  latencyMs?: number;
  /** Injectable clock, epoch milliseconds. */
  now?: () => number;
}

function failure(code: AppErrorCode, message: string, field?: string): Result<never> {
  return { ok: false, error: field ? { code, message, field } : { code, message } };
}

/** The public shape of a notification (without the internal `userId`). */
function toNotification(stored: StoredNotification): AppNotification {
  return {
    id: stored.id,
    kind: stored.kind,
    title: stored.title,
    body: stored.body,
    createdAt: stored.createdAt,
    read: stored.read,
  };
}

/** The mock notification repository. */
export class MockNotificationRepository implements NotificationRepository {
  private readonly latencyMs: number;

  private readonly clock: () => number;

  constructor(options: MockNotificationOptions = {}) {
    this.latencyMs = resolveLatency({ latencyMs: options.latencyMs });
    this.clock = options.now ?? (() => Date.now());
  }

  /** Simulated network latency. */
  private async simulateLatency(): Promise<void> {
    await mockDelay(this.latencyMs);
  }

  /** The notifications of a user, newest first. */
  private listFor(userId: string): AppNotification[] {
    return loadDb()
      .notifications.filter((notification) => notification.userId === userId)
      .sort((left, right) => Date.parse(right.createdAt) - Date.parse(left.createdAt))
      .map(toNotification);
  }

  async list(userId: string): Promise<Result<AppNotification[]>> {
    await this.simulateLatency();
    return { ok: true, data: this.listFor(userId) };
  }

  async markRead(userId: string, id: string): Promise<Result<AppNotification[]>> {
    await this.simulateLatency();

    const exists = loadDb().notifications.some(
      (notification) => notification.id === id && notification.userId === userId,
    );
    if (!exists) return failure('not_found', 'The notification was not found.');

    updateDb((db) => {
      const target = db.notifications.find(
        (notification) => notification.id === id && notification.userId === userId,
      );
      if (target) target.read = true;
    });

    return { ok: true, data: this.listFor(userId) };
  }

  async markAllRead(userId: string): Promise<Result<AppNotification[]>> {
    await this.simulateLatency();

    updateDb((db) => {
      for (const notification of db.notifications) {
        if (notification.userId !== userId) continue;
        notification.read = true;
      }
    });

    return { ok: true, data: this.listFor(userId) };
  }
}

/** Create a repository, e.g. with a deterministic clock for tests. */
export function createMockNotificationRepository(
  options?: MockNotificationOptions,
): MockNotificationRepository {
  return new MockNotificationRepository(options);
}
