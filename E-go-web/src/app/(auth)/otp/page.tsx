import type { Metadata } from "next";
import { redirect } from "next/navigation";

import { OtpForm } from "@/components/auth/otp-form";
import { ROUTE_METADATA, ROUTES } from "@/lib/config/routes";
import { normalizePhoneDigits } from "@/lib/utils/phone";
import { sanitizeReturnTo } from "@/lib/utils/return-to";

const meta = ROUTE_METADATA.otp;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

/** The first value of a search parameter. */
function first(value: string | string[] | undefined): string | undefined {
  return Array.isArray(value) ? value[0] : value;
}

export default async function OtpPage({
  searchParams,
}: {
  searchParams: Promise<{
    phone?: string | string[];
    mode?: string | string[];
    sent?: string | string[];
    returnTo?: string | string[];
  }>;
}) {
  const params = await searchParams;

  const digits = normalizePhoneDigits(first(params.phone) ?? "");
  if (!digits) redirect(ROUTES.login);

  const mode = first(params.mode) === "register" ? "register" : "login";
  const sent = first(params.sent) === "1";
  const returnTo = sanitizeReturnTo(first(params.returnTo));

  return <OtpForm phone={digits} mode={mode} sent={sent} returnTo={returnTo} />;
}
