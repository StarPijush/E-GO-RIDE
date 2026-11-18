'use client';

import { useRouter } from 'next/navigation';
import { CheckCircle2 } from 'lucide-react';

import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Button, Card, Skeleton, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { formatINR } from '@/lib/domain/fare';
import { bookingStatusCopy, vehicleCopy } from '@/lib/domain/labels';
import { formatDateTime } from '@/lib/utils/format';
import { useBookingStore } from '@/stores/booking-store';

/** One row of the receipt. */
function ReceiptRow({ label, value }: { label: string; value?: string | null }) {
  return (
    <div className="flex items-start justify-between gap-3">
      <dt className="text-xs font-semibold uppercase tracking-wider text-muted">{label}</dt>
      <dd className="truncate text-sm font-medium text-navy">{value || '—'}</dd>
    </div>
  );
}

export function TripCompletedScreen() {
  const router = useRouter();
  const { show } = useToast();

  const status = useBookingStore((state) => state.status);
  const activeRide = useBookingStore((state) => state.activeRide);
  const proceedToRating = useBookingStore((state) => state.proceedToRating);
  const skipRating = useBookingStore((state) => state.skipRating);

  const ride = activeRide;

  const handleRate = () => {
    // The store may still be on the finished trip (a deep link).
    if (useBookingStore.getState().status === 'tripCompleted') {
      proceedToRating();
    }
    router.push(ROUTES.rideRating);
  };

  const handleDone = () => {
    if (useBookingStore.getState().status === 'tripCompleted') {
      proceedToRating();
    }

    const skipped = skipRating();
    if (!skipped) {
      const error = useBookingStore.getState().lastError;
      show({
        message: error?.message ?? 'The rating could not be skipped.',
        tone: 'warning',
      });
    }

    router.replace(ROUTES.home);
  };

  return (
    <BookingStageGuard route={ROUTES.tripCompleted}>
      <div className="mx-auto flex w-full max-w-lg flex-col justify-center px-4 py-8 sm:px-6">
        {!ride ? (
          <Card padding="lg" className="flex flex-col gap-3">
            <Skeleton className="h-16 w-16 rounded-full" />
            <Skeleton className="h-8 w-2/3" />
            <Skeleton className="h-28 w-full" />
          </Card>
        ) : (
          <div className="flex flex-col gap-4">
            <div className="flex flex-col items-center gap-2 text-center">
              <span className="flex size-16 items-center justify-center rounded-full bg-success-soft text-success">
                <CheckCircle2 aria-hidden="true" className="size-9" />
              </span>

              <h1 className="font-display text-2xl font-bold text-navy">You&apos;ve arrived!</h1>
              <p className="text-sm text-muted">Your trip is complete.</p>
            </div>

            <Card padding="lg" className="flex flex-col items-center gap-1 border-brand bg-brand-soft/60 text-center">
              <span className="text-xs font-semibold uppercase tracking-wider text-navy/70">
                Total fare
              </span>
              <span className="font-display text-4xl font-bold text-navy">
                {formatINR(ride.fare.total)}
              </span>
              <span className="text-sm font-medium text-navy">Cash payment</span>
              <span className="text-xs text-navy/70">Simulated - no money is charged.</span>
            </Card>

            <Card padding="lg">
              <dl className="flex flex-col gap-3">
                <ReceiptRow label="Vehicle" value={vehicleCopy[ride.vehicle].name} />
                <ReceiptRow label="From" value={ride.pickup.label} />
                <ReceiptRow label="To" value={ride.destination.label} />
                <ReceiptRow label="Driver" value={ride.driver?.name ?? 'Your driver'} />
                <ReceiptRow label="Trip ID" value={ride.id} />
                <ReceiptRow label="Date" value={formatDateTime(ride.createdAt)} />
                <ReceiptRow label="Status" value={bookingStatusCopy[status].label} />
              </dl>
            </Card>

            <div className="flex flex-col gap-3">
              <Button fullWidth onClick={handleRate}>
                Rate your ride
              </Button>

              <Button variant="secondary" fullWidth onClick={handleDone}>
                Done
              </Button>
            </div>

            <p className="text-center text-xs text-muted">
              This receipt is simulated. No real payment was taken.
            </p>
          </div>
        )}
      </div>
    </BookingStageGuard>
  );
}
