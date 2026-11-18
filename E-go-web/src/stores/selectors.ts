/**
 * Pure selectors of the stores.
 *
 * No React hooks here: a selector is a function that turns a state into a
 * value, so it can be tested and reused outside a component.
 */

import type { AuthSession, User } from '@/lib/domain/types';
import type { AuthState } from '@/stores/auth-store';

/** The signed-in user (or `null`). */
export function selectUser(state: AuthState): User | null {
  return state.user;
}

/** The session (or `null`). */
export function selectSession(state: AuthState): AuthSession | null {
  return state.session;
}

/** True while the session is valid. */
export function selectIsAuthenticated(state: AuthState): boolean {
  if (!state.session) return false;
  return Date.parse(state.session.expiresAt) > Date.now();
}

/** True when the user still has to complete the profile. */
export function selectNeedsProfileSetup(state: AuthState): boolean {
  if (!state.user) return false;
  return !state.user.profileComplete;
}

/**
 * The initials of a name (at most two letters).
 *
 * `Asha Verma` becomes `AV`, `E-GO Demo User` becomes `EU`, `Asha` becomes
 * `AS`.
 */
export function selectInitials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '';
  if (parts.length === 1) return parts[0].slice(0, 2).toUpperCase();
  return `${parts[0][0]}${parts[parts.length - 1][0]}`.toUpperCase();
}

/**
 * The greeting of the day.
 *
 * The caller passes the date (after the first render), so the function stays
 * pure and testable.
 */
export function selectGreeting(name: string, date: Date = new Date()): string {
  const hour = date.getHours();
  const part = hour < 12 ? 'morning' : hour < 17 ? 'afternoon' : 'evening';
  const firstName = name.trim().split(/\s+/).filter(Boolean)[0] ?? '';
  return firstName ? `Good ${part}, ${firstName}` : `Good ${part}`;
}
