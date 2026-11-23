import { fireEvent, render, screen } from "@testing-library/react";
import { describe, expect, it, vi } from "vitest";

const mocks = vi.hoisted(() => ({
  replace: vi.fn(),
  push: vi.fn(),
}));

vi.mock("next/navigation", () => ({
  useRouter: () => ({ replace: mocks.replace, push: mocks.push }),
  usePathname: () => "/help-support",
  useSearchParams: () => new URLSearchParams(),
}));

import { AboutScreen } from "@/components/support/about-screen";
import { HelpSupportScreen } from "@/components/support/help-support-screen";
import { SafetyScreen } from "@/components/support/safety-screen";
import { ToastHost, ToastProvider } from "@/components/ui/toast";

function renderScreen(node: React.ReactNode) {
  return render(
    <ToastProvider>
      <ToastHost />
      {node}
    </ToastProvider>,
  );
}

describe("help & support", () => {
  it("shows the support desk and the FAQ", () => {
    renderScreen(<HelpSupportScreen />);

    expect(screen.getByRole("heading", { name: "Help & Support" })).toBeInTheDocument();
    expect(screen.getByText("E-GO Support Team")).toBeInTheDocument();
    expect(
      screen.getByText(
        "We are here to assist with your rides, safety, and payments in Jhargram.",
      ),
    ).toBeInTheDocument();
    expect(screen.getByText("How do I book a ride?")).toBeInTheDocument();
  });

  it("submits an issue report through the dialog", async () => {
    renderScreen(<HelpSupportScreen />);

    fireEvent.click(screen.getByRole("button", { name: "Report an issue" }));

    expect(screen.getByRole("dialog", { name: "Report an Issue" })).toBeInTheDocument();

    const submit = screen.getByRole("button", { name: "Submit" });
    expect(submit).toBeDisabled();

    fireEvent.change(screen.getByLabelText("Your report"), {
      target: { value: "Driver requested excess cash." },
    });

    expect(submit).toBeEnabled();
    fireEvent.click(submit);

    expect(
      await screen.findByText("Issue report submitted! Our support team will review it."),
    ).toBeInTheDocument();
  });
});

describe("safety", () => {
  it("triggers the simulated emergency alert", async () => {
    renderScreen(<SafetyScreen />);

    expect(screen.getByRole("heading", { name: "Safety" })).toBeInTheDocument();
    expect(screen.queryByRole("heading", { name: "Help & Support" })).toBeNull();

    fireEvent.click(screen.getByRole("button", { name: "TRIGGER EMERGENCY SOS" }));

    expect(
      await screen.findByText(
        "Emergency SOS triggered (Demo Simulation). Contacts notified.",
      ),
    ).toBeInTheDocument();
  });
});

describe("about", () => {
  it("shows the mission, the region and the vehicles", () => {
    renderScreen(<AboutScreen />);

    expect(
      screen.getByText(
        "E-GO is built specifically for Jhargram - connecting passengers with local Toto (E-Rickshaw) and Bike drivers through simple, transparent, and fair pricing. No hidden surge, no complicated apps.",
      ),
    ).toBeInTheDocument();
    expect(screen.getByText(/Up to 3 passengers/)).toBeInTheDocument();
    expect(screen.getByText(/single-passenger/)).toBeInTheDocument();
    expect(screen.getByText("© 2026 E-GO. All rights reserved.")).toBeInTheDocument();
  });
});
