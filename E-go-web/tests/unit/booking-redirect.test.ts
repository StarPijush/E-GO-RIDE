import { describe, expect, it } from "vitest";

import { resolveBookingRedirect } from "@/components/shared/booking-stage-guard";
import { calculateFare } from "@/lib/domain/fare";
import type { BookingDraft, Place, Ride } from "@/lib/domain/types";

const pickup: Place = {
  id: "place-001",
  label: "Jhargram Railway Station",
  address: "Jhargram, West Bengal",
  kind: "pickup",
  lat: 22.4529,
  lng: 86.9003,
};

const destination: Place = {
  id: "place-006",
  label: "Jhargram College",
  address: "Jhargram, West Bengal",
  kind: "destination",
  lat: 22.461,
  lng: 86.912,
};

const fullDraft: BookingDraft = {
  pickup,
  destination,
  vehicle: "bike",
  fare: calculateFare("bike", pickup, destination),
};

function makeRide(overrides: Partial<Ride> = {}): Ride {
  return {
    id: "ride-1",
    userId: "user-1",
    pickup,
    destination,
    vehicle: "bike",
    fare: calculateFare("bike", pickup, destination),
    status: "searchingDriver",
    paymentMethodId: "cash-1",
    createdAt: "2026-11-15T10:00:00.000Z",
    phaseStartedAt: "2026-11-15T10:00:00.000Z",
    timeline: [{ status: "searchingDriver", at: "2026-11-15T10:00:00.000Z" }],
    ...overrides,
  };
}

describe("resolveBookingRedirect", () => {
  it("keeps the pickup selection of an idle booking", () => {
    expect(
      resolveBookingRedirect("/pickup-selection", {
        status: "idle",
        draft: {},
        activeRide: null,
      }),
    ).toBeNull();
  });

  it("sends an idle booking to the pickup selection", () => {
    expect(
      resolveBookingRedirect("/destination-selection", {
        status: "idle",
        draft: {},
        activeRide: null,
      }),
    ).toBe("/pickup-selection");
  });

  it("sends a booking that has a destination to the destination selection", () => {
    expect(
      resolveBookingRedirect("/pickup-selection", {
        status: "selectingDestination",
        draft: { ...fullDraft, vehicle: undefined, fare: undefined },
        activeRide: null,
      }),
    ).toBe("/destination-selection");
  });

  it("keeps the vehicle selection of a booking that has a vehicle", () => {
    expect(
      resolveBookingRedirect("/vehicle-selection", {
        status: "selectingVehicle",
        draft: fullDraft,
        activeRide: null,
      }),
    ).toBeNull();
  });

  it("follows a live ride to the tracking page", () => {
    const ride = makeRide({ status: "driverArriving" });

    expect(
      resolveBookingRedirect("/vehicle-selection", {
        status: "driverArriving",
        draft: fullDraft,
        activeRide: ride,
      }),
    ).toBe("/ride-tracking");

    expect(
      resolveBookingRedirect("/ride-tracking", {
        status: "driverArriving",
        draft: fullDraft,
        activeRide: ride,
      }),
    ).toBeNull();
  });

  it("keeps a failed search on the searching page", () => {
    const failed = makeRide({ status: "failed" });

    expect(
      resolveBookingRedirect("/searching-driver", {
        status: "failed",
        draft: fullDraft,
        activeRide: failed,
      }),
    ).toBeNull();

    expect(
      resolveBookingRedirect("/destination-selection", {
        status: "failed",
        draft: fullDraft,
        activeRide: failed,
      }),
    ).toBe("/searching-driver");
  });

  it("sends a finished ride home", () => {
    const cancelled = makeRide({ status: "cancelled" });

    expect(
      resolveBookingRedirect("/pickup-selection", {
        status: "cancelled",
        draft: fullDraft,
        activeRide: cancelled,
      }),
    ).toBe("/home");
  });

  it("sends the passenger home when a live route has no ride", () => {
    expect(
      resolveBookingRedirect("/ride-tracking", {
        status: "idle",
        draft: fullDraft,
        activeRide: null,
      }),
    ).toBe("/home");

    expect(
      resolveBookingRedirect("/ride-rating", {
        status: "idle",
        draft: fullDraft,
        activeRide: null,
      }),
    ).toBe("/home");
  });

  it("keeps the rating screen open right after the rating", () => {
    const rated = makeRide({ status: "rated" });

    expect(
      resolveBookingRedirect("/ride-rating", {
        status: "rated",
        draft: fullDraft,
        activeRide: rated,
      }),
    ).toBeNull();
  });
});
