import type { Metadata } from "next";

import { ProfileSetupForm } from "@/components/auth/profile-setup-form";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.profileSetup;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function ProfileSetupPage() {
  return <ProfileSetupForm />;
}
