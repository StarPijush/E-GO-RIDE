/**
 * Repository factory.
 *
 * This module is the **only** place the app may reach the mock adapters:
 * screens and stores import `getRepositories()` and never `lib/mock/*`
 * directly. When the real API arrives, only `createRepositories()` changes -
 * the screens stay untouched.
 */

import { simulationSeed } from '@/lib/config/env';
import { isDemoAuthEnabled } from '@/lib/config/env';
import { stableHash } from '@/lib/domain/ride-orchestrator';
import type { Driver } from '@/lib/domain/types';
import { createMockAuthRepository } from '@/lib/mock/auth-mock';
import { DEMO_OTP, DEMO_PASSWORD, DEMO_PHONE } from '@/lib/mock/demo-credentials';
import { createMockNotificationRepository } from '@/lib/mock/notification-mock';
import { createMockPaymentRepository } from '@/lib/mock/payment-mock';
import { createMockPlacesRepository } from '@/lib/mock/places-mock';
import { createMockRideRepository } from '@/lib/mock/ride-mock';
import { DEMO_DRIVERS, seedDemoData } from '@/lib/mock/seeds';
import {
  currentSimulationFailureRate,
  shouldSimulatedSearchFail,
} from '@/lib/mock/simulation';
import type {
  AuthRepository,
  NotificationRepository,
  PaymentRepository,
  PlacesRepository,
  RideRepository,
} from '@/lib/repositories/types';

export type { Result } from '@/lib/domain/types';

/** Every repository the app talks to. */
export interface Repositories {
  auth: AuthRepository;
  rides: RideRepository;
  places: PlacesRepository;
  payments: PaymentRepository;
  notifications: NotificationRepository;
}

/** Options of the repository factory. */
export interface RepositoryOptions {
  /** Simulated latency in milliseconds. `0` disables the delay. */
  latencyMs?: number;
}

/**
 * Build the repositories.
 *
 * Today every adapter is a mock; the HTTP adapters in `lib/repositories/http`
 * take over here when the backend is ready.
 */
export function createRepositories(options: RepositoryOptions = {}): Repositories {
  const latencyMs = options.latencyMs;

  return {
    auth: createMockAuthRepository({ latencyMs }),
    rides: createMockRideRepository({ latencyMs }),
    places: createMockPlacesRepository({ latencyMs }),
    payments: createMockPaymentRepository({ latencyMs }),
    notifications: createMockNotificationRepository({ latencyMs }),
  };
}

/**
 * The options of the simulated ride lifecycle.
 *
 * This is the **only** bridge the stores use for the simulation: they never
 * import `lib/mock/*` themselves.
 */
export interface RideSimulationOptions {
  /** The driver pool of the demo. */
  drivers: readonly Driver[];
  /** The numeric seed of the driver selection. */
  seed: number;
  /** True when the driver search of the ride should fail. */
  shouldFail: (rideId: string) => boolean;
}

/**
 * The simulation options of the running app.
 *
 * The seed comes from `NEXT_PUBLIC_SIM_SEED` (hashed into a number) and the
 * failure rate from `NEXT_PUBLIC_SIM_FAIL_RATE` (default `0`).
 */
export function getRideSimulationOptions(): RideSimulationOptions {
  const seedText = simulationSeed ?? '';
  const seed = seedText ? stableHash(seedText) : 0;
  const rate = currentSimulationFailureRate();

  return {
    drivers: DEMO_DRIVERS,
    seed,
    shouldFail: (rideId: string) => shouldSimulatedSearchFail(rideId, rate, seedText),
  };
}

/**
 * The demo credentials of the demo account.
 *
 * `null` outside of demo mode, so the login screen never shows them in a
 * production build. The UI reads them from here and never imports
 * `lib/mock/*` itself.
 */
export function getDemoCredentials(): { phone: string; password: string } | null {
  if (!isDemoAuthEnabled) return null;
  return { phone: DEMO_PHONE, password: DEMO_PASSWORD };
}

/**
 * The demo OTP of the demo account.
 *
 * `null` outside of demo mode, so the code is never part of a production
 * bundle.
 */
export function getDemoOtp(): string | null {
  if (!isDemoAuthEnabled) return null;
  return DEMO_OTP;
}

/**
 * Prepare the demo data of the app.
 *
 * The hydrator calls this once, after the persisted state was read. No
 * component may import `lib/mock/*` itself.
 */
export function initializeMockData(): void {
  seedDemoData();
}

/** The shared repositories of the running app. */
let repositories: Repositories | null = null;

/** The repositories of the app. The instance is created once and reused. */
export function getRepositories(): Repositories {
  if (!repositories) repositories = createRepositories();
  return repositories;
}

/**
 * Replace the repositories - **for tests only**.
 *
 * Pass `null` to restore the default (mock) repositories.
 */
export function setRepositoriesForTests(next: Repositories | null): void {
  repositories = next;
}
