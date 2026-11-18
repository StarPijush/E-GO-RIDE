import { render, screen } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

const push = vi.fn();

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: vi.fn(), push }),
  usePathname: () => "/home",
}));

import { HomeScreen } from "@/components/home/home-screen";
import { ToastProvider } from "@/components/ui/toast";
import { useAuthStore } from "@/stores/auth-store";
import { useBookingStore } from "@/stores/booking-store";

function renderScreen() {
  return render(
    <ToastProvider>
      <HomeScreen />
    </ToastProvider>,
  );
}

afterEach(() => {
  vi.clearAllMocks();
  useAuthStore.setState({ user: null, session: null, onboardingSeen: true, hasHydrated: true });
  useBookingStore.setState({
    status: "idle",
    draft: {},
    activeRide: null,
    pending: false,
    lastError: null,
  });
});

describe("home screen", () => {
  it("greets the passenger and shows the booking rows", () => {
    useAuthStore.setState({
      user: {
        id: "demo-ego-001",
        fullName: "Asha Verma",
        phone: "+919876543210",
        profileComplete: true,
        createdAt: new Date().toISOString(),
      },
    });

    renderScreen();

    expect(screen.getByRole("heading", { name: "Where to, Asha?" })).toBeInTheDocument();
    expect(
      screen.getByText("Book a Toto or bike ride across Jhargram in a few taps."),
    ).toBeInTheDocument();
    expect(screen.getByText("Pickup")).toBeInTheDocument();
    expect(screen.getByText("Destination")).toBeInTheDocument();
    expect(screen.getByText("Current location")).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Choose destination/ })).toBeInTheDocument();
    expect(
      screen.getByText("Drivers, routes and fares are simulated in this demo."),
    ).toBeInTheDocument();
  });

  it("opens the pickup selection", () => {
    renderScreen();

    screen.getByText("Pickup").click();

    expect(push).toHaveBeenCalledWith("/pickup-selection");
  });

  it("opens the destination selection and sets the demo pickup", () => {
    renderScreen();

    screen.getByText("Destination").click();

    expect(push).toHaveBeenCalledWith("/destination-selection");
    expect(useBookingStore.getState().draft.pickup?.label).toBe("Current location");
  });

  it("shows the active ride banner instead of a second booking", () => {
    useBookingStore.setState({
      status: "driverAssigned",
      activeRide: {
        id: "ride-1",
        userId: "demo-ego-001",
        pickup: {
          id: "place-001",
          label: "Jhargram Railway Station",
          address: "Jhargram, West Bengal",
          kind: "pickup",
          lat: 22.4529,
          lng: 86.9003,
        },
        destination: {
          id: "place-006",
          label: "Jhargram College",
          address: "Jhargram, West Bengal",
          kind: "destination",
          lat: 22.461,
          lng: 86.912,
        },
        vehicle: "bike",
        fare: {
          vehicle: "bike",
          baseFare: 20,
          distanceFare: 20,
          platformFee: 3,
          total: 43,
          distanceKm: 2,
          estimatedMinutes: 9,
          estimatedArrivalMinutes: 3,
          currency: "INR",
        },
        status: "driverAssigned",
        paymentMethodId: "cash-1",
        createdAt: new Date().toISOString(),
        phaseStartedAt: new Date().toISOString(),
        timeline: [{ status: "driverAssigned", at: new Date().toISOString() }],
      },
    });

    renderScreen();

    expect(screen.getByText("Driver assigned")).toBeInTheDocument();
    expect(screen.getByText("₹43")).toBeInTheDocument();
    expect(screen.getByRole("link", { name: "Resume ride" })).toHaveAttribute(
      "href",
      "/driver-assigned",
    );
    expect(screen.getByRole("link", { name: "View current ride" })).toBeInTheDocument();
    expect(screen.queryByRole("button", { name: /Choose destination/ })).toBeNull();
  });
});
