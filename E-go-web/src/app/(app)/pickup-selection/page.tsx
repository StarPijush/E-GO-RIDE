import type { Metadata } from "next";

import { PickupScreen } from "@/components/location/pickup-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.pickupSelection;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function PickupSelectionPage() {
  return <PickupScreen />;
}
