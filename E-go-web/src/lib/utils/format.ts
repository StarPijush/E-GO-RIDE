/**
 * Display formatting helpers.
 *
 * Everything uses `Intl` with a fixed locale (`en-IN`) and a fixed time zone
 * (`Asia/Kolkata`) so the output is identical on every machine and in every
 * test. No date library is used.
 *
 * Relative times depend on the current clock, so they must only be rendered
 * after mount - the caller is responsible for that (see architecture §5).
 */

/** Locale used for every date, time and relative-time label. */
export const DATE_LOCALE = 'en-IN';

/** Fixed time zone so formatted dates do not depend on the host machine. */
export const DATE_TIME_ZONE = 'Asia/Kolkata';

/** Anything that can be turned into a date. */
export type DateInput = Date | string | number;

const dateFormatter = new Intl.DateTimeFormat(DATE_LOCALE, {
  day: 'numeric',
  month: 'short',
  year: 'numeric',
  timeZone: DATE_TIME_ZONE,
});

const timeFormatter = new Intl.DateTimeFormat(DATE_LOCALE, {
  hour: 'numeric',
  minute: '2-digit',
  hour12: true,
  timeZone: DATE_TIME_ZONE,
});

const relativeFormatter = new Intl.RelativeTimeFormat(DATE_LOCALE, { numeric: 'auto' });

/** Convert the supported inputs into a `Date`, or `null` when invalid. */
function toDate(value: DateInput): Date | null {
  const date = value instanceof Date ? value : new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

/** `6:42 PM` (upper case meridiem, no leading zero). */
function formatClock(value: DateInput): string {
  const date = toDate(value);
  if (!date) return '';
  return timeFormatter.format(date).replace(/\b(am|pm)\b/gi, (meridiem) => meridiem.toUpperCase());
}

/** `15 Nov 2026`. */
export function formatDate(value: DateInput = new Date()): string {
  const date = toDate(value);
  if (!date) return '';
  return dateFormatter.format(date);
}

/** `6:42 PM`. */
export function formatTime(value: DateInput = new Date()): string {
  return formatClock(value);
}

/** `15 Nov 2026 · 6:42 PM`. */
export function formatDateTime(value: DateInput = new Date()): string {
  const date = toDate(value);
  if (!date) return '';
  return `${formatDate(date)} · ${formatClock(date)}`;
}

/**
 * Relative label such as `2 min ago` or `in 3 days`.
 *
 * `now` is injectable so tests do not depend on the wall clock. Render only
 * after mount - the value changes with the clock.
 */
export function formatRelativeTime(value: DateInput, now: DateInput = new Date()): string {
  const date = toDate(value);
  const reference = toDate(now);
  if (!date || !reference) return '';

  const seconds = Math.round((date.getTime() - reference.getTime()) / 1000);
  const absolute = Math.abs(seconds);

  if (absolute < 45) return relativeFormatter.format(0, 'second');
  if (absolute < 90) return relativeFormatter.format(seconds < 0 ? -1 : 1, 'minute');
  if (absolute < 3600) return relativeFormatter.format(Math.round(seconds / 60), 'minute');
  if (absolute < 86_400) return relativeFormatter.format(Math.round(seconds / 3600), 'hour');
  if (absolute < 604_800) return relativeFormatter.format(Math.round(seconds / 86_400), 'day');
  if (absolute < 2_629_800) return relativeFormatter.format(Math.round(seconds / 604_800), 'week');
  if (absolute < 31_557_600) return relativeFormatter.format(Math.round(seconds / 2_629_800), 'month');
  return relativeFormatter.format(Math.round(seconds / 31_557_600), 'year');
}

/** A rating as displayed next to a star: `4`, `4.8`. */
export function formatStars(stars: number): string {
  if (!Number.isFinite(stars)) return '0';
  return String(Math.round(stars * 10) / 10);
}

/** Up to two initials of a name: `E-GO Demo User` -> `ED`, `Rohan` -> `R`. */
export function initials(name: string): string {
  const parts = name.trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '';
  const letters = parts.slice(0, 2).map((part) => part.charAt(0));
  return letters.join('').toUpperCase();
}
