import type { Metadata } from "next";

import { DriverAssignedScreen } from "@/components/booking/driver-assigned-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.driverAssigned;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function DriverAssignedPage() {
  return <DriverAssignedScreen />;
}
