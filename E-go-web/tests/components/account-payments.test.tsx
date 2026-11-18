import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  replace: vi.fn(),
  push: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  usePathname: () => "/profile",
  useSearchParams: () => new URLSearchParams(),
}));

import { EditProfileScreen } from "@/components/account/edit-profile-screen";
import { PaymentMethodsScreen } from "@/components/account/payment-methods-screen";
import { ProfileScreen } from "@/components/account/profile-screen";
import { ToastProvider } from "@/components/ui/toast";
import { createEmptyDb, saveDb } from "@/lib/mock/db";
import { DEMO_USER } from "@/lib/mock/seeds";
import { useAuthStore } from "@/stores/auth-store";

const USER = { ...DEMO_USER, createdAt: "2026-11-01T08:00:00.000Z" };

function renderScreen(node: React.ReactNode) {
  return render(<ToastProvider>{node}</ToastProvider>);
}

beforeEach(() => {
  saveDb({
    ...createEmptyDb(),
    users: [USER],
  });

  useAuthStore.setState({
    user: USER,
    session: null,
    hasHydrated: true,
  });
});

afterEach(() => {
  vi.clearAllMocks();
});

describe("profile", () => {
  it("shows the account and the menu", async () => {
    renderScreen(<ProfileScreen />);

    expect(await screen.findByText("E-GO Demo User")).toBeInTheDocument();
    expect(screen.getByText("+919000000001")).toBeInTheDocument();

    const links: Record<string, string> = {
      "My rides": "/my-rides",
      "Saved places": "/saved-places",
      "Payment methods": "/payment-methods",
      "Help & Support": "/help-support",
      Notifications: "/notifications",
      Settings: "/settings",
      "About E-GO": "/about",
    };

    for (const [label, href] of Object.entries(links)) {
      expect(screen.getByRole("link", { name: label })).toHaveAttribute("href", href);
    }
  });
});

describe("edit profile", () => {
  it("saves the name of the passenger", async () => {
    renderScreen(<EditProfileScreen />);

    const name = await screen.findByLabelText(/Full name/);
    fireEvent.change(name, { target: { value: "Updated Rider" } });
    fireEvent.click(screen.getByRole("button", { name: "Save changes" }));

    await waitFor(() => {
      expect(useAuthStore.getState().user?.fullName).toBe("Updated Rider");
    });
  });
});

describe("payment methods", () => {
  it("shows cash as the only selectable method", async () => {
    renderScreen(<PaymentMethodsScreen />);

    expect(await screen.findByText("Cash")).toBeInTheDocument();
    expect(screen.getByText("UPI (GPay, PhonePe, Paytm)")).toBeInTheDocument();
    expect(screen.getByText("Coming soon")).toBeInTheDocument();
    expect(
      screen.getByText(
        "In this preview release of E-GO, payments are simulated. No real monetary transactions or banking APIs are connected.",
      ),
    ).toBeInTheDocument();

    const upi = screen.getByRole("button", { name: /UPI \(GPay, PhonePe, Paytm\)/ });
    expect(upi).toBeDisabled();
  });
});
