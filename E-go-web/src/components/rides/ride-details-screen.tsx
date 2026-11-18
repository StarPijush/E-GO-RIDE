'use client';

import Link from 'next/link';

import { FareBreakdownRows } from '@/components/booking/fare-breakdown';
import { RouteCard } from '@/components/booking/route-card';
import { PageHeader } from '@/components/layout/page-header';
import { RatingStars } from '@/components/shared/rating-stars';
import { Avatar } from '@/components/ui/avatar';
import { Badge } from '@/components/ui/badge';
import { Card } from '@/components/ui/card';
import { EmptyState } from '@/components/ui/empty-state';
import { ErrorState } from '@/components/ui/error-state';
import { Skeleton } from '@/components/ui/skeleton';
import { ROUTES } from '@/lib/config/routes';
import { bookingStatusCopy, vehicleCopy } from '@/lib/domain/labels';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { getRepositories } from '@/lib/repositories';
import { formatDateTime, formatStars } from '@/lib/utils/format';
import { useAuthStore } from '@/stores/auth-store';

const linkClass =
  'text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

const primaryLinkClass =
  'inline-flex h-12 w-full items-center justify-center rounded-pill bg-brand px-5 font-semibold text-navy transition-colors hover:bg-brand-strong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export interface RideDetailsScreenProps {
  /** The id of the ride. */
  rideId: string;
}

/** The details of one ride of the history. */
export function RideDetailsScreen({ rideId }: RideDetailsScreenProps) {
  const user = useAuthStore((state) => state.user);

  const ride = useAsyncData(
    () => getRepositories().rides.getById(rideId),
    [rideId],
    { enabled: Boolean(rideId) },
  );

  // Only the owner of the ride may see it.
  const details = ride.data && ride.data.userId === user?.id ? ride.data : null;

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader title="Ride details" backHref={ROUTES.myRides} className="mb-5" />

      {ride.loading ? (
        <div className="flex flex-col gap-3">
          <Skeleton className="h-32 w-full rounded-card" />
          <Skeleton className="h-40 w-full rounded-card" />
          <Skeleton className="h-28 w-full rounded-card" />
        </div>
      ) : ride.error ? (
        <ErrorState
          title="The ride could not be loaded"
          message="Please try again."
          onRetry={ride.reload}
        />
      ) : !details ? (
        <EmptyState
          title="Ride not found"
          description="This ride does not exist or was removed."
          action={
            <Link href={ROUTES.myRides} className={linkClass}>
              Back to my rides
            </Link>
          }
        />
      ) : (
        <div className="flex flex-col gap-4">
          <Card padding="lg" className="flex flex-col gap-3">
            <div className="flex items-center justify-between gap-3">
              <span className="font-display text-base font-semibold text-navy">
                {vehicleCopy[details.vehicle].name}
              </span>
              <Badge tone={bookingStatusCopy[details.status].tone}>
                {bookingStatusCopy[details.status].label}
              </Badge>
            </div>

            <dl className="flex flex-col gap-2 text-sm">
              <div className="flex items-center justify-between gap-3">
                <dt className="text-xs font-semibold uppercase tracking-wider text-muted">
                  Trip ID
                </dt>
                <dd className="truncate font-medium text-navy">{details.id}</dd>
              </div>
              <div className="flex items-center justify-between gap-3">
                <dt className="text-xs font-semibold uppercase tracking-wider text-muted">Date</dt>
                <dd className="truncate font-medium text-navy">
                  {formatDateTime(details.createdAt)}
                </dd>
              </div>
              <div className="flex items-center justify-between gap-3">
                <dt className="text-xs font-semibold uppercase tracking-wider text-muted">Status</dt>
                <dd className="truncate font-medium text-navy">
                  {bookingStatusCopy[details.status].label}
                </dd>
              </div>
            </dl>

            {details.rating ? (
              <div className="flex flex-col gap-1 border-t border-line pt-3">
                <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                  Your rating
                </span>
                <RatingStars stars={details.rating.stars} />
                {details.rating.comment ? (
                  <p className="text-sm text-muted">{details.rating.comment}</p>
                ) : null}
              </div>
            ) : null}
          </Card>

          <RouteCard pickup={details.pickup} destination={details.destination} />

          <Card padding="lg">
            <FareBreakdownRows
              fare={details.fare}
              showPayment
              totalLabel="Total"
              paymentLabel="Cash"
            />
          </Card>

          <Card padding="lg" className="flex flex-col gap-3">
            <span className="text-xs font-semibold uppercase tracking-wider text-muted">Driver</span>

            {details.driver ? (
              <div className="flex items-center gap-3">
                <Avatar name={details.driver.name} size="md" />

                <div className="flex min-w-0 flex-1 flex-col">
                  <span className="truncate font-display text-base font-semibold text-navy">
                    {details.driver.name || 'Your driver'}
                  </span>
                  <span className="text-xs text-muted">
                    {vehicleCopy[details.driver.vehicleType].name} ·{' '}
                    {details.driver.vehicleNumber}
                  </span>
                  <span className="text-xs text-muted">{formatStars(details.driver.rating)}</span>
                </div>
              </div>
            ) : (
              <p className="text-sm text-muted">No demo driver was assigned.</p>
            )}
          </Card>

          {details.status === 'awaitingRating' ? (
            <div className="flex flex-col gap-2">
              <Link
                href={`${ROUTES.rideRating}?rideId=${details.id}`}
                className={primaryLinkClass}
              >
                Rate this ride
              </Link>
              <p className="text-center text-xs text-muted">You can rate this ride later.</p>
            </div>
          ) : null}

          <p className="text-center text-xs text-muted">History is stored locally in this demo.</p>
        </div>
      )}
    </div>
  );
}
