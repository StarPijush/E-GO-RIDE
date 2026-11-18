'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { CheckCircle2, MessageCircle, Phone, Star, X } from 'lucide-react';

import { CancelRideDialog } from '@/components/booking/cancel-ride-dialog';
import { RouteCard } from '@/components/booking/route-card';
import { PageHeader } from '@/components/layout/page-header';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Avatar, Button, Card, IconButton, Skeleton, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { vehicleCopy } from '@/lib/domain/labels';
import type { CancellationReason } from '@/lib/domain/types';
import { formatStars } from '@/lib/utils/format';
import { useBookingStore } from '@/stores/booking-store';

export function DriverAssignedScreen() {
  const router = useRouter();
  const { show } = useToast();

  const activeRide = useBookingStore((state) => state.activeRide);
  const pending = useBookingStore((state) => state.pending);
  const cancelBooking = useBookingStore((state) => state.cancelBooking);
  const acknowledgeCancellation = useBookingStore((state) => state.acknowledgeCancellation);
  const trackDriver = useBookingStore((state) => state.trackDriver);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const driver = activeRide?.driver;

  const handleCancel = async (reason: CancellationReason) => {
    setError(null);

    const result = await cancelBooking(reason);
    if (!result.ok) {
      setError(result.error.message);
      return;
    }

    setDialogOpen(false);
    acknowledgeCancellation();
    router.replace(ROUTES.home);
  };

  const handleTrack = async () => {
    setError(null);

    const result = await trackDriver();
    if (!result.ok) {
      setError(result.error.message);
      show({ message: result.error.message, tone: 'danger' });
      return;
    }

    router.push(ROUTES.rideTracking);
  };

  return (
    <BookingStageGuard route={ROUTES.driverAssigned}>
      <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Driver assigned"
          description="Your driver is on the way to the pickup point."
          className="mb-5"
          action={
            <IconButton label="Cancel ride" size="sm" onClick={() => setDialogOpen(true)}>
              <X aria-hidden="true" className="size-5" />
            </IconButton>
          }
        />

        {!activeRide || !driver ? (
          <Card padding="lg" className="flex flex-col gap-3">
            <Skeleton className="h-6 w-2/5" />
            <Skeleton className="h-16 w-full" />
            <Skeleton className="h-24 w-full" />
          </Card>
        ) : (
          <div className="flex flex-col gap-4">
            <Card padding="lg" className="flex items-start gap-3 border-brand bg-brand-soft/50">
              <CheckCircle2 aria-hidden="true" className="mt-0.5 size-8 shrink-0 text-navy" />

              <div className="flex flex-col gap-0.5">
                <p className="font-display text-lg font-bold text-navy">
                  Your driver is on the way!
                </p>
                <p className="text-sm text-navy">
                  Arriving in {activeRide.fare.estimatedArrivalMinutes} min (demo)
                </p>
              </div>
            </Card>

            <Card padding="lg" className="flex flex-col gap-4">
              <div className="flex items-center gap-3">
                <Avatar name={driver.name} size="lg" />

                <div className="flex min-w-0 flex-1 flex-col">
                  <span className="truncate font-display text-base font-semibold text-navy">
                    {driver.name}
                  </span>
                  <span className="flex items-center gap-1 text-xs text-muted">
                    <Star aria-hidden="true" className="size-3.5" />
                    {formatStars(driver.rating)} · {driver.ridesCompleted} rides
                  </span>
                </div>

                <div className="flex gap-2">
                  <IconButton
                    label={`Call ${driver.name}`}
                    variant="secondary"
                    size="sm"
                    onClick={() =>
                      show({
                        message: `Calling ${driver.name}... (demo simulation).`,
                        tone: 'neutral',
                      })
                    }
                  >
                    <Phone aria-hidden="true" className="size-4" />
                  </IconButton>

                  <IconButton
                    label={`Message ${driver.name}`}
                    variant="secondary"
                    size="sm"
                    onClick={() =>
                      show({
                        message: `Chat with ${driver.name} is simulated in this demo.`,
                        tone: 'neutral',
                      })
                    }
                  >
                    <MessageCircle aria-hidden="true" className="size-4" />
                  </IconButton>
                </div>
              </div>

              <div aria-hidden="true" className="h-px bg-line" />

              <div className="grid grid-cols-3 gap-3 text-center">
                <div className="flex flex-col gap-0.5">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                    Vehicle
                  </span>
                  <span className="truncate text-sm font-medium text-navy">
                    {driver.vehicleModel}
                  </span>
                </div>
                <div className="flex flex-col gap-0.5">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                    Plate
                  </span>
                  <span className="truncate text-sm font-medium text-navy">
                    {driver.vehicleNumber}
                  </span>
                </div>
                <div className="flex flex-col gap-0.5">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                    Type
                  </span>
                  <span className="truncate text-sm font-medium text-navy">
                    {vehicleCopy[driver.vehicleType].name}
                  </span>
                </div>
              </div>

              <p className="rounded-field bg-warning-soft px-3 py-2 text-center text-xs font-medium text-warning">
                Demo driver - not a real person.
              </p>
            </Card>

            <RouteCard pickup={activeRide.pickup} destination={activeRide.destination} />

            {error ? (
              <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
                {error}
              </p>
            ) : null}

            <Button fullWidth loading={pending} disabled={pending} onClick={handleTrack}>
              Track driver
            </Button>
          </div>
        )}
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
