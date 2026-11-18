import type { Metadata } from "next";

import { TripCompletedScreen } from "@/components/booking/trip-completed-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.tripCompleted;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function TripCompletedPage() {
  return <TripCompletedScreen />;
}
