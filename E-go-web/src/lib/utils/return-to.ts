/**
 * Sanitizing of the `returnTo` parameter.
 *
 * After a login the app sends the passenger back to the page they wanted.
 * That parameter comes from the URL, so it is untrusted: it may only be an
 * internal path of a protected route. Everything else falls back to the
 * home screen - never an error, never a throw.
 */

import { ALLOWED_RETURN_TO_SEGMENTS } from '@/lib/config/routes';

/** The longest accepted path. */
const MAX_LENGTH = 300;

/** Characters that are never part of a safe path. */
function isSafePath(value: string): boolean {
  if (!value.startsWith('/')) return false;
  // "//host" is a protocol relative URL, not a path.
  if (value.startsWith('//')) return false;
  if (value.includes('\\')) return false;
  if (value.includes(':')) return false;
  if (value.includes('#')) return false;

  for (const character of value) {
    const code = character.codePointAt(0) ?? 0;
    // Control characters (C0 and DEL).
    if (code < 0x20 || code === 0x7f) return false;
  }
  return true;
}

/**
 * A safe `returnTo` path, or the fallback.
 *
 * The path must
 * - be at most 300 characters long,
 * - start with exactly one `/`,
 * - contain no backslash, colon, hash or control character,
 * - survive one `decodeURIComponent` pass unchanged (no encoded escapes),
 * - and point at an allowlisted (protected) route.
 *
 * The query string is kept, everything else is dropped.
 */
export function sanitizeReturnTo(raw: string | null | undefined, fallback = '/home'): string {
  if (typeof raw !== 'string') return fallback;

  const candidate = raw.trim();
  if (candidate.length === 0 || candidate.length > MAX_LENGTH) return fallback;
  if (!isSafePath(candidate)) return fallback;

  let decoded: string;
  try {
    decoded = decodeURIComponent(candidate);
  } catch {
    // A broken escape sequence is never a path.
    return fallback;
  }
  if (decoded.length === 0 || decoded.length > MAX_LENGTH) return fallback;
  if (!isSafePath(decoded)) return fallback;

  const [path] = decoded.split('?');
  const segment = path.split('/').filter(Boolean)[0];
  if (!segment || !ALLOWED_RETURN_TO_SEGMENTS.includes(segment)) return fallback;

  return decoded;
}
