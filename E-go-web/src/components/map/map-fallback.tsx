import { MapSummary } from '@/components/map/map-summary';
import type { Driver, Place } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

/** Why the map is not shown. */
export type MapFallbackReason = 'disabled' | 'offline' | 'error';

export interface MapFallbackProps {
  pickup?: Place | null;
  destination?: Place | null;
  driver?: Driver | null;
  reason?: MapFallbackReason;
  className?: string;
}

/** The note of every reason. */
const NOTES: Record<MapFallbackReason, string> = {
  error: 'Map unavailable - showing locations',
  offline: "You're offline - showing locations",
  disabled: 'Map preview disabled - showing locations',
};

/**
 * The static diagram that replaces the map.
 *
 * It shows the same information without Leaflet (and without a network):
 * the route as a dashed line, the two markers and the driver.
 */
export function MapFallback({
  pickup,
  destination,
  driver,
  reason = 'error',
  className,
}: MapFallbackProps) {
  const pickupLabel = pickup?.label ?? 'Pickup not set';
  const destinationLabel = destination?.label ?? 'Destination not set';

  return (
    <div className={cn('relative h-full w-full overflow-hidden bg-surface', className)}>
      <div
        role="img"
        aria-label={`Map preview from ${pickupLabel} to ${destinationLabel}`}
        className="absolute inset-0"
      >
        <svg className="h-full w-full" aria-hidden="true" focusable="false">
          <defs>
            <pattern id="ego-map-grid" width="32" height="32" patternUnits="userSpaceOnUse">
              <path d="M32 0H0V32" fill="none" stroke="#E2E8F0" strokeWidth="1" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#ego-map-grid)" />
          <path
            d="M64 168 C 150 84, 226 196, 320 96"
            fill="none"
            stroke="#142B45"
            strokeWidth="4"
            strokeDasharray="6 8"
            strokeLinecap="round"
            opacity="0.75"
          />
        </svg>

        {/* The pickup marker */}
        <span
          aria-hidden="true"
          className="absolute left-[12%] top-[58%] block size-7 -translate-x-1/2 -translate-y-1/2 rounded-full border-[3px] border-navy bg-brand"
        />
        <span
          aria-hidden="true"
          className="absolute left-[12%] top-[58%] block size-2 -translate-x-1/2 -translate-y-1/2 rounded-full bg-white"
        />

        {/* The destination marker */}
        <span
          aria-hidden="true"
          className="absolute left-[78%] top-[28%] block size-7 -translate-x-1/2 -translate-y-1/2 rotate-[-45deg] rounded-br-none rounded-tl-full border-[3px] border-white bg-navy"
        />

        {/* The driver marker */}
        {driver ? (
          <span
            aria-hidden="true"
            className="absolute left-[46%] top-[44%] flex h-7 w-9 -translate-x-1/2 -translate-y-1/2 items-center justify-center rounded-full bg-navy text-[13px] font-bold text-white"
          >
            {driver.vehicleType === 'bike' ? 'B' : 'T'}
          </span>
        ) : null}
      </div>

      <div className="absolute inset-x-3 bottom-3 rounded-card bg-white p-3 shadow-card">
        <MapSummary pickup={pickup} destination={destination} driver={driver} />
        <p className="mt-1 text-xs text-muted">{NOTES[reason]}</p>
      </div>
    </div>
  );
}
