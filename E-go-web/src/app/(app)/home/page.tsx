import type { Metadata } from "next";

import { HomeScreen } from "@/components/home/home-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.home;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function HomePage() {
  return <HomeScreen />;
}
