/**
 * Server-only demo credentials.
 *
 * MUST NEVER be imported by a client component: the values are read from
 * server-only environment variables and passed to the client forms as props,
 * only while demo auth is enabled. Keeping the plaintext values out of the
 * source also keeps them out of the production server chunks.
 *
 * A production build compiles `isDemoAuthEnabled` to `false`, so both getters
 * return `null` before reading the environment.
 */

import { isDemoAuthEnabled } from '@/lib/config/env';

/** The demo login the login screen offers, or `null` when it is not configured. */
export function getDemoLogin(): { phone: string; password: string } | null {
  if (!isDemoAuthEnabled) return null;

  const phone = process.env.DEMO_LOGIN_PHONE?.trim();
  const password = process.env.DEMO_LOGIN_PASSWORD?.trim();
  if (!phone || !password) return null;

  return { phone, password };
}

/** The demo OTP the OTP screen offers, or `null` when it is not configured. */
export function getDemoOtp(): string | null {
  if (!isDemoAuthEnabled) return null;
  return process.env.DEMO_LOGIN_OTP?.trim() || null;
}
