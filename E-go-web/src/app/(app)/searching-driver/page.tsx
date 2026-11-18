import type { Metadata } from "next";

import { SearchingScreen } from "@/components/booking/searching-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.searchingDriver;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function SearchingDriverPage() {
  return <SearchingScreen />;
}
