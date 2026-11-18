import { distanceKm, formatDistanceKm } from '@/lib/domain/geo';
import type { Driver, Place } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface MapSummaryProps {
  pickup?: Place | null;
  destination?: Place | null;
  driver?: Driver | null;
  className?: string;
}

/**
 * The text version of the map.
 *
 * It is the accessible description of the route (and the visible part of the
 * fallback). The caller decides whether it is visible or `sr-only`.
 */
export function MapSummary({
  pickup,
  destination,
  driver,
  className,
}: MapSummaryProps) {
  const pickupLabel = pickup?.label ?? 'Pickup not set';
  const destinationLabel = destination?.label ?? 'Destination not set';

  return (
    <div role="group" aria-label="Route summary" className={cn('flex flex-col gap-1', className)}>
      <p className="text-sm text-navy">
        From {pickupLabel} to {destinationLabel}
      </p>

      {pickup && destination ? (
        <p className="text-xs text-muted">{formatDistanceKm(distanceKm(pickup, destination))}</p>
      ) : null}

      {driver ? <p className="text-xs text-muted">Driver en route (simulated)</p> : null}
    </div>
  );
}
