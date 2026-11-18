import Image from 'next/image';
import { Bike } from 'lucide-react';

import { formatDistanceKm } from '@/lib/domain/geo';
import { formatINR } from '@/lib/domain/fare';
import { vehicleCopy } from '@/lib/domain/labels';
import type { FareBreakdown, VehicleType } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface VehicleSummaryProps {
  /** The vehicle of the ride. */
  vehicle: VehicleType;
  /** The fare of the ride (for the distance, the duration and the price). */
  fare: FareBreakdown;
  /** A smaller row, for a card inside another card. */
  compact?: boolean;
  className?: string;
}

/** The vehicle of a ride with its distance, duration and price. */
export function VehicleSummary({
  vehicle,
  fare,
  compact = false,
  className,
}: VehicleSummaryProps) {
  const copy = vehicleCopy[vehicle];

  return (
    <div className={cn('flex items-center gap-3', className)}>
      <span
        className={cn(
          'flex shrink-0 items-center justify-center rounded-card bg-brand-soft',
          compact ? 'size-10' : 'size-12',
        )}
      >
        {vehicle === 'bike' ? (
          <Bike aria-hidden="true" className={compact ? 'size-5 text-navy' : 'size-6 text-navy'} />
        ) : (
          <Image
            src="/branding/ego_logo_icon.png"
            alt=""
            width={28}
            height={28}
            className={compact ? 'size-5 object-contain' : 'size-7 object-contain'}
          />
        )}
      </span>

      <span className="flex min-w-0 flex-1 flex-col">
        <span className="truncate font-display text-base font-semibold text-navy">
          {copy.name}
        </span>
        <span className="truncate text-xs text-muted">
          {formatDistanceKm(fare.distanceKm)} · {fare.estimatedMinutes} min trip
        </span>
      </span>

      <span className="shrink-0 font-display text-lg font-bold text-navy">
        {formatINR(fare.total)}
      </span>
    </div>
  );
}
