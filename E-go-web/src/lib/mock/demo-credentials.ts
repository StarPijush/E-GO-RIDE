/**
 * Demo account identifiers and credential verifiers for the mock auth layer.
 *
 * These are synthetic development values - they are not a real user, a real
 * phone number or a real secret. The plain-text demo password and OTP are NOT
 * kept here: only salted PBKDF2-SHA-256 verifiers are, so a production bundle
 * cannot be grepped for the demo credentials (architecture §6, amendment A4/R7).
 *
 * The verifiers are hashes, not secrets: they prove knowledge of the approved
 * demo values without shipping those values in client code. The demo UI reads
 * the plaintext values from server-only environment variables through
 * `lib/config/demo-server.ts` and receives them as page props.
 *
 * Nothing in `lib/domain/*` may import this module.
 */

import { isDemoAuthEnabled } from '@/lib/config/env';

/** Phone number of the seeded demo account. */
export const DEMO_PHONE = '9000000001';

/** Display name of the seeded demo account. */
export const DEMO_NAME = 'E-GO Demo User';

/** Email of the seeded demo account. */
export const DEMO_EMAIL = 'demo@ego.local';

/** Stable id of the seeded demo account. */
export const DEMO_USER_ID = 'demo-ego-001';

/**
 * PBKDF2-SHA-256 (10,000 iterations, 32 bytes, hex) verifier of the approved
 * demo password. A verifier, not a secret.
 */
export const DEMO_PASSWORD_VERIFIER = {
  salt: '00112233445566778899aabbccddeeff',
  hash: '1475aad91c8963efe92791e662a5b18feaed20a66013917491808cb256f4975d',
} as const;

/**
 * PBKDF2-SHA-256 (10,000 iterations, 32 bytes, hex) verifier of the approved
 * demo OTP. A verifier, not a secret.
 */
export const DEMO_OTP_VERIFIER = {
  salt: 'ffeeddccbbaa99887766554433221100',
  hash: 'fceddb913d09765c7aa08c413622d6899b2378bd9f8d830ddb7690a1cf221070',
} as const;

/**
 * True when the demo experience is enabled: the env flag is set and the
 * bundle is not a production build.
 */
export function isDemoMode(): boolean {
  return isDemoAuthEnabled;
}
