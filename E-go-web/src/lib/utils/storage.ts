/**
 * SSR-safe `localStorage` helpers.
 *
 * Every function degrades gracefully: on the server (no `window`), in private
 * browsing modes that throw `SecurityError` and when the quota is exceeded,
 * the helpers return `null` / `false` instead of throwing.
 *
 * Storage is never read at module scope - the helpers are always called from
 * an effect, an event handler or a repository call.
 */

/** Prefix of every E-GO persistence key. */
export const STORAGE_PREFIX = 'ego:';

function getStorage(): Storage | null {
  if (typeof window === 'undefined') return null;
  try {
    const storage = window.localStorage;
    return storage ?? null;
  } catch {
    // Access itself can throw when cookies/storage are blocked.
    return null;
  }
}

/** True when `localStorage` is usable in the current environment. */
export function hasStorage(): boolean {
  return getStorage() !== null;
}

/** The raw string stored under `key`, or `null`. */
export function readRaw(key: string): string | null {
  const storage = getStorage();
  if (!storage) return null;
  try {
    return storage.getItem(key);
  } catch {
    return null;
  }
}

/** Why a write failed. */
export interface WriteResult {
  ok: boolean;
  /**
   * - `unavailable`: no storage, or access was blocked (`SecurityError`);
   * - `quota`: the storage quota is exceeded;
   * - `serialize`: the value could not be turned into JSON.
   */
  reason?: 'unavailable' | 'quota' | 'serialize';
}

/** The DOMException codes of a full quota and of blocked storage. */
const QUOTA_EXCEEDED_ERR = 22;
const SECURITY_ERR = 1014;

function errorCode(error: unknown): number | undefined {
  if (typeof error !== 'object' || error === null) return undefined;
  const code = (error as { code?: unknown }).code;
  return typeof code === 'number' ? code : undefined;
}

/** Classify a failed write so the caller can react (toast, disable saving). */
function classifyWriteError(error: unknown): WriteResult {
  const name = error instanceof Error ? error.name : '';
  const code = errorCode(error);
  if (name === 'QuotaExceededError' || code === QUOTA_EXCEEDED_ERR) {
    return { ok: false, reason: 'quota' };
  }
  if (name === 'SecurityError' || code === SECURITY_ERR) {
    return { ok: false, reason: 'unavailable' };
  }
  return { ok: false, reason: 'unavailable' };
}

/**
 * Store a raw string.
 *
 * Unlike {@link writeRaw} the reason of a failure is returned, so a caller
 * can tell a full quota from a blocked storage.
 */
export function writeRawResult(key: string, value: string): WriteResult {
  const storage = getStorage();
  if (!storage) return { ok: false, reason: 'unavailable' };
  try {
    storage.setItem(key, value);
    return { ok: true };
  } catch (error) {
    return classifyWriteError(error);
  }
}

/** Store a raw string. Returns `false` when storage is unavailable or full. */
export function writeRaw(key: string, value: string): boolean {
  return writeRawResult(key, value).ok;
}

/** Remove a key. Returns `false` when storage is unavailable. */
export function removeKey(key: string): boolean {
  const storage = getStorage();
  if (!storage) return false;
  try {
    storage.removeItem(key);
    return true;
  } catch {
    return false;
  }
}

/**
 * Read and parse a JSON payload.
 *
 * `parse` receives the parsed JSON value and returns the typed value, or
 * `null` when the payload is invalid. Parse errors never escape.
 */
export function readJson<T>(key: string, parse: (value: unknown) => T | null): T | null {
  const raw = readRaw(key);
  if (raw === null) return null;
  let decoded: unknown;
  try {
    decoded = JSON.parse(raw);
  } catch {
    return null;
  }
  try {
    return parse(decoded);
  } catch {
    return null;
  }
}

/**
 * Serialize and store a JSON payload.
 *
 * Unlike {@link writeJson} the reason of a failure is returned.
 */
export function writeJsonResult(key: string, value: unknown): WriteResult {
  let encoded: string;
  try {
    encoded = JSON.stringify(value);
  } catch {
    return { ok: false, reason: 'serialize' };
  }
  return writeRawResult(key, encoded);
}

/** Serialize and store a JSON payload. Returns `false` on failure. */
export function writeJson(key: string, value: unknown): boolean {
  return writeJsonResult(key, value).ok;
}

/** Remove every `ego:*` key (used by "clear demo data"). */
export function removeEgoKeys(): void {
  const storage = getStorage();
  if (!storage) return;

  const keys: string[] = [];
  try {
    for (let index = 0; index < storage.length; index += 1) {
      const key = storage.key(index);
      if (key && key.startsWith(STORAGE_PREFIX)) keys.push(key);
    }
  } catch {
    return;
  }

  for (const key of keys) removeKey(key);
}
