'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { MessageCircle, Phone, Star, X } from 'lucide-react';

import { CancelRideDialog } from '@/components/booking/cancel-ride-dialog';
import { PageHeader } from '@/components/layout/page-header';
import { RideMap } from '@/components/map/ride-map';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Avatar, Badge, Button, Card, IconButton, Skeleton, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { formatINR } from '@/lib/domain/fare';
import { bookingStatusCopy } from '@/lib/domain/labels';
import type { CancellationReason } from '@/lib/domain/types';
import { formatStars } from '@/lib/utils/format';
import { useBookingStore } from '@/stores/booking-store';

/** The share of the phase that is over (0 - 1). */
function phaseProgress(
  status: string,
  phaseStartedAt: string | undefined,
  nextTransitionAt: string | undefined,
  now: string,
): number {
  if (status === 'driverArrived') return 1;
  if (!phaseStartedAt || !nextTransitionAt) return 0;

  const start = Date.parse(phaseStartedAt);
  const end = Date.parse(nextTransitionAt);
  const current = Date.parse(now);
  if (!Number.isFinite(start) || !Number.isFinite(end) || !Number.isFinite(current)) return 0;
  if (end <= start) return 0;

  return Math.min(Math.max((current - start) / (end - start), 0), 1);
}

export function RideTrackingScreen() {
  const router = useRouter();
  const { show } = useToast();

  const status = useBookingStore((state) => state.status);
  const activeRide = useBookingStore((state) => state.activeRide);
  const now = useBookingStore((state) => state.now);
  const pending = useBookingStore((state) => state.pending);
  const startTrip = useBookingStore((state) => state.startTrip);
  const cancelBooking = useBookingStore((state) => state.cancelBooking);
  const acknowledgeCancellation = useBookingStore((state) => state.acknowledgeCancellation);

  const [dialogOpen, setDialogOpen] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const ride = activeRide;
  const driver = ride?.driver;
  const copy = bookingStatusCopy[status];

  // The FSM allows a cancellation while the driver is on the way.
  const canCancel = status === 'driverArriving' || status === 'driverArrived';

  const progress = phaseProgress(
    status,
    ride?.phaseStartedAt,
    ride?.nextTransitionAt,
    now,
  );

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

  const handleStartTrip = async () => {
    setError(null);

    const result = await startTrip();
    if (!result.ok) {
      setError(result.error.message);
      show({ message: result.error.message, tone: 'danger' });
    }
  };

  return (
    <BookingStageGuard route={ROUTES.rideTracking}>
      <div className="mx-auto w-full max-w-[1200px] px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Ride tracking"
          description="Follow your demo ride to the pickup point."
          className="mb-5"
          action={
            canCancel ? (
              <IconButton label="Cancel ride" size="sm" onClick={() => setDialogOpen(true)}>
                <X aria-hidden="true" className="size-5" />
              </IconButton>
            ) : null
          }
        />

        {!ride ? (
          <Card padding="lg" className="flex flex-col gap-3">
            <Skeleton className="h-6 w-2/5" />
            <Skeleton className="h-40 w-full" />
            <Skeleton className="h-24 w-full" />
          </Card>
        ) : (
          <div className="grid gap-5 lg:grid-cols-[1.25fr_1fr] lg:items-start">
            <div className="lg:sticky lg:top-24">
              <RideMap
                pickup={ride.pickup}
                destination={ride.destination}
                driver={driver ?? null}
                heightClassName="h-[42vh] lg:h-[420px]"
              >
                <Badge tone="neutral" className="absolute left-3 top-3">
                  Simulated GPS - not live tracking
                </Badge>
              </RideMap>
            </div>

            <div className="flex flex-col gap-4">
              <Card padding="lg" className="flex flex-col gap-3">
                <div className="flex items-center justify-between gap-3" aria-live="polite">
                  <span className="text-sm font-medium text-navy">
                    {status === 'driverArriving'
                      ? 'Driver arriving'
                      : status === 'driverArrived'
                        ? 'Driver arrived'
                        : status === 'tripInProgress'
                          ? 'Trip in progress'
                          : copy.label}
                  </span>
                  <Badge tone={copy.tone}>{copy.label}</Badge>
                </div>

                <div
                  className="h-1.5 w-full overflow-hidden rounded-pill bg-navy-soft"
                  role="progressbar"
                  aria-valuemin={0}
                  aria-valuemax={100}
                  aria-valuenow={Math.round(progress * 100)}
                  aria-label="Ride progress"
                >
                  <div
                    className="h-full rounded-pill bg-brand transition-[width] duration-300"
                    style={{ width: `${Math.round(progress * 100)}%` }}
                  />
                </div>

                {status === 'driverArrived' ? (
                  <p className="rounded-field bg-success-soft px-3 py-2 text-sm font-medium text-success">
                    Driver has arrived at pickup.
                  </p>
                ) : null}

                {status === 'tripInProgress' ? (
                  <p className="rounded-field bg-info-soft px-3 py-2 text-sm font-medium text-info">
                    Trip in progress.
                  </p>
                ) : null}

                {status === 'driverArriving' ? (
                  <p className="text-xs text-muted">
                    About {ride.fare.estimatedArrivalMinutes} min (demo). You will be able to start
                    the trip when the driver arrives.
                  </p>
                ) : null}

                {status === 'driverArrived' ? (
                  <Button fullWidth loading={pending} disabled={pending} onClick={handleStartTrip}>
                    Start trip
                  </Button>
                ) : null}
              </Card>

              {driver ? (
                <Card padding="lg" className="flex flex-col gap-3">
                  <div className="flex items-center gap-3">
                    <Avatar name={driver.name} size="md" />

                    <div className="flex min-w-0 flex-1 flex-col">
                      <span className="truncate font-display text-base font-semibold text-navy">
                        {driver.name || 'Your driver'}
                      </span>
                      <span className="flex items-center gap-1 text-xs text-muted">
                        <Star aria-hidden="true" className="size-3.5" />
                        {formatStars(driver.rating)}
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

                  <p className="text-xs text-muted">
                    {driver.vehicleModel} · {driver.vehicleNumber}
                  </p>

                  <p className="rounded-field bg-warning-soft px-3 py-2 text-center text-xs font-medium text-warning">
                    Demo driver - not a real person.
                  </p>
                </Card>
              ) : null}

              <Card padding="lg" className="flex flex-col gap-1">
                <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                  Destination
                </span>
                <span className="text-sm font-semibold text-navy">{ride.destination.label}</span>
                <span className="text-xs text-muted">{ride.destination.address}</span>

                <div className="mt-2 flex items-center justify-between gap-3">
                  <span className="text-xs text-muted">Cash</span>
                  <span className="font-display text-lg font-bold text-navy">
                    {formatINR(ride.fare.total)}
                  </span>
                </div>

                <span className="mt-1 text-[11px] text-muted">Trip ID: {ride.id}</span>
              </Card>

              {error ? (
                <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
                  {error}
                </p>
              ) : null}
            </div>
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
