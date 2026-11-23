import type { Metadata } from "next";

import { SettingsScreen } from "@/components/settings/settings-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.settings;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function SettingsPage() {
  return <SettingsScreen />;
}
