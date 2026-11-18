import type { Metadata } from "next";

import { FareScreen } from "@/components/booking/fare-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.fareDetails;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function FareDetailsPage() {
  return <FareScreen />;
}
