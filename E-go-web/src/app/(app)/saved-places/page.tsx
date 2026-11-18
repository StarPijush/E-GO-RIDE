import type { Metadata } from "next";

import { SavedPlacesScreen } from "@/components/places/saved-places-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.savedPlaces;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function SavedPlacesPage() {
  return <SavedPlacesScreen />;
}
