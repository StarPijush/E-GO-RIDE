/**
 * Demo credentials for the mock auth repository.
 *
 * These are synthetic development values - they are not a real user, a real
 * phone number or a real secret. They live in the mock layer (and not in
 * `lib/config/constants.ts`) so a production bundle can be grepped for them
 * (architecture §6, amendment A4/R7).
 *
 * Nothing in `lib/domain/*` may import this module.
 */

import { isDemoAuthEnabled } from '@/lib/config/env';

/** Phone number of the seeded demo account. */
export const DEMO_PHONE = '9000000001';

/** Password of the seeded demo account. */
export const DEMO_PASSWORD = 'EgoDemo@123';

/** Display name of the seeded demo account. */
export const DEMO_NAME = 'E-GO Demo User';

/** Email of the seeded demo account. */
export const DEMO_EMAIL = 'demo@ego.local';

/** OTP accepted while demo mode is enabled. */
export const DEMO_OTP = '123456';

/** Stable id of the seeded demo account. */
export const DEMO_USER_ID = 'demo-ego-001';

/**
 * True when the demo experience is enabled: the env flag is set and the
 * bundle is not a production build.
 */
export function isDemoMode(): boolean {
  return isDemoAuthEnabled;
}
