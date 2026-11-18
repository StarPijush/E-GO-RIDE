import type { Metadata } from "next";

import { EditProfileScreen } from "@/components/account/edit-profile-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.editProfile;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function EditProfilePage() {
  return <EditProfileScreen />;
}
