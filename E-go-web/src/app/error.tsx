"use client";

import { ErrorState } from "@/components/ui/error-state";

/** The error boundary of the public routes. */
export default function RootError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <main id="main" className="flex min-h-dvh items-center justify-center px-4">
      <ErrorState
        title="This page hit a snag"
        message="Something went wrong while loading this page. Please try again."
        onRetry={reset}
      />
    </main>
  );
}
