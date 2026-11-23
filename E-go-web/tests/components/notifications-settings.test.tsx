import { fireEvent, render, screen, waitFor, within } from "@testing-library/react";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  replace: vi.fn(),
  push: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  usePathname: () => "/notifications",
  useSearchParams: () => new URLSearchParams(),
}));

import { NotificationsScreen } from "@/components/notifications/notifications-screen";
import { SettingsScreen } from "@/components/settings/settings-screen";
import { ToastProvider } from "@/components/ui/toast";
import { createEmptyDb, loadDb, saveDb, type StoredNotification } from "@/lib/mock/db";
import { DEMO_USER } from "@/lib/mock/seeds";
import { useAuthStore } from "@/stores/auth-store";

const USER = { ...DEMO_USER, createdAt: "2026-11-01T08:00:00.000Z" };

const NOTIFICATIONS: StoredNotification[] = [
  {
    id: "notif-test-unread",
    kind: "ride",
    title: "Driver assigned",
    body: "Suresh Das is on the way to your pickup point.",
    createdAt: "2026-11-12T07:46:30.000Z",
    read: false,
    userId: USER.id,
  },
  {
    id: "notif-test-read",
    kind: "system",
    title: "Welcome to E-GO!",
    body: "Book your first ride and move your way.",
    createdAt: "2026-11-11T09:15:00.000Z",
    read: true,
    userId: USER.id,
  },
];

function renderScreen(node: React.ReactNode) {
  return render(<ToastProvider>{node}</ToastProvider>);
}

beforeEach(() => {
  saveDb({
    ...createEmptyDb(),
    users: [USER],
    notifications: NOTIFICATIONS.map((notification) => ({ ...notification })),
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

describe("notifications", () => {
  it("lists the notifications and marks an unread one as read", async () => {
    renderScreen(<NotificationsScreen />);

    expect(await screen.findByText("Driver assigned")).toBeInTheDocument();
    expect(screen.getByText("Suresh Das is on the way to your pickup point.")).toBeInTheDocument();
    expect(screen.getByText("Welcome to E-GO!")).toBeInTheDocument();
    expect(screen.getByText("Book your first ride and move your way.")).toBeInTheDocument();

    const unreadRow = screen.getByRole("button", { name: /Driver assigned/ });
    expect(within(unreadRow).getByText("Unread")).toBeInTheDocument();

    fireEvent.click(unreadRow);

    await waitFor(() => {
      expect(loadDb().notifications.find((notification) => notification.id === "notif-test-unread")?.read).toBe(
        true,
      );
    });
  });
});

describe("settings", () => {
  it("shows and toggles the notification preferences", () => {
    renderScreen(<SettingsScreen />);

    const rideAlerts = screen.getByRole("switch", { name: "Ride Status Alerts" });
    const smsUpdates = screen.getByRole("switch", { name: "SMS Updates" });
    const offers = screen.getByRole("switch", { name: "Offers & Discounts" });

    expect(rideAlerts).toHaveAttribute("aria-checked", "true");
    expect(smsUpdates).toHaveAttribute("aria-checked", "true");
    expect(offers).toHaveAttribute("aria-checked", "false");

    fireEvent.click(offers);

    expect(offers).toHaveAttribute("aria-checked", "true");
  });

  it("changes the app language and closes the sheet", () => {
    renderScreen(<SettingsScreen />);

    expect(screen.getByText("English")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /App Language/ }));
    fireEvent.click(screen.getByRole("radio", { name: "বাংলা (Bengali)" }));

    expect(screen.queryByRole("dialog", { name: "Choose Language" })).toBeNull();
    expect(screen.getByText("বাংলা (Bengali)")).toBeInTheDocument();
  });
});
