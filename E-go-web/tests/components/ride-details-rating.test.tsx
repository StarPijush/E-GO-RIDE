import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  replace: vi.fn(),
  push: vi.fn(),
  rideQuery: { value: "" },
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  usePathname: () => "/ride-details/historical-ride",
  useSearchParams: () => new URLSearchParams(mocks.rideQuery.value),
}));

import { RatingScreen } from "@/components/booking/rating-screen";
import { RideDetailsScreen } from "@/components/rides/ride-details-screen";
import { ToastProvider } from "@/components/ui/toast";
import { calculateFare } from "@/lib/domain/fare";
import type { Place, Ride } from "@/lib/domain/types";
import { createEmptyDb, loadDb, saveDb } from "@/lib/mock/db";
import { DEMO_USER } from "@/lib/mock/seeds";
import { useAuthStore } from "@/stores/auth-store";
import { useBookingStore } from "@/stores/booking-store";

const PICKUP: Place = {
  id: "place-001",
  label: "Jhargram Railway Station",
  address: "Jhargram, West Bengal",
  kind: "pickup",
  lat: 22.4529,
  lng: 86.9003,
};

const DESTINATION: Place = {
  id: "place-006",
  label: "Jhargram College",
  address: "Jhargram, West Bengal",
  kind: "destination",
  lat: 22.461,
  lng: 86.912,
};

const FARE = calculateFare("bike", PICKUP, DESTINATION);

const HISTORICAL_RIDE: Ride = {
  id: "historical-ride",
  userId: DEMO_USER.id,
  pickup: PICKUP,
  destination: DESTINATION,
  vehicle: "bike",
  fare: FARE,
  status: "awaitingRating",
  driver: {
    id: "driver-001",
    name: "Rajan Kumar",
    rating: 4.8,
    ridesCompleted: 324,
    vehicleType: "bike",
    vehicleModel: "Hero Splendor",
    vehicleNumber: "WB 32 D 1234",
    location: { lat: 22.455, lng: 86.902 },
    etaMinutes: 3,
  },
  paymentMethodId: "cash-demo-001",
  createdAt: "2026-11-09T18:30:00.000Z",
  phaseStartedAt: "2026-11-09T18:38:30.000Z",
  completedAt: "2026-11-09T18:38:00.000Z",
  timeline: [{ status: "awaitingRating", at: "2026-11-09T18:38:30.000Z" }],
};

function renderScreen(node: React.ReactNode) {
  return render(<ToastProvider>{node}</ToastProvider>);
}

beforeEach(() => {
  mocks.rideQuery.value = "";

  saveDb({
    ...createEmptyDb(),
    users: [{ ...DEMO_USER, createdAt: "2026-11-01T08:00:00.000Z" }],
    rides: [HISTORICAL_RIDE],
  });

  useAuthStore.setState({
    user: { ...DEMO_USER, createdAt: "2026-11-01T08:00:00.000Z" },
    session: null,
    hasHydrated: true,
  });

  useBookingStore.setState({
    status: "idle",
    draft: {},
    activeRide: null,
    pending: false,
    lastError: null,
    hasHydrated: true,
  });
});

afterEach(() => {
  vi.clearAllMocks();
});

describe("ride details", () => {
  it("shows the ride and offers the rating", async () => {
    renderScreen(<RideDetailsScreen rideId="historical-ride" />);

    await waitFor(() => {
      expect(screen.getByText("historical-ride")).toBeInTheDocument();
    });

    expect(screen.getByText("Jhargram Railway Station")).toBeInTheDocument();
    expect(screen.getByText("Jhargram College")).toBeInTheDocument();
    expect(screen.getByText(`₹${FARE.total}`)).toBeInTheDocument();
    expect(screen.getByText("Rajan Kumar")).toBeInTheDocument();

    const rateLink = screen.getByRole("link", { name: "Rate this ride" });
    expect(rateLink).toHaveAttribute("href", "/ride-rating?rideId=historical-ride");
  });
});

describe("historical rating", () => {
  it("rates a ride of the history without touching the booking", async () => {
    mocks.rideQuery.value = "rideId=historical-ride";

    renderScreen(<RatingScreen />);

    await waitFor(() => {
      expect(screen.getByText("How was your ride?")).toBeInTheDocument();
    });

    fireEvent.click(screen.getByLabelText("5 stars - Excellent!"));
    fireEvent.click(screen.getByRole("button", { name: "Submit rating" }));

    await waitFor(() => {
      expect(loadDb().rides[0].status).toBe("rated");
    });

    expect(await screen.findByText("Thank you!")).toBeInTheDocument();

    // The booking of the running app is not touched by a historical rating.
    expect(useBookingStore.getState().status).toBe("idle");
    expect(useBookingStore.getState().activeRide).toBeNull();
  });
});
