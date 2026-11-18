'use client';

import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { useMemo, useState } from 'react';

import { RouteCard } from '@/components/booking/route-card';
import { VehicleCard } from '@/components/booking/vehicle-card';
import { PageHeader } from '@/components/layout/page-header';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Button, Card, EmptyState, useToast } from '@/components/ui';
import { ROUTES } from '@/lib/config/routes';
import { distanceKm } from '@/lib/domain/geo';
import { calculateFare, formatINR, vehicleOptions } from '@/lib/domain/fare';
import type { VehicleType } from '@/lib/domain/types';
import { useBookingStore } from '@/stores/booking-store';

const textButtonClass =
  'text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2';

export function VehicleScreen() {
  const router = useRouter();
  const { show } = useToast();

  const draft = useBookingStore((state) => state.draft);
  const pending = useBookingStore((state) => state.pending);
  const chooseVehicle = useBookingStore((state) => state.chooseVehicle);
  const reviewFare = useBookingStore((state) => state.reviewFare);
  const backToDestination = useBookingStore((state) => state.backToDestination);

  const [selected, setSelected] = useState<VehicleType>(draft.vehicle ?? 'bike');

  const pickup = draft.pickup;
  const destination = draft.destination;
  const hasRoute = Boolean(pickup && destination);

  const vehicles = useMemo(() => {
    if (!pickup || !destination) return [];
    const route = distanceKm(pickup, destination);
    return vehicleOptions(pickup, destination).map((option) => ({
      option,
      tripMinutes: calculateFare(option.type, pickup, destination).estimatedMinutes,
      distanceKm: route,
    }));
  }, [pickup, destination]);

  const selectedVehicle = vehicles.find((entry) => entry.option.type === selected);

  const handleBack = () => {
    backToDestination();
    router.push(ROUTES.destinationSelection);
  };

  const handleContinue = () => {
    if (!selectedVehicle) return;

    const chosen = chooseVehicle(selectedVehicle.option.type);
    if (!chosen) {
      const error = useBookingStore.getState().lastError;
      show({
        message: error?.message ?? 'Please choose a vehicle first.',
        tone: 'warning',
      });
      return;
    }

    const reviewed = reviewFare();
    if (!reviewed) {
      const error = useBookingStore.getState().lastError;
      show({
        message: error?.message ?? 'The fare could not be reviewed.',
        tone: 'warning',
      });
      return;
    }

    router.push(ROUTES.fareDetails);
  };

  return (
    <BookingStageGuard route={ROUTES.vehicleSelection}>
      <div className="mx-auto w-full max-w-3xl px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Choose vehicle"
          description="Compare the demo fare and pick your ride."
          backHref={ROUTES.home}
          className="mb-5"
          action={
            <button type="button" onClick={handleBack} className={textButtonClass}>
              Change destination
            </button>
          }
        />

        {!hasRoute ? (
          <EmptyState
            title="Route missing"
            description="Choose a pickup point and a destination first."
            action={
              <Link href={ROUTES.pickupSelection} className={textButtonClass}>
                Set pickup point
              </Link>
            }
          />
        ) : (
          <div className="flex flex-col gap-4">
            <RouteCard pickup={pickup} destination={destination} />

            <div role="radiogroup" aria-label="Choose a vehicle" className="flex flex-col gap-3">
              {vehicles.map((entry) => (
                <VehicleCard
                  key={entry.option.type}
                  option={entry.option}
                  selected={entry.option.type === selected}
                  onSelect={(option) => setSelected(option.type)}
                  tripMinutes={entry.tripMinutes}
                  distanceKm={entry.distanceKm}
                  disabled={pending}
                />
              ))}
            </div>

            <Card padding="lg" className="sticky bottom-20 flex flex-col gap-3 lg:static">
              <div className="flex items-center justify-between gap-3">
                <span className="text-sm text-muted">Estimated fare</span>
                <span className="font-display text-xl font-bold text-navy">
                  {formatINR(selectedVehicle?.option.fare ?? 0)}
                </span>
              </div>

              <Button fullWidth loading={pending} disabled={pending} onClick={handleContinue}>
                Continue
              </Button>

              <p className="text-center text-xs text-muted">
                Fares are demo estimates. Actual fares may vary.
              </p>
            </Card>
          </div>
        )}
      </div>
    </BookingStageGuard>
  );
}
