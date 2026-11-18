import { describe, expect, it } from 'vitest';

import { distanceKm, formatDistanceKm, roundTo, roundToTenth, roundToWhole } from '@/lib/domain/geo';
import { MAP_CENTER, MOCK_CURRENT_LOCATION } from '@/lib/config/constants';
import type { LatLng } from '@/lib/domain/types';

describe('distanceKm', () => {
  it('returns 0 for identical points', () => {
    expect(distanceKm(MAP_CENTER, MAP_CENTER)).toBe(0);
  });

  it('matches the known distance of one degree of latitude', () => {
    // 1 degree of latitude is ~111.19 km with a 6371 km earth radius.
    const distance = distanceKm({ lat: 0, lng: 0 }, { lat: 1, lng: 0 });
    expect(distance).toBeCloseTo(111.1949, 3);
  });

  it('matches the known distance of one degree of longitude at the equator', () => {
    const distance = distanceKm({ lat: 0, lng: 0 }, { lat: 0, lng: 1 });
    expect(distance).toBeCloseTo(111.1949, 3);
  });

  it('shortens a degree of longitude with latitude', () => {
    const atEquator = distanceKm({ lat: 0, lng: 0 }, { lat: 0, lng: 1 });
    const atJhargram = distanceKm(MAP_CENTER, { lat: MAP_CENTER.lat, lng: MAP_CENTER.lng + 1 });
    expect(atJhargram).toBeLessThan(atEquator);
    expect(atJhargram).toBeCloseTo(102.7655, 3);
  });

  it('matches the known distance between the map centre and the mock location', () => {
    const distance = distanceKm(MAP_CENTER, MOCK_CURRENT_LOCATION);
    expect(distance).toBeCloseTo(0.2916, 4);
    expect(distance).toBeGreaterThan(0.29);
    expect(distance).toBeLessThan(0.3);
  });

  it('is symmetric', () => {
    const from: LatLng = { lat: 22.45, lng: 86.9 };
    const to: LatLng = { lat: 22.46, lng: 86.92 };
    expect(distanceKm(from, to)).toBeCloseTo(distanceKm(to, from), 12);
  });
});

describe('rounding helpers', () => {
  it('rounds to a fixed number of decimals', () => {
    expect(roundTo(2.6749999999999998, 1)).toBe(2.7);
    expect(roundTo(2.449, 2)).toBe(2.45);
    expect(roundTo(10, 1)).toBe(10);
  });

  it('rounds to one decimal', () => {
    expect(roundToTenth(2.449)).toBe(2.4);
    expect(roundToTenth(12.74)).toBe(12.7);
  });

  it('rounds halves up, like the Dart pricing code', () => {
    expect(roundToWhole(3.5)).toBe(4);
    expect(roundToWhole(4.5)).toBe(5);
    expect(roundToWhole(2.5)).toBe(3);
    expect(roundToWhole(2.4999)).toBe(2);
  });
});

describe('formatDistanceKm', () => {
  it('shows two decimals below one kilometre', () => {
    expect(formatDistanceKm(0.2916)).toBe('0.29 km');
  });

  it('shows one decimal from one kilometre upwards', () => {
    expect(formatDistanceKm(2)).toBe('2 km');
    expect(formatDistanceKm(12.74)).toBe('12.7 km');
  });

  it('handles invalid input', () => {
    expect(formatDistanceKm(Number.NaN)).toBe('—');
  });
});
