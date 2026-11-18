/**
 * The markers of the E-GO map.
 *
 * They are `divIcon`s with inline styles - the default Leaflet images are
 * broken in bundlers and the brand markers have to look like the app.
 *
 * Only fixed values are interpolated: no user data ever reaches the HTML of
 * a marker.
 *
 * This module imports Leaflet, so it may only be used by the inner map
 * (which is loaded on the client only).
 */

import L from 'leaflet';

const NAVY = '#142B45';
const BRAND = '#FFC928';
const WHITE = '#FFFFFF';

/** The pickup marker: a yellow dot with a navy ring. */
export const pickupIcon = L.divIcon({
  className: 'ego-map-marker',
  html: `<span style="display:block;position:relative;width:28px;height:28px;border-radius:50%;background:${BRAND};border:3px solid ${NAVY};box-sizing:border-box;box-shadow:0 1px 4px rgb(20 43 69 / 0.3);"><span style="position:absolute;left:50%;top:50%;width:8px;height:8px;margin:-4px 0 0 -4px;border-radius:50%;background:${WHITE};"></span></span>`,
  iconSize: [28, 28],
  iconAnchor: [14, 14],
});

/** The destination marker: a navy pin with a white ring. */
export const destinationIcon = L.divIcon({
  className: 'ego-map-marker',
  html: `<span style="display:block;position:relative;width:30px;height:30px;border-radius:50% 50% 50% 0;transform:rotate(-45deg);background:${NAVY};border:3px solid ${WHITE};box-sizing:border-box;box-shadow:0 1px 4px rgb(20 43 69 / 0.35);"><span style="position:absolute;left:50%;top:50%;width:8px;height:8px;margin:-4px 0 0 -4px;border-radius:50%;background:${WHITE};"></span></span>`,
  iconSize: [30, 30],
  iconAnchor: [15, 30],
});

/** The driver marker: a navy pill with the letter of the vehicle. */
export function driverIcon(vehicle: 'bike' | 'toto'): L.DivIcon {
  const letter = vehicle === 'bike' ? 'B' : 'T';

  return L.divIcon({
    className: 'ego-map-marker',
    html: `<span style="display:flex;align-items:center;justify-content:center;width:34px;height:26px;border-radius:13px;background:${NAVY};color:${WHITE};font-family:inherit;font-size:13px;font-weight:700;box-shadow:0 2px 6px rgb(20 43 69 / 0.35);">${letter}</span>`,
    iconSize: [34, 26],
    iconAnchor: [17, 13],
  });
}
