import type { Metadata } from "next";

import { ConfirmationScreen } from "@/components/booking/confirmation-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.bookingConfirmation;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function BookingConfirmationPage() {
  return <ConfirmationScreen />;
}
