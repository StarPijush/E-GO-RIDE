'use client';

import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { useEffect, useState } from 'react';
import { Heart } from 'lucide-react';

import { RatingForm, type RatingFormValues } from '@/components/booking/rating-form';
import { PageHeader } from '@/components/layout/page-header';
import { RatingStars } from '@/components/shared/rating-stars';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Button, Card, EmptyState, ErrorState, Skeleton } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { getRepositories } from '@/lib/repositories';
import { useAuthStore } from '@/stores/auth-store';
import { useBookingStore } from '@/stores/booking-store';

const linkClass =
  'text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

/** The rating of the ride that is still on the screen. */
function LiveRating() {
  const router = useRouter();

  const activeRide = useBookingStore((state) => state.activeRide);
  const pending = useBookingStore((state) => state.pending);
  const submitRating = useBookingStore((state) => state.submitRating);
  const skipRating = useBookingStore((state) => state.skipRating);
  const resetBooking = useBookingStore((state) => state.resetBooking);

  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // The thank-you view goes home on its own (one timer, cleaned up).
  useEffect(() => {
    if (!submitted) return;

    const timer = setTimeout(() => {
      resetBooking();
      router.replace(ROUTES.home);
    }, 1500);

    return () => clearTimeout(timer);
  }, [submitted, resetBooking, router]);

  const driver = activeRide?.driver;
  const vehicle = activeRide?.vehicle;

  const handleSubmit = async (values: RatingFormValues) => {
    setError(null);

    const result = await submitRating({
      stars: values.stars,
      tags: values.tags,
      comment: values.comment,
    });
    if (!result.ok) {
      setError(result.error.message);
      return;
    }

    setSubmitted(true);
  };

  const handleSkip = () => {
    const skipped = skipRating();
    if (!skipped) {
      const failure = useBookingStore.getState().lastError;
      setError(failure?.message ?? 'The rating could not be skipped.');
    }
    router.replace(ROUTES.home);
  };

  if (submitted) {
    return (
      <BookingStageGuard route={ROUTES.rideRating}>
        <div className="mx-auto flex min-h-[70vh] w-full max-w-md flex-col items-center justify-center gap-3 px-4 text-center">
          <span className="flex size-16 items-center justify-center rounded-full bg-brand-soft text-navy">
            <Heart aria-hidden="true" className="size-8" />
          </span>

          <h1 className="font-display text-2xl font-bold text-navy">Thank you!</h1>
          <p className="text-sm text-muted">Your feedback helps us improve.</p>
          {driver ? <p className="text-sm font-medium text-navy">{driver.name}</p> : null}
        </div>
      </BookingStageGuard>
    );
  }

  return (
    <BookingStageGuard route={ROUTES.rideRating}>
      <div className="mx-auto w-full max-w-lg px-4 py-5 sm:px-6">
        <div className="mb-5 flex items-center justify-between gap-3">
          <h1 className="font-display text-2xl font-bold text-navy">Rate your ride</h1>

          <Button variant="ghost" size="sm" onClick={handleSkip}>
            Skip
          </Button>
        </div>

        <RatingForm
          driver={driver}
          vehicle={vehicle}
          pending={pending}
          error={error}
          onSubmit={handleSubmit}
        />
      </div>
    </BookingStageGuard>
  );
}

/** The rating of a ride of the history (a deep link). */
function HistoricalRating({ rideId }: { rideId: string }) {
  const router = useRouter();
  const user = useAuthStore((state) => state.user);

  const [submitted, setSubmitted] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const ride = useAsyncData(
    () => getRepositories().rides.getById(rideId),
    [rideId],
    { enabled: Boolean(rideId) },
  );

  // Only the owner of the ride may rate it.
  const details = ride.data && ride.data.userId === user?.id ? ride.data : null;

  useEffect(() => {
    if (!submitted) return;

    const timer = setTimeout(() => {
      router.replace(`${ROUTES.rideDetails}/${rideId}`);
    }, 1500);

    return () => clearTimeout(timer);
  }, [submitted, rideId, router]);

  const handleSubmit = async (values: RatingFormValues) => {
    setError(null);

    const result = await getRepositories().rides.rate(rideId, {
      rideId,
      stars: values.stars,
      tags: values.tags,
      comment: values.comment,
      createdAt: new Date().toISOString(),
    });
    if (!result.ok) {
      setError(result.error.message);
      return;
    }

    setSubmitted(true);
  };

  if (submitted) {
    return (
      <div className="mx-auto flex min-h-[70vh] w-full max-w-md flex-col items-center justify-center gap-3 px-4 text-center">
        <span className="flex size-16 items-center justify-center rounded-full bg-brand-soft text-navy">
          <Heart aria-hidden="true" className="size-8" />
        </span>

        <h1 className="font-display text-2xl font-bold text-navy">Thank you!</h1>
        <p className="text-sm text-muted">Your feedback helps us improve.</p>
        {details?.driver ? (
          <p className="text-sm font-medium text-navy">{details.driver.name}</p>
        ) : null}
      </div>
    );
  }

  if (ride.loading) {
    return (
      <div className="mx-auto flex w-full max-w-lg flex-col gap-4 px-4 py-5 sm:px-6">
        <Skeleton className="h-32 w-full rounded-card" />
        <Skeleton className="h-40 w-full rounded-card" />
        <Skeleton className="h-24 w-full rounded-card" />
      </div>
    );
  }

  if (ride.error) {
    return (
      <div className="mx-auto w-full max-w-lg px-4 py-5 sm:px-6">
        <ErrorState
          title="The ride could not be loaded"
          message="Please try again."
          onRetry={ride.reload}
        />
      </div>
    );
  }

  if (!details) {
    return (
      <div className="mx-auto w-full max-w-lg px-4 py-5 sm:px-6">
        <EmptyState
          title="Ride not found"
          description="This ride does not exist or was removed."
          action={
            <Link href={ROUTES.myRides} className={linkClass}>
              Back to my rides
            </Link>
          }
        />
      </div>
    );
  }

  if (details.status === 'rated') {
    return (
      <div className="mx-auto w-full max-w-lg px-4 py-5 sm:px-6">
        <PageHeader
          title="Ride details"
          backHref={`${ROUTES.rideDetails}/${details.id}`}
          className="mb-5"
        />

        <Card padding="lg" className="flex flex-col items-center gap-3 text-center">
          <p className="font-display text-base font-semibold text-navy">
            This ride is already rated.
          </p>

          {details.rating ? <RatingStars stars={details.rating.stars} /> : null}

          {details.rating?.comment ? (
            <p className="text-sm text-muted">{details.rating.comment}</p>
          ) : null}

          <Link href={`${ROUTES.rideDetails}/${details.id}`} className={linkClass}>
            Back to the ride
          </Link>
        </Card>
      </div>
    );
  }

  if (details.status !== 'awaitingRating') {
    return (
      <div className="mx-auto w-full max-w-lg px-4 py-5 sm:px-6">
        <PageHeader
          title="Rate your ride"
          backHref={`${ROUTES.rideDetails}/${details.id}`}
          className="mb-5"
        />

        <EmptyState
          title="This ride cannot be rated"
          description="Only a finished ride that waits for a rating can be rated."
          action={
            <Link href={`${ROUTES.rideDetails}/${details.id}`} className={linkClass}>
              Back to the ride
            </Link>
          }
        />
      </div>
    );
  }

  return (
    <div className="mx-auto w-full max-w-lg px-4 py-5 sm:px-6">
      <PageHeader
        title="Rate your ride"
        backHref={`${ROUTES.rideDetails}/${details.id}`}
        className="mb-5"
      />

      <RatingForm
        driver={details.driver}
        vehicle={details.vehicle}
        pending={false}
        error={error}
        onSubmit={handleSubmit}
      />

      <div className="mt-4 flex justify-center">
        <Link href={`${ROUTES.rideDetails}/${details.id}`} className={linkClass}>
          Back to ride
        </Link>
      </div>
    </div>
  );
}

/**
 * The rating screen.
 *
 * Without a `rideId` it rates the ride that is still on the screen; with a
 * `rideId` it rates a ride of the history (a deep link that survives a
 * refresh).
 */
export function RatingScreen() {
  const searchParams = useSearchParams();
  const rideId = searchParams.get('rideId');

  if (rideId) return <HistoricalRating rideId={rideId} />;
  return <LiveRating />;
}
