/**
 * Indian mobile number normalization.
 *
 * Line-for-line port of `E-go/lib/features/auth/domain/auth_validators.dart`
 * (`AuthValidators.normalizePhone`):
 * - strip every non-digit character;
 * - 12 digits starting with `91` -> drop the country code;
 * - 11 digits starting with `0` -> drop the trunk prefix;
 * - the remaining 10 digits must match `^[6-9]\d{9}$`;
 * - the canonical form is E.164 (`+91XXXXXXXXXX`).
 */

/** National mobile number pattern (10 digits, first digit 6-9). */
export const NATIONAL_MOBILE_PATTERN = /^[6-9]\d{9}$/;

/**
 * The 10 digit national number for `raw`, or `null` when the input is not a
 * valid Indian mobile number.
 */
export function normalizePhoneDigits(raw: string): string | null {
  const digits = raw.replace(/\D/g, '');
  let national = digits;

  if (digits.length === 12 && digits.startsWith('91')) {
    national = digits.slice(2);
  } else if (digits.length === 11 && digits.startsWith('0')) {
    national = digits.slice(1);
  }

  return NATIONAL_MOBILE_PATTERN.test(national) ? national : null;
}

/** The E.164 form (`+919000000001`), or `null` when the input is invalid. */
export function normalizePhone(raw: string): string | null {
  const national = normalizePhoneDigits(raw);
  return national === null ? null : `+91${national}`;
}

/** True when `raw` is a valid Indian mobile number. */
export function isValidPhone(raw: string): boolean {
  return normalizePhone(raw) !== null;
}

/**
 * Display form of a phone number: `+91 90000 00001`.
 * Invalid input is returned trimmed and unchanged.
 */
export function formatPhoneDisplay(raw: string): string {
  const national = normalizePhoneDigits(raw);
  if (national === null) return raw.trim();
  return `+91 ${national.slice(0, 5)} ${national.slice(5)}`;
}
