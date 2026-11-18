'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { Info } from 'lucide-react';

import { FareBreakdownRows } from '@/components/booking/fare-breakdown';
import { RouteCard } from '@/components/booking/route-card';
import { VehicleSummary } from '@/components/booking/vehicle-summary';
import { PageHeader } from '@/components/layout/page-header';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Button, Card, EmptyState, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { useBookingStore } from '@/stores/booking-store';

const textButtonClass =
  'text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function FareScreen() {
  const router = useRouter();
  const { show } = useToast();

  const draft = useBookingStore((state) => state.draft);
  const pending = useBookingStore((state) => state.pending);
  const beginConfirmation = useBookingStore((state) => state.beginConfirmation);
  const backToVehicle = useBookingStore((state) => state.backToVehicle);

  const vehicle = draft.vehicle;
  const fare = draft.fare;

  const handleBack = () => {
    backToVehicle();
    router.push(ROUTES.vehicleSelection);
  };

  const handleConfirm = () => {
    const begun = beginConfirmation();
    if (!begun) {
      const error = useBookingStore.getState().lastError;
      show({
        message: error?.message ?? 'The booking cannot be confirmed yet.',
        tone: 'warning',
      });
      return;
    }
    router.push(ROUTES.bookingConfirmation);
  };

  const handleMissingFare = () => {
    backToVehicle();
    router.push(ROUTES.vehicleSelection);
  };

  return (
    <BookingStageGuard route={ROUTES.fareDetails}>
      <div className="mx-auto w-full max-w-3xl px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Fare details"
          description="Check your demo estimate before confirming."
          backHref={ROUTES.home}
          className="mb-5"
          action={
            <button type="button" onClick={handleBack} className={textButtonClass}>
              Change vehicle
            </button>
          }
        />

        {vehicle && fare ? (
          <div className="flex flex-col gap-4">
            <RouteCard pickup={draft.pickup} destination={draft.destination} />

            <Card padding="lg" className="flex flex-col gap-4">
              <VehicleSummary vehicle={vehicle} fare={fare} />
              <FareBreakdownRows fare={fare} showPayment paymentLabel="Cash" />
            </Card>

            <div className="flex items-start gap-2 rounded-field bg-info-soft px-3 py-2 text-xs text-info">
              <Info aria-hidden="true" className="mt-0.5 size-4 shrink-0" />
              <span>This is a demo fare estimate. Actual fares may vary.</span>
            </div>

            <Card padding="lg">
              <div className="flex items-start justify-between gap-3">
                <span className="flex flex-col">
                  <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                    Payment method
                  </span>
                  <span className="text-sm font-semibold text-navy">Cash</span>
                  <span className="text-xs text-muted">
                    Pay the driver directly in this demo.
                  </span>
                </span>

                <Link href={ROUTES.paymentMethods} className={textButtonClass}>
                  Change
                </Link>
              </div>
            </Card>

            <Card padding="lg" className="sticky bottom-20 flex flex-col gap-3 lg:static">
              <Button fullWidth loading={pending} disabled={pending} onClick={handleConfirm}>
                Confirm vehicle
              </Button>
            </Card>
          </div>
        ) : (
          <EmptyState
            title="Fare not ready"
            description="Choose a vehicle to see the fare estimate."
            action={
              <button type="button" onClick={handleMissingFare} className={textButtonClass}>
                Back to vehicles
              </button>
            }
          />
        )}
      </div>
    </BookingStageGuard>
  );
}
