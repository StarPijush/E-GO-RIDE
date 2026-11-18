/**
 * Deterministic fare engine for E-GO Web.
 *
 * Ported from `E-go/lib/core/mock_pricing.dart`. All fares are demo
 * estimates - no real pricing API is involved.
 */

import { distanceKm, roundToTenth, roundToWhole } from '@/lib/domain/geo';
import { VEHICLE_TYPES, type FareBreakdown, type LatLng, type VehicleOption, type VehicleType } from '@/lib/domain/types';

/** Minimum distance charged for, in kilometres (Flutter: `distance < 0.5 ? 0.5 : distance`). */
export const MIN_FARE_DISTANCE_KM = 0.5;

/** Per-vehicle pricing rules, in whole rupees. */
export interface FareRules {
  baseFare: number;
  distanceRatePerKm: number;
  platformFee: number;
  /** Average travel speed used for the ETA, in km/h. */
  averageSpeedKmPerHour: number;
  /** Fixed minutes added to the travel time. */
  etaBufferMinutes: number;
  minEstimatedMinutes: number;
  maxEstimatedMinutes: number;
  /** Minutes until the vehicle reaches the pickup point. */
  estimatedArrivalMinutes: number;
}

/** Line-for-line port of the Dart `switch (vehicleType)` pricing rules. */
export const FARE_RULES: Record<VehicleType, FareRules> = {
  bike: {
    baseFare: 20,
    distanceRatePerKm: 10,
    platformFee: 3,
    averageSpeedKmPerHour: 20,
    etaBufferMinutes: 3,
    minEstimatedMinutes: 2,
    maxEstimatedMinutes: 60,
    estimatedArrivalMinutes: 3,
  },
  toto: {
    baseFare: 15,
    distanceRatePerKm: 7,
    platformFee: 2,
    averageSpeedKmPerHour: 12,
    etaBufferMinutes: 5,
    minEstimatedMinutes: 3,
    maxEstimatedMinutes: 90,
    estimatedArrivalMinutes: 5,
  },
};

/** Display metadata for the vehicle picker. */
export const VEHICLE_META: Record<VehicleType, { name: string; description: string; capacity: number }> = {
  bike: { name: 'Bike', description: 'Fast & affordable', capacity: 1 },
  toto: { name: 'Toto (E-Rickshaw)', description: 'E-Rickshaw · Up to 3 passengers', capacity: 3 },
};

const clamp = (value: number, min: number, max: number): number =>
  Math.min(Math.max(value, min), max);

/**
 * Fare breakdown for a trip.
 *
 * Port rules:
 * - effective distance = `max(0.5, haversine km)`
 * - `distanceFare = round(effectiveDistance * rate)` (Dart `toStringAsFixed(0)`)
 * - `estimatedMinutes = round(effectiveDistance / speed * 60 + buffer)`, clamped
 * - `total = baseFare + distanceFare + platformFee` (the rounded distance fare)
 * - `distanceKm` is rounded to one decimal for display only; the fare always
 *   uses the exact effective distance.
 */
export function calculateFare(vehicle: VehicleType, from: LatLng, to: LatLng): FareBreakdown {
  const rules = FARE_RULES[vehicle];
  const effectiveDistance = Math.max(MIN_FARE_DISTANCE_KM, distanceKm(from, to));

  const distanceFare = roundToWhole(effectiveDistance * rules.distanceRatePerKm);
  const estimatedMinutes = clamp(
    roundToWhole((effectiveDistance / rules.averageSpeedKmPerHour) * 60 + rules.etaBufferMinutes),
    rules.minEstimatedMinutes,
    rules.maxEstimatedMinutes,
  );

  return {
    vehicle,
    baseFare: rules.baseFare,
    distanceFare,
    platformFee: rules.platformFee,
    total: rules.baseFare + distanceFare + rules.platformFee,
    distanceKm: roundToTenth(effectiveDistance),
    estimatedMinutes,
    estimatedArrivalMinutes: rules.estimatedArrivalMinutes,
    currency: 'INR',
  };
}

/** Both vehicle options with their fare for the given trip, in picker order. */
export function vehicleOptions(from: LatLng, to: LatLng): VehicleOption[] {
  return VEHICLE_TYPES.map((type) => {
    const meta = VEHICLE_META[type];
    const fare = calculateFare(type, from, to);
    return {
      type,
      name: meta.name,
      description: meta.description,
      capacity: meta.capacity,
      estimatedArrivalMinutes: fare.estimatedArrivalMinutes,
      fare: fare.total,
    };
  });
}

/** Group digits the Indian way: last three, then pairs (`1,23,45,678`). */
function groupIndianDigits(value: string): string {
  if (value.length <= 3) return value;
  const lastThree = value.slice(-3);
  let rest = value.slice(0, -3);
  const groups: string[] = [];
  while (rest.length > 0) {
    groups.unshift(rest.slice(-2));
    rest = rest.slice(0, -2);
  }
  return [...groups, lastThree].join(',');
}

/** Format whole rupees for display, e.g. `28` -> `"₹28"`, `123456` -> `"₹1,23,456"`. */
export function formatINR(amount: number): string {
  if (!Number.isFinite(amount)) return '₹0';
  const rounded = Math.round(amount);
  const sign = rounded < 0 ? '-' : '';
  return `${sign}₹${groupIndianDigits(Math.abs(rounded).toString())}`;
}
