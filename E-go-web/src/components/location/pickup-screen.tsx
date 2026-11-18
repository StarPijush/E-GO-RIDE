'use client';

import { useEffect, useRef, useState } from 'react';
import { useRouter } from 'next/navigation';
import { LocateFixed } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import { PlaceSearch } from '@/components/location/place-search';
import { RideMap } from '@/components/map/ride-map';
import { BookingStageGuard } from '@/components/shared/booking-stage-guard';
import { Badge, Button, Card, useToast } from '@/components/ui';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { ROUTES } from '@/lib/config/routes';
import { distanceKm } from '@/lib/domain/geo';
import { errorMessage } from '@/lib/domain/labels';
import type { LatLng, Place } from '@/lib/domain/types';
import { getRepositories } from '@/lib/repositories';
import { CURRENT_LOCATION_PLACE } from '@/lib/utils/current-location';
import { useBookingStore } from '@/stores/booking-store';

export function PickupScreen() {
  const router = useRouter();
  const { show } = useToast();

  const status = useBookingStore((state) => state.status);
  const draft = useBookingStore((state) => state.draft);
  const startBooking = useBookingStore((state) => state.startBooking);
  const choosePickup = useBookingStore((state) => state.choosePickup);

  const [candidate, setCandidate] = useState<Place | null>(null);
  const started = useRef(false);

  // The screen starts the booking once (the guard sends the passenger here).
  useEffect(() => {
    if (started.current) return;
    started.current = true;

    if (status !== 'idle') return;
    startBooking('pickup');

    const error = useBookingStore.getState().lastError;
    if (error) {
      show({ message: errorMessage(error), tone: 'warning' });
    }
  }, [show, startBooking, status]);

  // The seeded places, used to snap a map tap to the nearest demo place.
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

  const confirmPickup = (place: Place) => {
    const accepted = choosePickup(place);
    if (!accepted) {
      const error = useBookingStore.getState().lastError;
      show({
        message: error ? errorMessage(error) : 'Please choose a pickup point first.',
        tone: 'warning',
      });
      return;
    }
    router.push(ROUTES.destinationSelection);
  };

  return (
    <BookingStageGuard route={ROUTES.pickupSelection}>
      <div className="mx-auto w-full max-w-[1200px] px-4 py-5 sm:px-6 lg:px-8">
        <PageHeader
          title="Set pickup point"
          description="Search, tap the map, or use your demo current location."
          backHref={ROUTES.home}
          className="mb-5"
        />

        <div className="grid gap-5 lg:grid-cols-2 lg:items-start">
          <RideMap
            pickup={candidate ?? draft.pickup ?? CURRENT_LOCATION_PLACE}
            interactive
            onMapClick={handleMapClick}
            heightClassName="h-[280px] lg:h-[420px]"
          >
            <Badge tone="neutral" className="absolute left-3 top-3">
              Tap the map to pick a nearby spot
            </Badge>
          </RideMap>

          <div className="flex flex-col gap-4">
            <Button variant="secondary" fullWidth onClick={() => confirmPickup(CURRENT_LOCATION_PLACE)}>
              <LocateFixed aria-hidden="true" className="size-5" />
              Use current location
            </Button>

            <PlaceSearch
              label="Search for a pickup point"
              onSelect={confirmPickup}
              autoFocus
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
                    <Button onClick={() => confirmPickup(candidate)}>Use this location</Button>
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
