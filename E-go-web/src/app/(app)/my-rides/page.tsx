import type { Metadata } from "next";

import { MyRidesScreen } from "@/components/rides/my-rides-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.myRides;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function MyRidesPage() {
  return <MyRidesScreen />;
}
