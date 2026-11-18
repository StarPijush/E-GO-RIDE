"use client";

import Link from "next/link";
import { useRouter } from "next/navigation";
import { ArrowLeft } from "lucide-react";

import { Button } from "@/components/ui/button";
import { ROUTES } from "@/lib/config/routes";
import { authCopy } from "@/lib/domain/labels";
import { useAuthStore } from "@/stores/auth-store";

/**
 * The actions of the onboarding.
 *
 * They are client components, the slides themselves stay server components.
 */

/** Skips the onboarding and goes to the login. */
export function OnboardingSkip() {
  const router = useRouter();

  const handleSkip = () => {
    useAuthStore.getState().setOnboardingSeen();
    router.push(ROUTES.login);
  };

  return (
    <button
      type="button"
      onClick={handleSkip}
      className="inline-flex min-h-11 items-center justify-center rounded-pill px-4 text-sm font-semibold text-navy transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
    >
      {authCopy.onboarding.skip}
    </button>
  );
}

export interface OnboardingNextProps {
  /** Where the action leads to. */
  href: string;
  /** The label of the button. */
  label: string;
  /** The last slide: it marks the onboarding as seen. */
  final?: boolean;
}

/** The primary action of a slide. */
export function OnboardingNext({ href, label, final = false }: OnboardingNextProps) {
  const router = useRouter();

  const handleClick = () => {
    if (final) {
      useAuthStore.getState().setOnboardingSeen();
      router.push(ROUTES.login);
      return;
    }
    router.push(href);
  };

  return (
    <Button fullWidth onClick={handleClick}>
      {label}
    </Button>
  );
}

export interface OnboardingBackProps {
  /** The previous onboarding page. */
  href: string;
  /** The arrow is hidden on the first slide. */
  show?: boolean;
}

/** The back arrow of a slide. */
export function OnboardingBack({ href, show = true }: OnboardingBackProps) {
  if (!show) return null;

  return (
    <Link
      href={href}
      aria-label="Go back"
      className="inline-flex size-11 shrink-0 items-center justify-center rounded-full text-navy transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
    >
      <ArrowLeft aria-hidden="true" className="size-5" />
    </Link>
  );
}
