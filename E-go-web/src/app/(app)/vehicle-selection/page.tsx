import type { Metadata } from "next";

import { VehicleScreen } from "@/components/booking/vehicle-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.vehicleSelection;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function VehicleSelectionPage() {
  return <VehicleScreen />;
}
