import type { Metadata } from "next";

import { DestinationScreen } from "@/components/location/destination-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.destinationSelection;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function DestinationSelectionPage() {
  return <DestinationScreen />;
}
