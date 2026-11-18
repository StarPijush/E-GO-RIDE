import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { ROUTE_METADATA, ROUTES } from "@/lib/config/routes";

const meta = ROUTE_METADATA.register;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

/** `/register` is an alias of `/create-account`. */
export default function RegisterPage() {
  redirect(ROUTES.createAccount);
}
