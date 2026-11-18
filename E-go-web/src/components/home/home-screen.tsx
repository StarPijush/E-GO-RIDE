'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Briefcase, ChevronRight, Home, MapPin } from 'lucide-react';

import { RideMap } from '@/components/map/ride-map';
import { STATUS_ROUTE } from '@/components/shared/booking-stage-guard';
import { Badge, Button, Card, Skeleton, useToast } from '@/components/ui';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { ROUTES } from '@/lib/config/routes';
import { formatINR } from '@/lib/domain/fare';
import { bookingStatusLabels } from '@/lib/domain/labels';
import type { BookingStatus } from '@/lib/domain/types';
import { getRepositories } from '@/lib/repositories';
import { CURRENT_LOCATION_PLACE } from '@/lib/utils/current-location';
import { cn } from '@/lib/utils/cn';
import { useAuthStore } from '@/stores/auth-store';
import { useBookingStore } from '@/stores/booking-store';

/** The statuses in which a ride is still (or again) the centre of the screen. */
const ACTIVE_RIDE_STATUSES: readonly BookingStatus[] = [
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
  'tripInProgress',
  'tripCompleted',
  'awaitingRating',
  'failed',
];

/** The statuses in which the ride can still be resumed. */
const RESUME_STATUSES: readonly BookingStatus[] = [
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
  'tripInProgress',
];

const linkButtonClass =
  'inline-flex min-h-12 w-full items-center justify-center rounded-pill bg-brand px-5 font-semibold text-navy transition-colors hover:bg-brand-strong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

const textLinkClass =
  'text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function HomeScreen() {
  const router = useRouter();
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const status = useBookingStore((state) => state.status);
  const draft = useBookingStore((state) => state.draft);
  const activeRide = useBookingStore((state) => state.activeRide);
  const startBooking = useBookingStore((state) => state.startBooking);
  const choosePickup = useBookingStore((state) => state.choosePickup);
  const resetBooking = useBookingStore((state) => state.resetBooking);

  const userId = user?.id ?? '';
  const firstName = user?.fullName?.trim().split(/\s+/)[0] || 'there';

  const savedPlaces = useAsyncData(
    () => getRepositories().places.listSaved(userId),
    [userId],
    { enabled: Boolean(user) },
  );

  const hasActiveRide = Boolean(activeRide) && ACTIVE_RIDE_STATUSES.includes(status);
  const rideHref = STATUS_ROUTE[status] ?? ROUTES.searchingDriver;
  const rideActionLabel =
    status === 'failed'
      ? 'Retry search'
      : RESUME_STATUSES.includes(status)
        ? 'Resume ride'
        : 'View ride';

  const handlePickup = () => {
    if (status !== 'idle') resetBooking();
    startBooking('pickup');
    router.push(ROUTES.pickupSelection);
  };

  const handleDestination = () => {
    if (!draft.pickup) {
      const accepted = choosePickup(CURRENT_LOCATION_PLACE);
      if (!accepted) {
        show({ message: 'Please choose a pickup point first.', tone: 'warning' });
        router.push(ROUTES.pickupSelection);
        return;
      }
    }
    router.push(ROUTES.destinationSelection);
  };

  const rowClass =
    'flex min-h-14 w-full items-center gap-3 rounded-field px-2 text-left transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

  return (
    <div className="mx-auto w-full max-w-[1200px] px-4 py-5 sm:px-6 lg:px-8 lg:py-8">
      <div className="flex flex-col gap-4">
        <header className="flex flex-col gap-1">
          <h1 className="font-display text-2xl font-bold text-navy lg:text-3xl">
            Where to, {firstName}?
          </h1>
          <p className="text-sm text-muted">
            Book a Toto or bike ride across Jhargram in a few taps.
          </p>
        </header>

        {hasActiveRide && activeRide ? (
          <Card padding="lg" className="border-brand bg-brand-soft/50" aria-live="polite">
            <div className="flex flex-col gap-3">
              <div className="flex items-center justify-between gap-3">
                <Badge tone={status === 'failed' ? 'danger' : 'info'}>
                  {bookingStatusLabels[status] ?? 'Ride in progress'}
                </Badge>
                <span className="text-sm font-semibold text-navy">
                  {formatINR(activeRide.fare.total)}
                </span>
              </div>

              <p className="text-sm text-navy">
                {activeRide.pickup.label} → {activeRide.destination.label}
              </p>

              <Link href={rideHref} className={linkButtonClass}>
                {rideActionLabel}
              </Link>
            </div>
          </Card>
        ) : null}

        <div className="grid gap-6 lg:grid-cols-[1.4fr_1fr] lg:items-start">
          <div className="lg:sticky lg:top-24">
            <RideMap
              pickup={draft.pickup ?? CURRENT_LOCATION_PLACE}
              destination={draft.destination}
              heightClassName="h-[220px] lg:h-[300px]"
            >
              <Badge tone="neutral" className="absolute left-3 top-3">
                Demo map - simulated
              </Badge>
            </RideMap>
          </div>

          <div className="flex flex-col gap-4">
            <Card padding="lg">
              {hasActiveRide ? (
                <Link href={rideHref} className={linkButtonClass}>
                  View current ride
                </Link>
              ) : (
                <div className="flex flex-col gap-2">
                  <button type="button" onClick={handlePickup} className={rowClass}>
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-brand">
                      <MapPin aria-hidden="true" className="size-4 text-navy" />
                    </span>

                    <span className="flex min-w-0 flex-1 flex-col">
                      <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                        Pickup
                      </span>
                      <span className="truncate text-sm font-medium text-navy">
                        {draft.pickup?.label ?? 'Current location'}
                      </span>
                      <span className="truncate text-xs text-muted">
                        {draft.pickup?.address ?? 'Using your demo pickup point'}
                      </span>
                    </span>

                    <ChevronRight aria-hidden="true" className="size-5 shrink-0 text-muted" />
                  </button>

                  <div
                    aria-hidden="true"
                    className="ml-[26px] h-4 border-l-2 border-dotted border-line"
                  />

                  <button type="button" onClick={handleDestination} className={rowClass}>
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-navy">
                      <MapPin aria-hidden="true" className="size-4 text-white" />
                    </span>

                    <span className="flex min-w-0 flex-1 flex-col">
                      <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                        Destination
                      </span>
                      <span className="truncate text-sm font-medium text-navy">
                        {draft.destination?.label ?? 'Where are you going?'}
                      </span>
                    </span>

                    <ChevronRight aria-hidden="true" className="size-5 shrink-0 text-muted" />
                  </button>

                  <div className="mt-2 flex flex-col gap-3">
                    <Button fullWidth onClick={handleDestination}>
                      Choose destination
                    </Button>

                    <Link href={ROUTES.savedPlaces} className={cn(textLinkClass, 'self-center')}>
                      Saved places
                    </Link>

                    <p className="text-center text-xs text-muted">
                      Drivers, routes and fares are simulated in this demo.
                    </p>
                  </div>
                </div>
              )}
            </Card>

            {savedPlaces.error ? null : (
              <Card padding="lg">
                <div className="flex flex-col gap-3">
                  <h2 className="font-display text-sm font-semibold text-navy">Saved places</h2>

                  {savedPlaces.loading ? (
                    <div className="flex flex-wrap gap-2">
                      <Skeleton className="h-9 w-28 rounded-pill" />
                      <Skeleton className="h-9 w-24 rounded-pill" />
                    </div>
                  ) : savedPlaces.data && savedPlaces.data.length > 0 ? (
                    <div className="flex flex-wrap gap-2">
                      {savedPlaces.data.slice(0, 3).map((place) => (
                        <Link
                          key={place.savedId}
                          href={ROUTES.savedPlaces}
                          className={cn(
                            'inline-flex min-h-9 items-center gap-2 rounded-pill border border-line bg-white px-3 text-sm font-medium text-navy',
                            'transition-colors hover:bg-navy-soft',
                            'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
                          )}
                        >
                          {place.tag === 'home' ? (
                            <Home aria-hidden="true" className="size-4" />
                          ) : place.tag === 'work' ? (
                            <Briefcase aria-hidden="true" className="size-4" />
                          ) : (
                            <MapPin aria-hidden="true" className="size-4" />
                          )}
                          {place.label}
                        </Link>
                      ))}
                    </div>
                  ) : (
                    <Link href={ROUTES.savedPlaces} className={textLinkClass}>
                      Save Home and Work for faster booking
                    </Link>
                  )}
                </div>
              </Card>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
