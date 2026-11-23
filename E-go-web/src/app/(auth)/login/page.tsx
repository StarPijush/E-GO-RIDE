import type { Metadata } from "next";

import { LoginForm } from "@/components/auth/login-form";
import { getDemoLogin } from "@/lib/config/demo-server";
import { ROUTE_METADATA } from "@/lib/config/routes";
import { sanitizeReturnTo } from "@/lib/utils/return-to";

const meta = ROUTE_METADATA.login;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default async function LoginPage({
  searchParams,
}: {
  searchParams: Promise<{ returnTo?: string | string[] }>;
}) {
  const params = await searchParams;
  const raw = Array.isArray(params.returnTo) ? params.returnTo[0] : params.returnTo;

  return <LoginForm returnTo={sanitizeReturnTo(raw)} demo={getDemoLogin()} />;
}
