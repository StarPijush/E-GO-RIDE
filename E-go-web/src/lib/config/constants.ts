/**
 * Single source of truth for E-GO Web's simulated timings, map defaults and
 * persistence keys.
 *
 * No other module may hard-code a duration: every simulated delay lives here
 * so the whole app can be reasoned about (and tuned) from one file.
 *
 * Demo credentials live in `lib/mock/demo-credentials.ts` so they are never
 * bundled into a production build.
 */

import type { LatLng } from '@/lib/domain/types';

export const APP_NAME = 'E-GO';

/** Version written into every persisted payload (`ego:*:v1`). */
export const SCHEMA_VERSION = 1;

/** localStorage keys. Bump the `:v1` suffix when the payload shape changes. */
export const STORAGE_KEYS = {
  auth: 'ego:auth:v1',
  booking: 'ego:booking:v1',
  db: 'ego:db:v1',
  prefs: 'ego:prefs:v1',
} as const;
export type StorageKey = (typeof STORAGE_KEYS)[keyof typeof STORAGE_KEYS];

/** Map default view (Jhargram, West Bengal). */
export const MAP_CENTER: LatLng = { lat: 22.4529, lng: 86.9003 };
export const MAP_DEFAULT_ZOOM = 14;

/** Simulated "current location" used when the browser geolocation is unavailable. */
export const MOCK_CURRENT_LOCATION: LatLng = { lat: 22.455, lng: 86.902 };

/** OpenStreetMap tiles (overridable through `NEXT_PUBLIC_MAP_TILE_URL`). */
export const OSM_TILE_URL = 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png';
export const OSM_ATTRIBUTION = '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';

/**
 * Simulated lifecycle durations in milliseconds (A8).
 * Deadlines are absolute (`nextTransitionAt`) so a refresh or a hidden tab
 * can recover the correct phase.
 */
export const RIDE_TIMINGS = {
  /** `searchingDriver` -> `driverAssigned`. */
  searchingDriverMs: 6_000,
  /** `driverAssigned` -> `driverArriving`. */
  driverAssignedMs: 4_000,
  /** `driverArriving` -> `driverArrived`. */
  driverArrivingMs: 12_000,
  /** `driverArrived` -> `tripInProgress` auto-start fallback. */
  driverArrivedAutoStartMs: 30_000,
  /** `tripInProgress` -> `tripCompleted`. */
  tripInProgressMs: 15_000,
  /** `tripCompleted` -> `awaitingRating`. */
  tripCompletedMs: 500,
} as const;

/** Seconds the user must wait before another OTP may be requested. */
export const OTP_COOLDOWN_SECONDS = 30;

/** Minutes an issued OTP stays valid. */
export const OTP_EXPIRY_MINUTES = 10;

/** Maximum number of OTP verification attempts before the code is burned. */
export const MAX_OTP_ATTEMPTS = 5;

/** Lifetime of a mock session. */
export const SESSION_TTL_DAYS = 7;

/** Simulated latency of a mock repository call, in milliseconds. */
export const MOCK_LATENCY_MS = {
  min: 150,
  max: 400,
} as const;
