/**
 * Public environment configuration.
 *
 * Every value here is `NEXT_PUBLIC_*`, i.e. inlined into the browser bundle
 * by Next.js - nothing secret may be added to this file.
 *
 * Each variable is read through a static `process.env.NEXT_PUBLIC_X` member
 * expression on purpose: that is the only form Next.js replaces at build
 * time (spreading `process.env` would not be inlined).
 */

import { z } from 'zod';

import { OSM_TILE_URL } from '@/lib/config/constants';

/** `"true"` / `"false"` flag; anything else falls back to the default. */
const booleanFlag = (fallback: 'true' | 'false') =>
  z.enum(['true', 'false']).catch(fallback).default(fallback);

/** Optional string; an empty value is treated as "not set". */
const optionalString = z.preprocess(
  (value) => (typeof value === 'string' && value.trim() === '' ? undefined : value),
  z.string().trim().optional().catch(undefined),
);

/**
 * A ratio between 0 and 1.
 *
 * Unparseable values fall back to `0` (no simulated failures) and the result
 * is clamped, so a typo in `.env.local` can never break the app.
 */
const ratio = (fallback: number) =>
  z.preprocess(
    (value) => {
      if (typeof value === 'number') return value;
      if (typeof value !== 'string' || value.trim() === '') return fallback;
      return Number(value);
    },
    z.number().catch(fallback).transform((value) => Math.min(Math.max(value, 0), 1)),
  );

const envSchema = z.object({
  NEXT_PUBLIC_ENABLE_DEMO_AUTH: booleanFlag('false'),
  NEXT_PUBLIC_MAP_TILE_URL: z.string().trim().min(1).catch(OSM_TILE_URL).default(OSM_TILE_URL),
  NEXT_PUBLIC_DISABLE_MAP: booleanFlag('false'),
  NEXT_PUBLIC_API_BASE_URL: optionalString,
  NEXT_PUBLIC_SIM_SEED: optionalString,
  /** Share of searches that fail (simulated "no driver found"). */
  NEXT_PUBLIC_SIM_FAIL_RATE: ratio(0),
});

const rawEnv = {
  NEXT_PUBLIC_ENABLE_DEMO_AUTH: process.env.NEXT_PUBLIC_ENABLE_DEMO_AUTH,
  NEXT_PUBLIC_MAP_TILE_URL: process.env.NEXT_PUBLIC_MAP_TILE_URL,
  NEXT_PUBLIC_DISABLE_MAP: process.env.NEXT_PUBLIC_DISABLE_MAP,
  NEXT_PUBLIC_API_BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL,
  NEXT_PUBLIC_SIM_SEED: process.env.NEXT_PUBLIC_SIM_SEED,
  NEXT_PUBLIC_SIM_FAIL_RATE: process.env.NEXT_PUBLIC_SIM_FAIL_RATE,
};

const parsed = envSchema.safeParse(rawEnv);

/** Parsed public environment. Falls back to the defaults if anything is off. */
export const env = parsed.success ? parsed.data : envSchema.parse({});

/**
 * Demo auth is only available outside production builds (A4).
 * The production check is compiled away by Next.js.
 */
export const isDemoAuthEnabled =
  env.NEXT_PUBLIC_ENABLE_DEMO_AUTH === 'true' && process.env.NODE_ENV !== 'production';

/** True when the map must not be rendered (CI / text fallback mode). */
export const isMapDisabled = env.NEXT_PUBLIC_DISABLE_MAP === 'true';

/** Optional deterministic seed for the mock ride lifecycle. */
export const simulationSeed = env.NEXT_PUBLIC_SIM_SEED;

/**
 * Share of driver searches that fail (0 - 1).
 *
 * `0` keeps the demo deterministic; `1` fails every search. The value is
 * clamped, so an invalid env value behaves like `0`.
 */
export const simulationFailureRate = env.NEXT_PUBLIC_SIM_FAIL_RATE;

export type PublicEnv = z.infer<typeof envSchema>;
