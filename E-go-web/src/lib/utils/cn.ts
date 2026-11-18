/**
 * Class name helper.
 *
 * `clsx` resolves conditional class values, `tailwind-merge` removes
 * conflicting Tailwind utilities so the last one wins (e.g. `p-2 p-4` -> `p-4`).
 */

import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

/** Merge conditional class names and de-duplicate conflicting Tailwind utilities. */
export function cn(...inputs: ClassValue[]): string {
  return twMerge(clsx(inputs));
}
