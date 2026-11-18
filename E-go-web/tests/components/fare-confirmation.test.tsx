import { render, screen } from "@testing-library/react";
import { beforeEach, describe, expect, it, vi } from "vitest";

const push = vi.fn();

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: vi.fn(), push }),
  usePathname: () => "/fare-details",
}));

import { ConfirmationScreen } from "@/components/booking/confirmation-screen";
import { FareScreen } from "@/components/booking/fare-screen";
import { ToastProvider } from "@/components/ui/toast";
import { calculateFare } from "@/lib/domain/fare";
import type { Place } from "@/lib/domain/types";
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

beforeEach(() => {
  useBookingStore.setState({
    status: "reviewingFare",
    draft: {
      pickup: PICKUP,
      destination: DESTINATION,
      vehicle: "toto",
      fare: calculateFare("toto", PICKUP, DESTINATION),
    },
    activeRide: null,
    pending: false,
    lastError: null,
    hasHydrated: true,
  });
});

describe("fare screen", () => {
  it("shows the fare rows of the stored estimate", () => {
    const fare = calculateFare("toto", PICKUP, DESTINATION);

    render(
      <ToastProvider>
        <FareScreen />
      </ToastProvider>,
    );

    expect(screen.getByText("Base fare")).toBeInTheDocument();
    expect(screen.getByText(`Distance (${fare.distanceKm} km × ₹7/km)`)).toBeInTheDocument();
    expect(screen.getByText("Platform fee")).toBeInTheDocument();
    expect(screen.getByText("Total estimate")).toBeInTheDocument();
    // The total shows up in the breakdown and in the vehicle summary.
    expect(screen.getAllByText(`₹${fare.total}`).length).toBeGreaterThan(0);
    expect(screen.getByText("This is a demo fare estimate. Actual fares may vary.")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Confirm vehicle" })).toBeEnabled();
  });

  it("shows the cash payment only", () => {
    render(
      <ToastProvider>
        <FareScreen />
      </ToastProvider>,
    );

    expect(screen.getByText("Payment method")).toBeInTheDocument();
    expect(screen.getAllByText("Cash").length).toBeGreaterThan(0);
    expect(screen.getByText("Pay the driver directly in this demo.")).toBeInTheDocument();
    expect(screen.queryByText(/UPI/)).toBeNull();
  });
});

describe("confirmation screen", () => {
  it("warns that no driver is dispatched", () => {
    render(
      <ToastProvider>
        <ConfirmationScreen />
      </ToastProvider>,
    );

    expect(screen.getByText("Demo mode: No real driver will be dispatched.")).toBeInTheDocument();
    expect(
      screen.getByText("You can cancel free of charge while searching or before the trip starts."),
    ).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Confirm booking" })).toBeEnabled();
    expect(screen.getByText("Total estimate")).toBeInTheDocument();
  });
});
