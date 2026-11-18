'use client';

import { useRouter } from 'next/navigation';
import { useState } from 'react';
import { TriangleAlert } from 'lucide-react';

import { FareBreakdownRows } from '@/components/booking/fare-breakdown';
import { RouteCard } from '@/components/booking/route-card';
import { VehicleSummary } from '@/components/booking/vehicle-summary';
import { PageHeader } from '@/components/layout/page-header';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Button, Card, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { useBookingStore } from '@/stores/booking-store';

const textButtonClass =
  'text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function ConfirmationScreen() {
  const router = useRouter();
  const { show } = useToast();

  const draft = useBookingStore((state) => state.draft);
  const pending = useBookingStore((state) => state.pending);
  const beginConfirmation = useBookingStore((state) => state.beginConfirmation);
  const backToFare = useBookingStore((state) => state.backToFare);
  const confirmBooking = useBookingStore((state) => state.confirmBooking);

  const [error, setError] = useState<string | null>(null);

  const vehicle = draft.vehicle;
  const fare = draft.fare;

  const handleBack = () => {
    backToFare();
    router.push(ROUTES.fareDetails);
  };

  const handleConfirm = async () => {
    setError(null);

    // A deep link may land here before the booking was confirmed.
    if (useBookingStore.getState().status === 'reviewingFare') {
      const begun = beginConfirmation();
      if (!begun) {
        const failure = useBookingStore.getState().lastError;
        setError(failure?.message ?? 'The booking cannot be confirmed yet.');
        return;
      }
    }

    const result = await confirmBooking();
    if (!result.ok) {
      // The ride was not created - stay on the page and explain why.
      setError(result.error.message);
      return;
    }

    show({ message: 'Booking confirmed. Looking for a driver.', tone: 'success' });
    router.push(ROUTES.searchingDriver);
  };

  return (
    <BookingStageGuard route={ROUTES.bookingConfirmation}>
      <div className="mx-auto w-full max-w-3xl px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Confirm booking"
          description="One last look before we search for a driver."
          backHref={ROUTES.home}
          className="mb-5"
          action={
            <button type="button" onClick={handleBack} className={textButtonClass}>
              Back to fare
            </button>
          }
        />

        <div className="flex flex-col gap-4">
          <RouteCard pickup={draft.pickup} destination={draft.destination} />

          {vehicle && fare ? (
            <Card padding="lg" className="flex flex-col gap-4">
              <VehicleSummary vehicle={vehicle} fare={fare} />
              <FareBreakdownRows fare={fare} showPayment paymentLabel="Cash" />
            </Card>
          ) : null}

          <div className="flex items-start gap-2 rounded-field bg-warning-soft px-3 py-2 text-xs font-medium text-warning">
            <TriangleAlert aria-hidden="true" className="mt-0.5 size-4 shrink-0" />
            <span>Demo mode: No real driver will be dispatched.</span>
          </div>

          <p className="text-xs text-muted">
            You can cancel free of charge while searching or before the trip starts.
          </p>

          {error ? (
            <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
              {error}
            </p>
          ) : null}

          <Card padding="lg" className="sticky bottom-20 flex flex-col gap-3 lg:static">
            <Button fullWidth loading={pending} disabled={pending} onClick={handleConfirm}>
              Confirm booking
            </Button>

            <button type="button" onClick={handleBack} className={textButtonClass}>
              Keep editing
            </button>
          </Card>
        </div>
      </div>
    </BookingStageGuard>
  );
}
