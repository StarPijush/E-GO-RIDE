import Link from "next/link";
import { MapPinOff } from "lucide-react";

import { Logo } from "@/components/shared/logo";
import { EmptyState } from "@/components/ui/empty-state";
import { ROUTES } from "@/lib/config/routes";

/** The page of an unknown address. */
export default function NotFound() {
  return (
    <main id="main" className="flex min-h-dvh flex-col items-center justify-center gap-6 px-4">
      <div className="flex w-full max-w-md flex-col items-center gap-6 text-center">
        <Logo href={null} size="lg" />

        <EmptyState
          icon={<MapPinOff aria-hidden="true" className="size-7" />}
          title="Page not found"
          description="The page you are looking for does not exist or has moved."
          action={
            <div className="flex flex-wrap justify-center gap-3">
              <Link
                href={ROUTES.home}
                className="inline-flex h-12 items-center justify-center rounded-pill bg-brand px-5 font-semibold text-navy transition-colors hover:bg-brand-strong focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
              >
                Back home
              </Link>
              <Link
                href={ROUTES.login}
                className="inline-flex h-12 items-center justify-center rounded-pill border border-line bg-white px-5 font-semibold text-navy transition-colors hover:bg-navy-soft focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2"
              >
                Log in
              </Link>
            </div>
          }
        />
      </div>
    </main>
  );
}
