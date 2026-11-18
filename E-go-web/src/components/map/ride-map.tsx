'use client';

import dynamic from 'next/dynamic';
import { useEffect, useState, type ReactNode } from 'react';

import { MapFallback, type MapFallbackReason } from '@/components/map/map-fallback';
import { MapSummary } from '@/components/map/map-summary';
import { Button } from '@/components/ui';
import { isMapDisabled } from '@/lib/config/env';
import type { Driver, LatLng, Place } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface RideMapProps {
  pickup?: Place | null;
  destination?: Place | null;
  driver?: Driver | null;
  /** The map reacts to clicks. */
  interactive?: boolean;
  onMapClick?: (point: LatLng) => void;
  /** The size of the map (the default is a block of 280 px). */
  className?: string;
  /** An overlay on top of the map (the children opt back into the pointer). */
  children?: ReactNode;
  /** A separate height class, when the width and the height differ. */
  heightClassName?: string;
}

/** The placeholder while the map chunk loads. */
function MapLoading() {
  return (
    <div role="status" className="flex h-full w-full items-center justify-center bg-surface">
      <span className="sr-only">Loading map</span>
      <span className="size-8 animate-spin rounded-full border-2 border-navy/20 border-t-navy" />
    </div>
  );
}

/** Leaflet is only loaded in the browser, so it never reaches the server. */
const RideMapInner = dynamic(() => import('@/components/map/ride-map-inner'), {
  ssr: false,
  loading: () => <MapLoading />,
});

/**
 * The map of a ride.
 *
 * The wrapper owns the fallback: when the map is disabled, offline or broken,
 * a static diagram with the same information is shown instead.
 */
export function RideMap({
  pickup,
  destination,
  driver,
  interactive = false,
  onMapClick,
  className = 'h-[280px]',
  children,
  heightClassName,
}: RideMapProps) {
  const [failed, setFailed] = useState(false);
  const [offline, setOffline] = useState(false);
  const [retryKey, setRetryKey] = useState(0);

  useEffect(() => {
    const update = () => setOffline(!navigator.onLine);
    update();

    window.addEventListener('online', update);
    window.addEventListener('offline', update);
    return () => {
      window.removeEventListener('online', update);
      window.removeEventListener('offline', update);
    };
  }, []);

  const reason: MapFallbackReason = isMapDisabled ? 'disabled' : offline ? 'offline' : 'error';
  const showFallback = isMapDisabled || failed || offline;

  return (
    <div
      role="region"
      aria-label="Map showing pickup and destination"
      className={cn('relative overflow-hidden rounded-card', heightClassName ?? className)}
    >
      {showFallback ? (
        <MapFallback
          pickup={pickup}
          destination={destination}
          driver={driver}
          reason={reason}
          className="h-full w-full"
        />
      ) : (
        <>
          <RideMapInner
            key={retryKey}
            pickup={pickup}
            destination={destination}
            driver={driver}
            interactive={interactive}
            onMapClick={onMapClick}
            onTileError={() => setFailed(true)}
            className="h-full w-full"
          />
          <MapSummary pickup={pickup} destination={destination} driver={driver} className="sr-only" />
        </>
      )}

      {children ? (
        <div className="pointer-events-none absolute inset-0 z-10">{children}</div>
      ) : null}

      {failed && !isMapDisabled && !offline ? (
        <div className="pointer-events-auto absolute bottom-3 left-3 z-20">
          <Button
            variant="secondary"
            size="sm"
            onClick={() => {
              setFailed(false);
              setRetryKey((key) => key + 1);
            }}
          >
            Try map again
          </Button>
        </div>
      ) : null}
    </div>
  );
}
