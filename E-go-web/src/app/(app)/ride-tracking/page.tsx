import type { Metadata } from "next";

import { RideTrackingScreen } from "@/components/booking/ride-tracking-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.rideTracking;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function RideTrackingPage() {
  return <RideTrackingScreen />;
}
