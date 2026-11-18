import { MapPin } from 'lucide-react';

import { Card } from '@/components/ui/card';
import type { Place } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface RouteCardProps {
  pickup?: Place | null;
  destination?: Place | null;
  /** Less padding, for a card inside another card. */
  compact?: boolean;
  className?: string;
}

/**
 * The route of the booking (pickup and destination).
 *
 * The card is presentational: it never changes the booking itself.
 */
export function RouteCard({
  pickup,
  destination,
  compact = false,
  className,
}: RouteCardProps) {
  return (
    <Card
      padding={compact ? 'md' : 'lg'}
      className={cn(className)}
      aria-label="Your route"
    >
      <div className="flex flex-col gap-3">
        <div className="flex items-start gap-3">
          <span
            aria-hidden="true"
            className="mt-1 size-3 shrink-0 rounded-full border-2 border-navy bg-brand"
          />

          <div className="flex min-w-0 flex-col">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted">
              Pickup
            </span>
            <span className="truncate text-sm font-semibold text-navy">
              {pickup?.label ?? 'Pickup location'}
            </span>
            {pickup?.address ? (
              <span className="truncate text-xs text-muted">{pickup.address}</span>
            ) : null}
          </div>
        </div>

        <div aria-hidden="true" className="ml-[5px] h-4 border-l-2 border-dotted border-line" />

        <div className="flex items-start gap-3">
          <span aria-hidden="true" className="mt-0.5 flex size-4 shrink-0 items-center justify-center">
            <MapPin className="size-4 text-navy" />
          </span>

          <div className="flex min-w-0 flex-col">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted">
              Destination
            </span>
            <span className="truncate text-sm font-semibold text-navy">
              {destination?.label ?? 'Destination'}
            </span>
            {destination?.address ? (
              <span className="truncate text-xs text-muted">{destination.address}</span>
            ) : null}
          </div>
        </div>
      </div>
    </Card>
  );
}
