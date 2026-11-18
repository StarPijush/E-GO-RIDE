import Image from 'next/image';
import Link from 'next/link';
import { Bike, Star } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { ROUTES } from '@/lib/config/routes';
import { formatINR } from '@/lib/domain/fare';
import { bookingStatusCopy, vehicleCopy } from '@/lib/domain/labels';
import type { Ride } from '@/lib/domain/types';
import { formatDateTime } from '@/lib/utils/format';
import { cn } from '@/lib/utils/cn';

export interface RideCardProps {
  /** The ride of the card. */
  ride: Ride;
  className?: string;
}

/** One ride of the history. */
export function RideCard({ ride, className }: RideCardProps) {
  const copy = bookingStatusCopy[ride.status];

  return (
    <Link
      href={`${ROUTES.rideDetails}/${ride.id}`}
      aria-label={`Ride ${ride.id}: ${ride.pickup.label} to ${ride.destination.label}`}
      className={cn(
        'block rounded-card',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
        className,
      )}
    >
      <Card padding="md" className="transition-colors hover:border-navy-soft">
        <div className="flex flex-col gap-3">
          <div className="flex items-center justify-between gap-3">
            <span className="flex items-center gap-2 font-semibold text-navy">
              {ride.vehicle === 'bike' ? (
                <Bike aria-hidden="true" className="size-4" />
              ) : (
                <Image
                  src="/branding/ego_logo_icon.png"
                  alt=""
                  width={18}
                  height={18}
                  className="size-[18px] object-contain"
                />
              )}
              {vehicleCopy[ride.vehicle].name}
            </span>

            <Badge tone={copy.tone}>{copy.label}</Badge>
          </div>

          <div className="flex flex-col gap-1.5">
            <div className="flex items-start gap-2">
              <span
                aria-hidden="true"
                className="mt-1.5 size-2 shrink-0 rounded-full border border-navy bg-brand"
              />
              <span className="flex min-w-0 flex-col">
                <span className="truncate text-sm font-medium text-navy">
                  {ride.pickup.label}
                </span>
                <span className="truncate text-xs text-muted">{ride.pickup.address}</span>
              </span>
            </div>

            <div className="flex items-start gap-2">
              <span
                aria-hidden="true"
                className="mt-1.5 size-2 shrink-0 rotate-45 rounded-[2px] bg-navy"
              />
              <span className="flex min-w-0 flex-col">
                <span className="truncate text-sm font-medium text-navy">
                  {ride.destination.label}
                </span>
                <span className="truncate text-xs text-muted">{ride.destination.address}</span>
              </span>
            </div>
          </div>

          <div className="flex items-center justify-between gap-3 border-t border-line pt-3">
            <span className="text-xs text-muted">{formatDateTime(ride.createdAt)}</span>

            {ride.rating ? (
              <span className="flex items-center gap-1 text-xs text-muted">
                <Star aria-hidden="true" className="size-3.5" />
                {ride.rating.stars}
              </span>
            ) : null}

            <span className="font-display text-base font-bold text-navy">
              {formatINR(ride.fare.total)}
            </span>
          </div>
        </div>
      </Card>
    </Link>
  );
}
