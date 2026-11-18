'use client';

import 'leaflet/dist/leaflet.css';

import { useCallback, useEffect, useMemo, useRef } from 'react';
import {
  MapContainer,
  Marker,
  Polyline,
  TileLayer,
  useMap,
  useMapEvents,
} from 'react-leaflet';

import { driverIcon, destinationIcon, pickupIcon } from '@/components/map/marker-icons';
import { env } from '@/lib/config/env';
import type { Driver, LatLng, Place } from '@/lib/domain/types';

export interface RideMapInnerProps {
  pickup?: Place | null;
  destination?: Place | null;
  driver?: Driver | null;
  /** The map reacts to clicks. */
  interactive?: boolean;
  onMapClick?: (point: LatLng) => void;
  className?: string;
  /** Called when the tiles keep failing. */
  onTileError?: () => void;
}

/** The center of Jhargram. */
const MAP_CENTER: [number, number] = [22.4529, 86.9003];

/** How many tile errors mean "the map does not work". */
const TILE_ERROR_LIMIT = 3;

/** The attribution of the tiles (required by the OpenStreetMap licence). */
const ATTRIBUTION =
  '&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors';

/** Moves the viewport so that the whole route is visible. */
function FitRoute({
  pickup,
  destination,
}: {
  pickup?: Place | null;
  destination?: Place | null;
}) {
  const map = useMap();

  const pickupLat = pickup?.lat;
  const pickupLng = pickup?.lng;
  const destinationLat = destination?.lat;
  const destinationLng = destination?.lng;

  useEffect(() => {
    if (
      pickupLat !== undefined &&
      pickupLng !== undefined &&
      destinationLat !== undefined &&
      destinationLng !== undefined
    ) {
      map.fitBounds(
        [
          [pickupLat, pickupLng],
          [destinationLat, destinationLng],
        ],
        { padding: [48, 48] },
      );
      return;
    }

    const lat = pickupLat ?? destinationLat;
    const lng = pickupLng ?? destinationLng;
    if (lat !== undefined && lng !== undefined) {
      map.setView([lat, lng], map.getZoom());
    }
  }, [map, pickupLat, pickupLng, destinationLat, destinationLng]);

  return null;
}

/** Forwards the clicks on the map. */
function MapClickHandler({ onMapClick }: { onMapClick: (point: LatLng) => void }) {
  useMapEvents({
    click: (event) => {
      onMapClick({ lat: event.latlng.lat, lng: event.latlng.lng });
    },
  });

  return null;
}

/**
 * The map itself.
 *
 * It is only loaded on the client (`ssr: false`), so Leaflet never reaches
 * the server render.
 */
export function RideMapInner({
  pickup,
  destination,
  driver,
  interactive = false,
  onMapClick,
  className,
  onTileError,
}: RideMapInnerProps) {
  const tileErrors = useRef(0);
  const reported = useRef(false);

  const handleTileError = useCallback(() => {
    tileErrors.current += 1;
    if (tileErrors.current >= TILE_ERROR_LIMIT && !reported.current) {
      reported.current = true;
      onTileError?.();
    }
  }, [onTileError]);

  const tileEventHandlers = useMemo(() => ({ tileerror: handleTileError }), [handleTileError]);

  return (
    <div aria-hidden="true" tabIndex={-1} className={className ?? 'h-full w-full'}>
      <MapContainer
        center={MAP_CENTER}
        zoom={14}
        scrollWheelZoom={false}
        className="h-full w-full"
      >
        <TileLayer
          url={env.NEXT_PUBLIC_MAP_TILE_URL}
          maxZoom={19}
          attribution={ATTRIBUTION}
          eventHandlers={tileEventHandlers}
        />

        <FitRoute pickup={pickup} destination={destination} />

        {interactive && onMapClick ? <MapClickHandler onMapClick={onMapClick} /> : null}

        {pickup ? (
          <Marker position={[pickup.lat, pickup.lng]} icon={pickupIcon} title={pickup.label} />
        ) : null}

        {destination ? (
          <Marker
            position={[destination.lat, destination.lng]}
            icon={destinationIcon}
            title={destination.label}
          />
        ) : null}

        {driver ? (
          <Marker
            position={[driver.location.lat, driver.location.lng]}
            icon={driverIcon(driver.vehicleType)}
            title={driver.name}
          />
        ) : null}

        {pickup && destination ? (
          <Polyline
            positions={[
              [pickup.lat, pickup.lng],
              [destination.lat, destination.lng],
            ]}
            pathOptions={{ color: '#142B45', weight: 4, dashArray: '6 8', opacity: 0.75 }}
          />
        ) : null}
      </MapContainer>
    </div>
  );
}

export default RideMapInner;
