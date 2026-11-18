/**
 * Geographic helpers for E-GO Web.
 *
 * Ported from `E-go/lib/core/mock_pricing.dart` (`MockPricingService.distanceKm`):
 * the haversine formula with a mean earth radius of 6371 km.
 */

import type { LatLng } from '@/lib/domain/types';

/** Mean earth radius used by the Flutter pricing service, in kilometres. */
export const EARTH_RADIUS_KM = 6371;

const toRadians = (degrees: number): number => (degrees * Math.PI) / 180;

/**
 * Great-circle distance between two coordinates, in kilometres.
 *
 * Port rule: `a = sin(dLat/2)^2 + cos(lat1)*cos(lat2)*sin(dLon/2)^2`,
 * `c = 2*asin(sqrt(a))`, `distance = 6371 * c`.
 */
export function distanceKm(from: LatLng, to: LatLng): number {
  const lat1 = toRadians(from.lat);
  const lat2 = toRadians(to.lat);
  const dLat = toRadians(to.lat - from.lat);
  const dLng = toRadians(to.lng - from.lng);

  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(dLng / 2) ** 2;
  const c = 2 * Math.asin(Math.min(1, Math.sqrt(a)));
  return EARTH_RADIUS_KM * c;
}

/**
 * Round to a fixed number of decimals, mirroring Dart's `toStringAsFixed(n)`
 * (round half up on the exact binary value of the input).
 */
export function roundTo(value: number, decimals: number): number {
  return Number(value.toFixed(decimals));
}

/**
 * Round to a whole number. `Math.round` matches Dart's `toStringAsFixed(0)`
 * for the non-negative values used by the fare engine (3.5 -> 4, 4.5 -> 5).
 */
export function roundToWhole(value: number): number {
  return Math.round(value);
}

/** Round to one decimal place, for display-only distances. */
export function roundToTenth(value: number): number {
  return roundTo(value, 1);
}

/**
 * Human readable distance: metres under 1 km (`"0.45 km"`), kilometres with a
 * single decimal above that (`"2 km"`, `"12.7 km"`).
 */
export function formatDistanceKm(km: number): string {
  if (!Number.isFinite(km)) return '—';
  const value = km < 1 ? roundTo(km, 2) : roundTo(km, 1);
  return `${value} km`;
}
