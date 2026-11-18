import { describe, expect, it } from 'vitest';

import { distanceKm, roundToWhole } from '@/lib/domain/geo';
import { calculateFare, formatINR, vehicleOptions, VEHICLE_META } from '@/lib/domain/fare';
import type { LatLng } from '@/lib/domain/types';

const ORIGIN: LatLng = { lat: 22.4529, lng: 86.9003 };

/** Exact destination point `km` kilometres due north of `origin` (great circle). */
function pointAtDistanceKm(origin: LatLng, km: number): LatLng {
  const angularDistance = km / 6371;
  return {
    lat: origin.lat + (angularDistance * 180) / Math.PI,
    lng: origin.lng,
  };
}

describe('calculateFare', () => {
  it('charges the minimum distance for a trip to the same point (bike)', () => {
    const fare = calculateFare('bike', ORIGIN, ORIGIN);
    expect(fare.distanceKm).toBe(0.5);
    expect(fare.distanceFare).toBe(5);
    expect(fare.total).toBe(28);
    expect(fare.estimatedMinutes).toBe(5);
    expect(fare.estimatedArrivalMinutes).toBe(3);
  });

  it('charges the minimum distance for a trip to the same point (toto)', () => {
    const fare = calculateFare('toto', ORIGIN, ORIGIN);
    expect(fare.distanceKm).toBe(0.5);
    expect(fare.distanceFare).toBe(4);
    expect(fare.total).toBe(21);
    expect(fare.estimatedMinutes).toBe(8);
    expect(fare.estimatedArrivalMinutes).toBe(5);
  });

  it('prices a 2 km trip', () => {
    const destination = pointAtDistanceKm(ORIGIN, 2);
    expect(distanceKm(ORIGIN, destination)).toBeCloseTo(2, 2);

    const bike = calculateFare('bike', ORIGIN, destination);
    expect(bike.distanceFare).toBe(20);
    expect(bike.total).toBe(43);
    expect(bike.estimatedMinutes).toBe(9);

    const toto = calculateFare('toto', ORIGIN, destination);
    expect(toto.distanceFare).toBe(14);
    expect(toto.total).toBe(31);
    expect(toto.estimatedMinutes).toBe(15);
  });

  it('prices a 5 km trip', () => {
    const destination = pointAtDistanceKm(ORIGIN, 5);
    expect(distanceKm(ORIGIN, destination)).toBeCloseTo(5, 2);

    const bike = calculateFare('bike', ORIGIN, destination);
    expect(bike.distanceFare).toBe(50);
    expect(bike.total).toBe(73);
    expect(bike.estimatedMinutes).toBe(18);

    const toto = calculateFare('toto', ORIGIN, destination);
    expect(toto.distanceFare).toBe(35);
    expect(toto.total).toBe(52);
    expect(toto.estimatedMinutes).toBe(30);
  });

  it('always totals base + distance + platform', () => {
    const destination = pointAtDistanceKm(ORIGIN, 4.2);
    for (const vehicle of ['bike', 'toto'] as const) {
      const fare = calculateFare(vehicle, ORIGIN, destination);
      expect(fare.total).toBe(fare.baseFare + fare.distanceFare + fare.platformFee);
      expect(Number.isInteger(fare.total)).toBe(true);
      expect(Number.isInteger(fare.distanceFare)).toBe(true);
    }
  });

  it('uses the exact effective distance for the fare and rounds only for display', () => {
    const destination = pointAtDistanceKm(ORIGIN, 4.24);
    const fare = calculateFare('bike', ORIGIN, destination);
    const exact = Math.max(0.5, distanceKm(ORIGIN, destination));
    expect(fare.distanceFare).toBe(roundToWhole(exact * 10));
    expect(fare.distanceKm).toBe(Number(exact.toFixed(1)));
  });

  it('never charges less than the minimum distance', () => {
    const near = pointAtDistanceKm(ORIGIN, 0.05);
    expect(distanceKm(ORIGIN, near)).toBeLessThan(0.5);
    expect(calculateFare('bike', ORIGIN, near).distanceKm).toBe(0.5);
    expect(calculateFare('bike', ORIGIN, near).distanceFare).toBe(5);
    expect(calculateFare('toto', ORIGIN, near).distanceFare).toBe(4);
  });

  it('clamps the estimated travel time', () => {
    const far = pointAtDistanceKm(ORIGIN, 400);
    expect(calculateFare('bike', ORIGIN, far).estimatedMinutes).toBe(60);
    expect(calculateFare('toto', ORIGIN, far).estimatedMinutes).toBe(90);
  });

  it('rounds halves up like the Dart pricing code', () => {
    // Dart: (3.5).toStringAsFixed(0) == "4", (4.5).toStringAsFixed(0) == "5".
    expect(roundToWhole(3.5)).toBe(4);
    expect(roundToWhole(4.5)).toBe(5);
    expect(roundToWhole(3.5)).toBe(Number((3.5).toFixed(0)));
    expect(roundToWhole(4.5)).toBe(Number((4.5).toFixed(0)));
  });
});

describe('vehicleOptions', () => {
  it('describes both vehicles and quotes their fares', () => {
    const destination = pointAtDistanceKm(ORIGIN, 2);
    const options = vehicleOptions(ORIGIN, destination);

    expect(options).toHaveLength(2);
    expect(options[0]).toMatchObject({
      type: 'bike',
      name: 'Bike',
      description: 'Fast & affordable',
      capacity: 1,
      estimatedArrivalMinutes: 3,
      fare: 43,
    });
    expect(options[1]).toMatchObject({
      type: 'toto',
      name: 'Toto (E-Rickshaw)',
      description: 'E-Rickshaw · Up to 3 passengers',
      capacity: 3,
      estimatedArrivalMinutes: 5,
      fare: 31,
    });
    expect(VEHICLE_META.bike.capacity).toBe(1);
    expect(VEHICLE_META.toto.capacity).toBe(3);
  });
});

describe('formatINR', () => {
  it('formats whole rupees', () => {
    expect(formatINR(28)).toBe('₹28');
    expect(formatINR(0)).toBe('₹0');
  });

  it('groups thousands the Indian way', () => {
    expect(formatINR(1234)).toBe('₹1,234');
    expect(formatINR(123456)).toBe('₹1,23,456');
    expect(formatINR(12345678)).toBe('₹1,23,45,678');
  });
});
