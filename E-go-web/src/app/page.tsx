"use client";

import Image from "next/image";
import { useRouter } from "next/navigation";
import { useEffect } from "react";

import { Spinner } from "@/components/ui/spinner";
import { ROUTES } from "@/lib/config/routes";
import { authCopy } from "@/lib/domain/labels";
import { useAuthStore } from "@/stores/auth-store";

/**
 * The splash gate.
 *
 * It waits for the persisted session and then sends the passenger to the
 * right place: the home screen with a session, the login with a seen
 * onboarding, otherwise the first onboarding slide.
 */
export default function SplashPage() {
  const router = useRouter();

  const hasHydrated = useAuthStore((state) => state.hasHydrated);
  const session = useAuthStore((state) => state.session);
  const onboardingSeen = useAuthStore((state) => state.onboardingSeen);

  useEffect(() => {
    if (!hasHydrated) return;

    router.replace(
      session ? ROUTES.home : onboardingSeen ? ROUTES.login : ROUTES.onboarding,
    );
  }, [hasHydrated, onboardingSeen, router, session]);

  return (
    <main
      id="main"
      className="relative flex min-h-dvh flex-col items-center justify-center gap-6 overflow-hidden bg-navy px-6 text-center"
    >
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -top-32 left-1/2 h-96 w-96 -translate-x-1/2 rounded-full bg-brand/10 blur-3xl"
      />
      <div aria-hidden="true" className="absolute inset-x-0 top-0 h-1 bg-brand" />

      <div className="relative flex w-full max-w-xs flex-col items-center gap-5 rounded-card bg-white p-7 shadow-float">
        <Image
          src="/branding/ego_logo_primary.png"
          alt="E-GO"
          width={160}
          height={160}
          priority
          className="size-28 object-contain"
        />

        <Image
          src="/branding/ego_logo_wordmark.png"
          alt=""
          width={432}
          height={130}
          className="h-7 w-auto object-contain"
        />

        <h1 className="sr-only">E-GO</h1>

        <Spinner size="md" label="Loading E-GO" />
      </div>

      <p className="relative text-sm font-medium tracking-wide text-white/70">
        {authCopy.appTagline}
      </p>
    </main>
  );
}
