'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';

import { PageHeader } from '@/components/layout/page-header';
import { PlaceSearch } from '@/components/location/place-search';
import { RideMap } from '@/components/map/ride-map';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Badge, Button, Card, useToast } from '@/components/ui';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { ROUTES } from '@/lib/config/routes';
import { distanceKm } from '@/lib/domain/geo';
import { errorMessage } from '@/lib/domain/labels';
import type { LatLng, Place, SavedPlace } from '@/lib/domain/types';
import { getRepositories } from '@/lib/repositories';
import { useAuthStore } from '@/stores/auth-store';
import { useBookingStore } from '@/stores/booking-store';

export function DestinationScreen() {
  const router = useRouter();
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const draft = useBookingStore((state) => state.draft);
  const startBooking = useBookingStore((state) => state.startBooking);
  const chooseDestination = useBookingStore((state) => state.chooseDestination);
  const resetBooking = useBookingStore((state) => state.resetBooking);

  const [candidate, setCandidate] = useState<Place | null>(null);

  const userId = user?.id ?? '';
  const savedPlaces = useAsyncData(
    () => getRepositories().places.listSaved(userId),
    [userId],
    { enabled: Boolean(user) },
  );

  const places = useAsyncData(() => getRepositories().places.search(''), []);

  const handleMapClick = (point: LatLng) => {
    const list = places.data ?? [];
    if (list.length === 0) {
      show({ message: 'No demo place is near that point.', tone: 'warning' });
      return;
    }

    let nearest = list[0];
    let nearestDistance = distanceKm(point, nearest);

    for (const place of list.slice(1)) {
      const distance = distanceKm(point, place);
      if (distance < nearestDistance) {
        nearest = place;
        nearestDistance = distance;
      }
    }

    setCandidate(nearest);
  };

  const confirmDestination = (place: Place) => {
    const accepted = chooseDestination(place);
    if (!accepted) {
      const error = useBookingStore.getState().lastError;
      if (error) {
        show({ message: errorMessage(error), tone: 'warning' });
      }
      router.push(ROUTES.pickupSelection);
      return;
    }
    router.push(ROUTES.vehicleSelection);
  };

  const handleChangePickup = () => {
    resetBooking();
    startBooking('pickup');
    router.push(ROUTES.pickupSelection);
  };

  return (
    <BookingStageGuard route={ROUTES.destinationSelection}>
      <div className="mx-auto w-full max-w-[1200px] px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Where are you going?"
          description="Search a destination in Jhargram."
          backHref={ROUTES.home}
          className="mb-5"
          action={
            <button
              type="button"
              onClick={handleChangePickup}
              className="text-sm font-semibold text-navy underline underline-offset-2 transition-colors hover:text-navy/80 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
            >
              Change pickup
            </button>
          }
        />

        {draft.pickup ? (
          <Card padding="md" className="mb-5">
            <div className="flex flex-col gap-0.5">
              <span className="text-xs font-semibold uppercase tracking-wider text-muted">
                Pickup
              </span>
              <span className="text-sm font-medium text-navy">{draft.pickup.label}</span>
              <span className="text-xs text-muted">{draft.pickup.address}</span>
            </div>
          </Card>
        ) : null}

        <div className="grid gap-5 lg:grid-cols-2 lg:items-start">
          <RideMap
            pickup={draft.pickup}
            destination={candidate ?? draft.destination}
            interactive
            onMapClick={handleMapClick}
            heightClassName="h-[280px] lg:h-[420px]"
          >
            <Badge tone="neutral" className="absolute left-3 top-3">
              Demo map - simulated
            </Badge>
          </RideMap>

          <div className="flex flex-col gap-4">
            <PlaceSearch
              label="Search for a destination"
              onSelect={confirmDestination}
              savedPlaces={savedPlaces.data ?? undefined}
              onSelectSaved={(place: SavedPlace) => confirmDestination(place)}
            />

            {candidate ? (
              <Card padding="lg">
                <div className="flex flex-col gap-3">
                  <p className="text-xs font-semibold uppercase tracking-wider text-muted">
                    Nearest demo place
                  </p>
                  <p className="text-sm font-semibold text-navy">{candidate.label}</p>
                  <p className="text-xs text-muted">{candidate.address}</p>

                  <div className="flex flex-wrap gap-2">
                    <Button onClick={() => confirmDestination(candidate)}>Use this location</Button>
                    <Button variant="ghost" onClick={() => setCandidate(null)}>
                      Cancel
                    </Button>
                  </div>
                </div>
              </Card>
            ) : null}
          </div>
        </div>
      </div>
    </BookingStageGuard>
  );
}
