'use client';

import Link from 'next/link';
import { useState } from 'react';
import { History, Route } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { RideCard } from '@/components/rides/ride-card';
import {
  Card,
  EmptyState,
  ErrorState,
  IconButton,
  SegmentedTabs,
  Skeleton,
} from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { bookingStatusCopy } from '@/lib/domain/labels';
import type { RideFilter } from '@/lib/domain/types';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { getRepositories } from '@/lib/repositories';
import { STATUS_ROUTE } from '@/components/shared/booking-stage-guard';
import { useAuthStore } from '@/stores/auth-store';
import { useBookingStore } from '@/stores/booking-store';

/** The filters of the history (A10 - there is no shared ride). */
const TABS = [
  { value: 'all', label: 'All' },
  { value: 'completed', label: 'Completed' },
  { value: 'cancelled', label: 'Cancelled' },
] as const satisfies readonly { value: RideFilter; label: string }[];

export function MyRidesScreen() {
  const user = useAuthStore((state) => state.user);
  const activeRide = useBookingStore((state) => state.activeRide);
  const status = useBookingStore((state) => state.status);

  const userId = user?.id ?? '';
  const [filter, setFilter] = useState<RideFilter>('all');

  const rides = useAsyncData(
    () => getRepositories().rides.list(userId, filter),
    [userId, filter],
    { enabled: Boolean(user) },
  );

  const hasActiveRide =
    Boolean(activeRide) && status !== 'idle' && status !== 'rated' && status !== 'cancelled';

  const resumeHref = STATUS_ROUTE[status] ?? ROUTES.home;
  const resumeLabel = status === 'awaitingRating' ? 'Rate ride' : 'Resume ride';

  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader
        title="Your rides"
        description="Your completed and cancelled rides."
        className="mb-5"
        action={
          <IconButton
            label="Reset ride filters"
            size="sm"
            disabled={filter === 'all'}
            onClick={() => setFilter('all')}
          >
            <History aria-hidden="true" className="size-5" />
          </IconButton>
        }
      />

      {hasActiveRide && activeRide ? (
        <Card padding="lg" className="mb-4 border-brand bg-brand-soft/50">
          <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div className="flex flex-col gap-0.5">
              <span className="font-display text-base font-semibold text-navy">
                {bookingStatusCopy[status].label}
              </span>
              <span className="text-sm text-navy/80">
                {status === 'awaitingRating'
                  ? 'Rate your last ride.'
                  : 'A ride is still in progress.'}
              </span>
            </div>

            <Link
              href={resumeHref}
              className="inline-flex h-11 shrink-0 items-center justify-center rounded-pill bg-brand px-5 font-semibold text-navy transition-colors hover:bg-brand-strong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
            >
              {resumeLabel}
            </Link>
          </div>
        </Card>
      ) : null}

      <div className="mb-4">
        <SegmentedTabs
          ariaLabel="Filter rides"
          tabs={TABS}
          value={filter}
          onChange={(value) => setFilter(value as RideFilter)}
        />
      </div>

      {rides.loading ? (
        <div className="flex flex-col gap-3">
          <Skeleton className="h-36 w-full rounded-card" />
          <Skeleton className="h-36 w-full rounded-card" />
          <Skeleton className="h-36 w-full rounded-card" />
        </div>
      ) : rides.error ? (
        <ErrorState
          title="Your rides could not be loaded"
          message="Please try again."
          onRetry={rides.reload}
        />
      ) : rides.data && rides.data.length > 0 ? (
        <div className="grid gap-3 md:grid-cols-2">
          {rides.data.map((ride) => (
            <RideCard key={ride.id} ride={ride} />
          ))}
        </div>
      ) : (
        <EmptyState
          icon={<Route aria-hidden="true" className="size-7" />}
          title="No rides yet"
          description="Your completed and cancelled rides will appear here."
          action={
            <Link
              href={ROUTES.destinationSelection}
              className="inline-flex h-12 items-center justify-center rounded-pill bg-brand px-5 font-semibold text-navy transition-colors hover:bg-brand-strong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
            >
              Book a TOTO
            </Link>
          }
        />
      )}
    </div>
  );
}
