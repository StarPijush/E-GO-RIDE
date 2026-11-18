'use client';

/**
 * The guard of the booking flow.
 *
 * Every step of the booking has prerequisites: a vehicle needs a pickup and
 * a destination, the rating needs a ride. The guard sends the passenger to
 * the step they really are on, so a deep link (or a refresh) never leads to
 * an empty screen.
 *
 * The decision itself is a pure function ({@link resolveBookingRedirect}),
 * so it can be tested without a browser.
 */

import { usePathname, useRouter } from 'next/navigation';
import { useEffect, useRef, type ReactNode } from 'react';

import { AppSkeleton } from '@/components/shared/app-skeleton';
import { useToast } from '@/components/ui/toast';
import { ROUTES } from '@/lib/config/routes';
import type { BookingDraft, BookingStatus, Ride } from '@/lib/domain/types';
import { useBookingStore } from '@/stores/booking-store';

/** What a route of the booking flow needs. */
export type BookingRequirement = 'pickup' | 'destination' | 'vehicle' | 'fare' | 'ride';

/** The rules of one route of the booking flow. */
export interface RouteStageRule {
  /** The booking statuses that may show this route. */
  allowed: readonly BookingStatus[];
  /** What has to be there before the route may show. */
  requires: readonly BookingRequirement[];
}

/** The rules of every route of the booking flow. */
export const ROUTE_STAGE_RULES: Record<string, RouteStageRule> = {
  [ROUTES.pickupSelection]: { allowed: ['idle', 'selectingPickup'], requires: [] },
  [ROUTES.destinationSelection]: {
    allowed: ['selectingPickup', 'selectingDestination'],
    requires: ['pickup'],
  },
  [ROUTES.vehicleSelection]: {
    allowed: ['selectingDestination', 'selectingVehicle'],
    requires: ['pickup', 'destination'],
  },
  [ROUTES.fareDetails]: {
    allowed: ['selectingVehicle', 'reviewingFare'],
    requires: ['pickup', 'destination', 'vehicle', 'fare'],
  },
  [ROUTES.bookingConfirmation]: {
    allowed: ['reviewingFare', 'confirmingBooking'],
    requires: ['pickup', 'destination', 'vehicle', 'fare'],
  },
  [ROUTES.searchingDriver]: { allowed: ['searchingDriver', 'failed'], requires: ['ride'] },
  [ROUTES.driverAssigned]: { allowed: ['driverAssigned', 'driverArriving'], requires: ['ride'] },
  [ROUTES.rideTracking]: {
    allowed: ['driverArriving', 'driverArrived', 'tripInProgress'],
    requires: ['ride'],
  },
  [ROUTES.tripCompleted]: { allowed: ['tripCompleted', 'awaitingRating'], requires: ['ride'] },
  [ROUTES.rideRating]: { allowed: ['awaitingRating'], requires: ['ride'] },
};

/** Where a booking status belongs. */
export const STATUS_ROUTE: Partial<Record<BookingStatus, string>> = {
  selectingPickup: ROUTES.pickupSelection,
  selectingDestination: ROUTES.destinationSelection,
  selectingVehicle: ROUTES.vehicleSelection,
  reviewingFare: ROUTES.fareDetails,
  confirmingBooking: ROUTES.bookingConfirmation,
  searchingDriver: ROUTES.searchingDriver,
  failed: ROUTES.searchingDriver,
  driverAssigned: ROUTES.driverAssigned,
  driverArriving: ROUTES.rideTracking,
  driverArrived: ROUTES.rideTracking,
  tripInProgress: ROUTES.rideTracking,
  tripCompleted: ROUTES.tripCompleted,
  awaitingRating: ROUTES.tripCompleted,
};

/** The route of a missing prerequisite. */
const REQUIREMENT_ROUTES: Record<BookingRequirement, string> = {
  pickup: ROUTES.pickupSelection,
  destination: ROUTES.destinationSelection,
  vehicle: ROUTES.vehicleSelection,
  fare: ROUTES.fareDetails,
  ride: ROUTES.searchingDriver,
};

/** The statuses of a ride that is still on its way. */
const LIVE_RIDE_STATUSES: readonly BookingStatus[] = [
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
  'tripInProgress',
  'tripCompleted',
];

/** The routes that only make sense with an active ride. */
export const LIVE_RIDE_ROUTES: readonly string[] = [
  ROUTES.searchingDriver,
  ROUTES.driverAssigned,
  ROUTES.rideTracking,
  ROUTES.tripCompleted,
  ROUTES.rideRating,
];

/** The state the redirect is computed from. */
export interface BookingStageState {
  status: BookingStatus;
  draft: BookingDraft;
  activeRide: Ride | null;
}

/** The first requirement that is not fulfilled. */
function firstMissingRequirement(
  requires: readonly BookingRequirement[],
  draft: BookingDraft,
  activeRide: Ride | null,
): string | null {
  for (const requirement of requires) {
    switch (requirement) {
      case 'pickup':
        if (!draft.pickup) return REQUIREMENT_ROUTES.pickup;
        break;
      case 'destination':
        if (!draft.destination) return REQUIREMENT_ROUTES.destination;
        break;
      case 'vehicle':
        if (!draft.vehicle) return REQUIREMENT_ROUTES.vehicle;
        break;
      case 'fare':
        if (!draft.fare) return REQUIREMENT_ROUTES.fare;
        break;
      case 'ride':
        if (!activeRide) return REQUIREMENT_ROUTES.ride;
        break;
      default:
        break;
    }
  }
  return null;
}

/**
 * The route the passenger belongs to, or `null` when the route may show.
 *
 * The rules are tried in this order:
 * 1. a live ride knows where the passenger is;
 * 2. the status of the booking knows where the passenger is;
 * 3. the route needs a prerequisite that is missing;
 * 4. a finished ride ends the booking.
 */
export function resolveBookingRedirect(
  route: string,
  state: BookingStageState,
): string | null {
  const { status, draft, activeRide } = state;
  const rule = ROUTE_STAGE_RULES[route];

  // The thank-you view may stay open right after the rating.
  if (route === ROUTES.rideRating && status === 'rated') return null;

  // A finished ride ends the booking.
  if (activeRide && (activeRide.status === 'cancelled' || activeRide.status === 'rated')) {
    return ROUTES.home;
  }

  // Without a ride the live routes have nothing to show.
  if (!activeRide && LIVE_RIDE_ROUTES.includes(route)) return ROUTES.home;

  // A ride that is on its way knows where the passenger is.
  if (activeRide && LIVE_RIDE_STATUSES.includes(activeRide.status)) {
    const target = STATUS_ROUTE[activeRide.status];
    if (target && target !== route) return target;
  }

  // The status of the booking knows where the passenger is.
  const statusTarget = STATUS_ROUTE[status];
  if (statusTarget && statusTarget !== route && rule && !rule.allowed.includes(status)) {
    return statusTarget;
  }

  if (rule) {
    const missing = firstMissingRequirement(rule.requires, draft, activeRide);
    if (missing) return missing;

    if (!rule.allowed.includes(status)) {
      return statusTarget ?? ROUTES.home;
    }
  }

  return null;
}

export interface BookingStageGuardProps {
  /** The route this guard protects. */
  route: string;
  children: ReactNode;
}

export function BookingStageGuard({ route, children }: BookingStageGuardProps) {
  const router = useRouter();
  const pathname = usePathname();
  const { show } = useToast();

  const hasHydrated = useBookingStore((state) => state.hasHydrated);
  const status = useBookingStore((state) => state.status);
  const draft = useBookingStore((state) => state.draft);
  const activeRide = useBookingStore((state) => state.activeRide);

  /** The redirect happens once - the effect must not replace again. */
  const redirecting = useRef(false);
  /** The toast is shown once per guard. */
  const notified = useRef(false);

  const redirect = resolveBookingRedirect(route, { status, draft, activeRide });

  useEffect(() => {
    if (!hasHydrated || redirecting.current) return;
    if (!redirect || redirect === pathname) return;

    redirecting.current = true;
    if (!notified.current) {
      notified.current = true;
      show({ message: 'Let us take you back to where you left off.', tone: 'neutral' });
    }
    router.replace(redirect);
  }, [hasHydrated, redirect, pathname, router, show]);

  if (!hasHydrated) return <AppSkeleton />;
  if (redirect && redirect !== pathname) return <AppSkeleton />;

  return <>{children}</>;
}
