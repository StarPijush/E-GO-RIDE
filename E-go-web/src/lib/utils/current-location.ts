import { MOCK_CURRENT_LOCATION } from '@/lib/config/constants';
import type { Place } from '@/lib/domain/types';

/**
 * The pickup point of the demo.
 *
 * This is **not** the browser GPS: the demo never asks for the location
 * permission, it simply uses a fixed point in Jhargram (the station area).
 */
export const CURRENT_LOCATION_PLACE: Place = {
  id: 'current-location',
  label: 'Current location',
  address: 'Jhargram, West Bengal',
  kind: 'pickup',
  ...MOCK_CURRENT_LOCATION,
};
