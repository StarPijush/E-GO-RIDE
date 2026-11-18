"use client";

import { Container } from "@/components/layout/container";
import { ErrorState } from "@/components/ui/error-state";

/**
 * The error boundary of the protected routes.
 *
 * The booking data lives in the browser, so a broken screen never costs the
 * passenger a ride.
 */
export default function AppError({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return (
    <Container className="py-10">
      <ErrorState
        title="This page hit a snag"
        message="Something went wrong while loading this page. Your booking data is safe."
        onRetry={reset}
      />
    </Container>
  );
}
