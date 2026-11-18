import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: vi.fn(), push: vi.fn() }),
  usePathname: () => "/my-rides",
}));

import { MyRidesScreen } from "@/components/rides/my-rides-screen";
import { SavedPlacesScreen } from "@/components/places/saved-places-screen";
import { ToastProvider } from "@/components/ui/toast";
import { calculateFare } from "@/lib/domain/fare";
import type { Place, Ride } from "@/lib/domain/types";
import { createEmptyDb, saveDb, type StoredSavedPlace } from "@/lib/mock/db";
import { DEMO_USER } from "@/lib/mock/seeds";
import { useAuthStore } from "@/stores/auth-store";

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

const RATED_RIDE: Ride = {
  id: "rated-ride",
  userId: DEMO_USER.id,
  pickup: PICKUP,
  destination: DESTINATION,
  vehicle: "toto",
  fare: FARE,
  status: "rated",
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
  rating: {
    rideId: "rated-ride",
    stars: 5,
    tags: ["Great driver"],
    createdAt: "2026-11-02T09:26:00.000Z",
  },
  timeline: [{ status: "rated", at: "2026-11-02T09:26:00.000Z" }],
};

const CANCELLED_RIDE: Ride = {
  id: "cancelled-ride",
  userId: DEMO_USER.id,
  pickup: PICKUP,
  destination: DESTINATION,
  vehicle: "toto",
  fare: FARE,
  status: "cancelled",
  driver: {
    id: "driver-004",
    name: "Madan Mahato",
    rating: 4.9,
    ridesCompleted: 402,
    vehicleType: "toto",
    vehicleModel: "E-Rickshaw",
    vehicleNumber: "WB 32 E 2211",
    location: { lat: 22.4512, lng: 86.8987 },
    etaMinutes: 5,
  },
  paymentMethodId: "cash-demo-001",
  createdAt: "2026-11-12T07:45:00.000Z",
  phaseStartedAt: "2026-11-12T07:47:00.000Z",
  cancelledAt: "2026-11-12T07:47:00.000Z",
  cancellationReason: "changed_plan",
  timeline: [{ status: "cancelled", at: "2026-11-12T07:47:00.000Z" }],
};

const SAVED_PLACES: StoredSavedPlace[] = [
  {
    id: "place-001",
    savedId: "saved-demo-home",
    label: "Home",
    address: "Jhargram, West Bengal",
    kind: "saved",
    tag: "home",
    lat: 22.4529,
    lng: 86.9003,
    userId: DEMO_USER.id,
  },
  {
    id: "place-006",
    savedId: "saved-demo-work",
    label: "Work",
    address: "Jhargram, West Bengal",
    kind: "saved",
    tag: "work",
    lat: 22.461,
    lng: 86.912,
    userId: DEMO_USER.id,
  },
];

/** The hrefs of the ride links that are on the screen. */
function rideHrefs(): (string | null)[] {
  return screen.getAllByRole("link").map((link) => link.getAttribute("href"));
}

function renderScreen(node: React.ReactNode) {
  return render(<ToastProvider>{node}</ToastProvider>);
}

beforeEach(() => {
  saveDb({
    ...createEmptyDb(),
    users: [{ ...DEMO_USER, createdAt: "2026-11-01T08:00:00.000Z" }],
    savedPlaces: SAVED_PLACES,
    rides: [RATED_RIDE, CANCELLED_RIDE],
  });

  useAuthStore.setState({
    user: { ...DEMO_USER, createdAt: "2026-11-01T08:00:00.000Z" },
    session: null,
    hasHydrated: true,
  });
});

afterEach(() => {
  vi.clearAllMocks();
});

describe("saved places", () => {
  it("adds and removes a place", async () => {
    renderScreen(<SavedPlacesScreen />);

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Remove Home" })).toBeInTheDocument();
    });
    expect(screen.getByRole("button", { name: "Remove Work" })).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: "Add a new place" }));

    fireEvent.change(await screen.findByLabelText(/Label/), { target: { value: "Gym" } });
    fireEvent.click(screen.getByLabelText("Other"));
    fireEvent.click(screen.getByRole("button", { name: "Save" }));

    await waitFor(() => {
      expect(screen.getByRole("button", { name: "Remove Gym" })).toBeInTheDocument();
    });
    expect(screen.getAllByText("Jhargram area").length).toBeGreaterThan(0);

    fireEvent.click(screen.getByRole("button", { name: "Remove Gym" }));

    await waitFor(() => {
      expect(screen.queryByRole("button", { name: "Remove Gym" })).toBeNull();
    });
  });
});

describe("my rides", () => {
  it("lists the rides and filters them", async () => {
    renderScreen(<MyRidesScreen />);

    await waitFor(() => {
      expect(rideHrefs()).toContain("/ride-details/rated-ride");
    });
    expect(rideHrefs()).toContain("/ride-details/cancelled-ride");

    expect(screen.getByRole("link", { name: /cancelled-ride/ })).toHaveAttribute(
      "href",
      "/ride-details/cancelled-ride",
    );

    fireEvent.click(screen.getByRole("tab", { name: "Cancelled" }));

    await waitFor(() => {
      expect(rideHrefs()).not.toContain("/ride-details/rated-ride");
    });
    expect(rideHrefs()).toContain("/ride-details/cancelled-ride");

    fireEvent.click(screen.getByRole("tab", { name: "All" }));

    await waitFor(() => {
      expect(rideHrefs()).toContain("/ride-details/rated-ride");
    });
    expect(rideHrefs()).toContain("/ride-details/cancelled-ride");
  });
});
