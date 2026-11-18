'use client';

import Image from 'next/image';
import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { Bike } from 'lucide-react';

import { CancelRideDialog } from '@/components/booking/cancel-ride-dialog';
import { RouteCard } from '@/components/booking/route-card';
import { VehicleSummary } from '@/components/booking/vehicle-summary';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Button, Card, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { bookingStatusCopy, vehicleCopy } from '@/lib/domain/labels';
import type { CancellationReason } from '@/lib/domain/types';
import { useBookingStore } from '@/stores/booking-store';

export function SearchingScreen() {
  const router = useRouter();
  const { show } = useToast();

  const status = useBookingStore((state) => state.status);
  const activeRide = useBookingStore((state) => state.activeRide);
  const pending = useBookingStore((state) => state.pending);
  const cancelBooking = useBookingStore((state) => state.cancelBooking);
  const acknowledgeCancellation = useBookingStore((state) => state.acknowledgeCancellation);
  const retrySearch = useBookingStore((state) => state.retrySearch);
  const resetBooking = useBookingStore((state) => state.resetBooking);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const failed = status === 'failed';
  const copy = bookingStatusCopy[status];
  const vehicle = activeRide?.vehicle;
  const fare = activeRide?.fare;

  const handleCancel = async (reason: CancellationReason) => {
    setError(null);

    const result = await cancelBooking(reason);
    if (!result.ok) {
      // The dialog stays open, so the passenger can try again.
      setError(result.error.message);
      return;
    }

    setDialogOpen(false);
    acknowledgeCancellation();
    router.replace(ROUTES.home);
  };

  const handleRetry = async () => {
    setError(null);

    const result = await retrySearch();
    if (!result.ok) {
      show({ message: result.error.message, tone: 'danger' });
    }
  };

  const handleHome = () => {
    resetBooking();
    router.replace(ROUTES.home);
  };

  return (
    <BookingStageGuard route={ROUTES.searchingDriver}>
      <div className="mx-auto flex min-h-[70vh] w-full max-w-lg flex-col justify-center px-4 py-8 sm:px-6">
        <Card padding="lg" className="flex flex-col items-center gap-5 text-center">
          <div className="relative flex size-32 items-center justify-center">
            <span
              aria-hidden="true"
              className="absolute inset-0 animate-ping rounded-full bg-brand/30"
            />
            <span className="relative flex size-24 items-center justify-center rounded-full bg-brand">
              {vehicle === 'bike' ? (
                <Bike aria-hidden="true" className="size-10 text-navy" />
              ) : (
                <Image
                  src="/branding/ego_logo_icon.png"
                  alt=""
                  width={40}
                  height={40}
                  className="size-10 object-contain"
                />
              )}
            </span>
          </div>

          <div className="flex flex-col gap-1.5">
            <h1 className="font-display text-2xl font-bold text-navy">
              {failed ? 'No drivers found' : copy.label}
            </h1>
            <p className="text-sm text-muted">
              {failed
                ? 'No drivers are available right now. Please try again.'
                : `Searching nearby ${vehicleCopy[vehicle ?? 'bike'].name} drivers... (simulated)`}
            </p>
          </div>

          <div className="w-full">
            <RouteCard pickup={activeRide?.pickup} destination={activeRide?.destination} compact />
          </div>

          {vehicle && fare ? (
            <div className="w-full">
              <Card padding="md">
                <VehicleSummary vehicle={vehicle} fare={fare} compact />
              </Card>
            </div>
          ) : null}

          <p className="text-xs text-muted">Simulated search - no real driver is dispatched.</p>

          {error ? (
            <p role="alert" className="w-full rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
              {error}
            </p>
          ) : null}

          {failed ? (
            <div className="flex w-full flex-col gap-3">
              <Button fullWidth loading={pending} disabled={pending} onClick={handleRetry}>
                Try again
              </Button>
              <Button variant="secondary" fullWidth onClick={handleHome}>
                Back to home
              </Button>
            </div>
          ) : (
            <Button
              variant="secondary"
              fullWidth
              onClick={() => setDialogOpen(true)}
              disabled={pending}
            >
              Cancel search
            </Button>
          )}
        </Card>
      </div>

      <CancelRideDialog
        open={dialogOpen}
        onClose={() => setDialogOpen(false)}
        onConfirm={handleCancel}
        pending={pending}
      />
    </BookingStageGuard>
  );
}
