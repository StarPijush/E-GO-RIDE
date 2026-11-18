/**
 * Identifier helpers.
 *
 * New records get a `crypto.randomUUID()`. Older browsers (and non-secure
 * contexts) fall back to a random v4 shaped UUID built from
 * `crypto.getRandomValues`, or from `Math.random` when even that is missing.
 */

/** True when the runtime exposes a usable `crypto.randomUUID()`. */
export function hasRandomUuid(): boolean {
  return typeof globalThis.crypto?.randomUUID === 'function';
}

function randomBytes(length: number): Uint8Array {
  const bytes = new Uint8Array(length);
  const webCrypto = globalThis.crypto;
  if (typeof webCrypto?.getRandomValues === 'function') {
    webCrypto.getRandomValues(bytes);
    return bytes;
  }
  for (let index = 0; index < length; index += 1) {
    bytes[index] = Math.floor(Math.random() * 256);
  }
  return bytes;
}

/** A random UUID, using `crypto.randomUUID()` when available. */
export function uuid(): string {
  if (hasRandomUuid()) return globalThis.crypto.randomUUID();

  const bytes = randomBytes(16);
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant 10xx
  const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`;
}

/**
 * A new identifier, optionally prefixed: `newId('user')` -> `user-<uuid>`.
 * The prefix is trimmed and must not end with a dash.
 */
export function newId(prefix?: string): string {
  const id = uuid();
  if (!prefix) return id;
  const clean = prefix.trim().replace(/-+$/, '');
  return clean ? `${clean}-${id}` : id;
}

let lastRideStamp = 0;
let rideCounter = 0;

/**
 * A ride identifier: `EGO-<epoch ms>`, with a `-<n>` suffix when several
 * rides are created inside the same millisecond.
 */
export function newRideId(now: Date = new Date()): string {
  const stamp = now.getTime();
  if (stamp === lastRideStamp) {
    rideCounter += 1;
  } else {
    lastRideStamp = stamp;
    rideCounter = 0;
  }
  return rideCounter === 0 ? `EGO-${stamp}` : `EGO-${stamp}-${rideCounter}`;
}
