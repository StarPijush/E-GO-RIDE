/**
 * Deterministic simulation of the driver search.
 *
 * All randomness of the demo lives here: the same ride id and the same seed
 * always produce the same outcome, so a demo (and a test) can be replayed.
 *
 * The failure rate comes from `NEXT_PUBLIC_SIM_FAIL_RATE` and defaults to `0`
 * - a demo that always finds a driver.
 */

import { simulationFailureRate, simulationSeed } from '@/lib/config/env';
import { stableHash } from '@/lib/domain/ride-orchestrator';

/** 2^32 - the range of the 32 bit hash. */
const HASH_RANGE = 0x1_0000_0000;

/** Clamp a rate into 0 - 1. */
function clampRate(rate: number): number {
  if (!Number.isFinite(rate)) return 0;
  return Math.min(Math.max(rate, 0), 1);
}

/**
 * True when the driver search of `rideId` should fail.
 *
 * The decision is a pure function of the ride id and the seed, so the same
 * ride always fails (or never fails) - there is no randomness at render time.
 */
export function shouldSimulatedSearchFail(
  rideId: string,
  rate: number = simulationFailureRate,
  seed: string = simulationSeed ?? '',
): boolean {
  const clamped = clampRate(rate);
  if (clamped <= 0) return false;
  if (clamped >= 1) return true;
  return stableHash(`${seed}:${rideId}`) / HASH_RANGE < clamped;
}

/** The configured failure rate (0 - 1). */
export function currentSimulationFailureRate(): number {
  return clampRate(simulationFailureRate);
}

/** The configured seed (an empty string when none is set). */
export function currentSimulationSeed(): string {
  return simulationSeed ?? '';
}
