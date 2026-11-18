/**
 * Mock payment method repository.
 *
 * DEVELOPMENT ONLY - the payment methods live in the browser database
 * (`ego:db:v1`). No payment is ever processed: cash is the default and only
 * selectable method of the demo (A9).
 *
 * The repository owns the per-user methods, the default flag and the cash
 * method that may not be removed. Every expected failure is returned as a
 * `Result` error, never thrown.
 */

import type { AppErrorCode, PaymentMethod, Result } from '@/lib/domain/types';
import {
  loadDb,
  storedPaymentMethodSchema,
  updateDb,
  type StoredPaymentMethod,
} from '@/lib/mock/db';
import { mockDelay, resolveLatency } from '@/lib/mock/mock-delay';
import type { PaymentRepository } from '@/lib/repositories/types';
import { newId } from '@/lib/utils/id';

/** Options of the mock repository (used to make tests deterministic). */
export interface MockPaymentOptions {
  /** Simulated latency in milliseconds. `0` disables the delay. */
  latencyMs?: number;
  /** Injectable clock, epoch milliseconds. */
  now?: () => number;
}

/** Copy of the error that a cash method may not be removed. */
const CASH_IS_PROTECTED = 'Cash is the default demo payment method and cannot be removed.';

function failure(code: AppErrorCode, message: string, field?: string): Result<never> {
  return { ok: false, error: field ? { code, message, field } : { code, message } };
}

/** The public shape of a payment method (without the internal `userId`). */
function toPaymentMethod(stored: StoredPaymentMethod): PaymentMethod {
  return {
    id: stored.id,
    type: stored.type,
    label: stored.label,
    masked: stored.masked,
    isDefault: stored.isDefault,
  };
}

/** The default method first, then alphabetically by label. */
function sortMethods(methods: readonly StoredPaymentMethod[]): StoredPaymentMethod[] {
  return [...methods].sort((left, right) => {
    if (left.isDefault !== right.isDefault) return left.isDefault ? -1 : 1;
    return left.label.localeCompare(right.label);
  });
}

/** The mock payment repository. */
export class MockPaymentRepository implements PaymentRepository {
  private readonly latencyMs: number;

  private readonly clock: () => number;

  constructor(options: MockPaymentOptions = {}) {
    this.latencyMs = resolveLatency({ latencyMs: options.latencyMs });
    this.clock = options.now ?? (() => Date.now());
  }

  /** Simulated network latency. */
  private async simulateLatency(): Promise<void> {
    await mockDelay(this.latencyMs);
  }

  /** The methods of a user, default first. */
  private listFor(userId: string): PaymentMethod[] {
    return sortMethods(loadDb().paymentMethods.filter((method) => method.userId === userId)).map(
      toPaymentMethod,
    );
  }

  async list(userId: string): Promise<Result<PaymentMethod[]>> {
    await this.simulateLatency();

    const existing = loadDb().paymentMethods.filter((method) => method.userId === userId);
    if (existing.length === 0) {
      // Every user has cash - the demo never starts without a payment method.
      const created: StoredPaymentMethod = {
        id: `cash-${userId}`,
        type: 'cash',
        label: 'Cash',
        isDefault: true,
        userId,
      };

      const validated = storedPaymentMethodSchema.safeParse(created);
      if (!validated.success) {
        return failure('unknown', 'The default payment method could not be created.');
      }

      updateDb((db) => {
        db.paymentMethods.push(created);
      });
      return { ok: true, data: [toPaymentMethod(created)] };
    }

    return { ok: true, data: this.listFor(userId) };
  }

  async add(userId: string, method: Omit<PaymentMethod, 'id'>): Promise<Result<PaymentMethod>> {
    await this.simulateLatency();

    const existing = loadDb().paymentMethods.filter((candidate) => candidate.userId === userId);
    const hasDefault = existing.some((candidate) => candidate.isDefault);

    const stored: StoredPaymentMethod = {
      id: newId('pm'),
      type: method.type,
      label: method.label,
      masked: method.masked,
      // The first method of a user is always the default one.
      isDefault: method.isDefault || !hasDefault,
      userId,
    };

    const validated = storedPaymentMethodSchema.safeParse(stored);
    if (!validated.success) {
      return failure('unknown', 'The payment method could not be saved.', 'label');
    }

    updateDb((db) => {
      if (stored.isDefault) {
        for (const candidate of db.paymentMethods) {
          if (candidate.userId === userId) candidate.isDefault = false;
        }
      }
      db.paymentMethods.push(stored);
    });

    return { ok: true, data: toPaymentMethod(stored) };
  }

  async remove(userId: string, id: string): Promise<Result<null>> {
    await this.simulateLatency();

    const target = loadDb().paymentMethods.find(
      (candidate) => candidate.id === id && candidate.userId === userId,
    );
    if (!target) return failure('not_found', 'The payment method was not found.');
    if (target.type === 'cash') {
      return failure('invalid_transition', CASH_IS_PROTECTED);
    }

    updateDb((db) => {
      const index = db.paymentMethods.findIndex(
        (candidate) => candidate.id === id && candidate.userId === userId,
      );
      if (index === -1) return;

      const wasDefault = db.paymentMethods[index].isDefault;
      db.paymentMethods.splice(index, 1);
      if (wasDefault) {
        // The remaining method takes over as the default one.
        const next = db.paymentMethods.find((candidate) => candidate.userId === userId);
        if (next) next.isDefault = true;
      }
    });

    return { ok: true, data: null };
  }

  async setDefault(userId: string, id: string): Promise<Result<PaymentMethod[]>> {
    await this.simulateLatency();

    const target = loadDb().paymentMethods.find(
      (candidate) => candidate.id === id && candidate.userId === userId,
    );
    if (!target) return failure('not_found', 'The payment method was not found.');

    updateDb((db) => {
      for (const candidate of db.paymentMethods) {
        if (candidate.userId !== userId) continue;
        candidate.isDefault = candidate.id === id;
      }
    });

    return { ok: true, data: this.listFor(userId) };
  }
}

/** Create a repository, e.g. with a deterministic clock for tests. */
export function createMockPaymentRepository(options?: MockPaymentOptions): MockPaymentRepository {
  return new MockPaymentRepository(options);
}
