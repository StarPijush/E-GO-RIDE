import type { Metadata } from "next";

import { NotificationsScreen } from "@/components/notifications/notifications-screen";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.notifications;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function NotificationsPage() {
  return <NotificationsScreen />;
}
