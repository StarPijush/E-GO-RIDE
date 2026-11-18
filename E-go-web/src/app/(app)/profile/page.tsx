import type { Metadata } from "next";

import { ProfileScreen } from "@/components/account/profile-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.profile;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function ProfilePage() {
  return <ProfileScreen />;
}
