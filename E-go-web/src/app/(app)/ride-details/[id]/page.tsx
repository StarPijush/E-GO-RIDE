import type { Metadata } from "next";

import { RideDetailsScreen } from "@/components/rides/ride-details-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.rideDetails;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default async function RideDetailsPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;

  return <RideDetailsScreen rideId={id} />;
}
