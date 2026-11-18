/**
 * Simulated network latency for the mock repositories.
 *
 * Every mock call takes a little time so the UI has to deal with loading
 * states - but never longer than a person is willing to wait. The range lives
 * in `config/constants.ts`; `0` disables the delay completely (tests).
 */

import { MOCK_LATENCY_MS } from '@/lib/config/constants';

/**
 * The latency to simulate, in milliseconds.
 *
 * An explicit `latencyMs` always wins - including `0`, which disables the
 * delay. Without an explicit value a random duration between
 * `MOCK_LATENCY_MS.min` and `MOCK_LATENCY_MS.max` is used.
 */
export function resolveLatency(options?: { latencyMs?: number }): number {
  const explicit = options?.latencyMs;
  if (typeof explicit === 'number' && Number.isFinite(explicit)) {
    return Math.max(0, explicit);
  }
  return MOCK_LATENCY_MS.min + Math.random() * (MOCK_LATENCY_MS.max - MOCK_LATENCY_MS.min);
}

/**
 * Wait for the simulated latency.
 *
 * A duration of `0` (or less) resolves immediately.
 */
export async function mockDelay(latencyMs?: number): Promise<void> {
  const duration = resolveLatency({ latencyMs });
  if (duration <= 0) return;
  await new Promise<void>((resolve) => {
    setTimeout(resolve, duration);
  });
}
