import type { Metadata } from "next";

import { CreateAccountForm } from "@/components/auth/create-account-form";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.createAccount;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function CreateAccountPage() {
  return <CreateAccountForm />;
}
