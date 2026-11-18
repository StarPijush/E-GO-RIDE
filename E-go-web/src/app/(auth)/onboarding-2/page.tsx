import type { Metadata } from "next";

import { OnboardingSlide } from "@/components/auth/onboarding-slide";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.onboarding2;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function OnboardingTwoPage() {
  return <OnboardingSlide index={1} />;
}
