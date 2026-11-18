import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import type { ReactNode } from "react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const { push, replace, currentPath } = vi.hoisted(() => ({
  push: vi.fn(),
  replace: vi.fn(),
  currentPath: { value: "/pickup-selection" },
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace, push }),
  usePathname: () => currentPath.value,
}));

import { DestinationScreen } from "@/components/location/destination-screen";
import { PickupScreen } from "@/components/location/pickup-screen";
import { ToastProvider } from "@/components/ui/toast";
import { useBookingStore } from "@/stores/booking-store";

const PICKUP = {
  id: "place-001",
  label: "Jhargram Railway Station",
  address: "Jhargram, West Bengal",
  kind: "pickup" as const,
  lat: 22.4529,
  lng: 86.9003,
};

function renderScreen(node: ReactNode) {
  return render(<ToastProvider>{node}</ToastProvider>);
}

beforeEach(() => {
  currentPath.value = "/pickup-selection";
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

describe("pickup screen", () => {
  it("starts the booking and shows the search", async () => {
    renderScreen(<PickupScreen />);

    expect(useBookingStore.getState().status).toBe("selectingPickup");
    expect(screen.getByRole("heading", { name: "Set pickup point" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: /Use current location/ })).toBeInTheDocument();

    await waitFor(() => {
      expect(screen.getByText("Jhargram Railway Station")).toBeInTheDocument();
    });
  });

  it("chooses the current location and continues", async () => {
    renderScreen(<PickupScreen />);

    fireEvent.click(screen.getByRole("button", { name: /Use current location/ }));

    expect(useBookingStore.getState().draft.pickup?.label).toBe("Current location");
    expect(push).toHaveBeenCalledWith("/destination-selection");
  });

  it("selects a place from the results", async () => {
    renderScreen(<PickupScreen />);

    await waitFor(() => {
      expect(screen.getByText("Jhargram Railway Station")).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText("Jhargram Railway Station"));

    expect(useBookingStore.getState().draft.pickup?.label).toBe("Jhargram Railway Station");
    expect(push).toHaveBeenCalledWith("/destination-selection");
  });
});

describe("destination screen", () => {
  it("shows the route card and the search", async () => {
    currentPath.value = "/destination-selection";
    useBookingStore.setState({
      status: "selectingDestination",
      draft: { pickup: PICKUP },
    });

    renderScreen(<DestinationScreen />);

    expect(screen.getByRole("heading", { name: "Where are you going?" })).toBeInTheDocument();
    expect(screen.getByRole("button", { name: "Change pickup" })).toBeInTheDocument();
    expect(screen.getAllByText("Jhargram Railway Station").length).toBeGreaterThan(0);

    await waitFor(() => {
      expect(screen.getByText("Jhargram College")).toBeInTheDocument();
    });
  });

  it("chooses a destination and continues to the vehicles", async () => {
    currentPath.value = "/destination-selection";
    useBookingStore.setState({
      status: "selectingDestination",
      draft: { pickup: PICKUP },
    });

    renderScreen(<DestinationScreen />);

    await waitFor(() => {
      expect(screen.getByText("Jhargram College")).toBeInTheDocument();
    });

    fireEvent.click(screen.getByText("Jhargram College"));

    expect(useBookingStore.getState().draft.destination?.label).toBe("Jhargram College");
    expect(push).toHaveBeenCalledWith("/vehicle-selection");
  });

  it("sends the passenger to the pickup when the pickup is missing", async () => {
    currentPath.value = "/destination-selection";

    renderScreen(<DestinationScreen />);

    await waitFor(() => {
      expect(replace).toHaveBeenCalledWith("/pickup-selection");
    });
  });
});
