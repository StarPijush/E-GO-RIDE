import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  push: vi.fn(),
  replace: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  usePathname: () => "/trip-completed",
  useSearchParams: () => new URLSearchParams(),
}));

import { RatingScreen } from "@/components/booking/rating-screen";
import { TripCompletedScreen } from "@/components/booking/trip-completed-screen";
import { ToastProvider } from "@/components/ui/toast";
import { createEmptyDb, saveDb } from "@/lib/mock/db";
import { calculateFare } from "@/lib/domain/fare";
import type { Place, Ride } from "@/lib/domain/types";
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

const FARE = calculateFare("toto", PICKUP, DESTINATION);

function makeRide(status: Ride["status"]): Ride {
  return {
    id: "ride-demo-001",
    userId: "demo-ego-001",
    pickup: PICKUP,
    destination: DESTINATION,
    vehicle: "toto",
    fare: FARE,
    status,
    driver: {
      id: "driver-002",
      name: "Suresh Das",
      rating: 4.6,
      ridesCompleted: 211,
      vehicleType: "toto",
      vehicleModel: "E-Rickshaw",
      vehicleNumber: "WB 32 E 5678",
      location: { lat: 22.455, lng: 86.902 },
      etaMinutes: 5,
    },
    paymentMethodId: "cash-demo-001",
    createdAt: "2026-11-02T09:12:00.000Z",
    phaseStartedAt: "2026-11-02T09:26:00.000Z",
    completedAt: "2026-11-02T09:21:00.000Z",
    timeline: [{ status: "tripCompleted", at: "2026-11-02T09:21:00.000Z" }],
  };
}

function renderScreen(node: React.ReactNode) {
  return render(<ToastProvider>{node}</ToastProvider>);
}

beforeEach(() => {
  const ride = makeRide("tripCompleted");
  // The repository reads the ride from the mock database.
  saveDb({ ...createEmptyDb(), rides: [ride] });

  useBookingStore.setState({
    status: "tripCompleted",
    draft: {},
    activeRide: ride,
    pending: false,
    lastError: null,
    hasHydrated: true,
  });
});

afterEach(() => {
  vi.clearAllMocks();
});

describe("trip completed", () => {
  it("shows the receipt", () => {
    renderScreen(<TripCompletedScreen />);

    expect(screen.getByText("You've arrived!")).toBeInTheDocument();
    expect(screen.getByText("Your trip is complete.")).toBeInTheDocument();
    expect(screen.getByText("Total fare")).toBeInTheDocument();
    expect(screen.getByText(`₹${FARE.total}`)).toBeInTheDocument();
    expect(screen.getByText("Cash payment")).toBeInTheDocument();
    expect(screen.getByText("Simulated - no money is charged.")).toBeInTheDocument();
    expect(screen.getByText("Suresh Das")).toBeInTheDocument();
    expect(screen.getByText("ride-demo-001")).toBeInTheDocument();
    expect(screen.getByText("This receipt is simulated. No real payment was taken.")).toBeInTheDocument();
  });
});

describe("ride rating", () => {
  beforeEach(() => {
    const ride = makeRide("awaitingRating");
    saveDb({ ...createEmptyDb(), rides: [ride] });

    useBookingStore.setState({
      status: "awaitingRating",
      activeRide: ride,
    });
  });

  it("asks for a star rating", async () => {
    renderScreen(<RatingScreen />);

    expect(screen.getByText("Ratings are stored in the demo only.")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Submit rating" }));

    expect(await screen.findByRole("alert")).toHaveTextContent("Please select a star rating.");
    expect(useBookingStore.getState().status).toBe("awaitingRating");
  });

  it("stores the rating and thanks the passenger", async () => {
    renderScreen(<RatingScreen />);

    fireEvent.click(screen.getByLabelText("5 stars - Excellent!"));
    fireEvent.click(screen.getByLabelText("On time"));
    fireEvent.click(screen.getByRole("button", { name: "Submit rating" }));

    await waitFor(() => {
      expect(useBookingStore.getState().status).toBe("rated");
    });

    expect(await screen.findByText("Thank you!")).toBeInTheDocument();
    expect(screen.getByText("Your feedback helps us improve.")).toBeInTheDocument();
    expect(screen.getByText("Suresh Das")).toBeInTheDocument();
  });
});
