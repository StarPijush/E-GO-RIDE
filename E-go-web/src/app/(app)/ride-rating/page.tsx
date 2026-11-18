import type { Metadata } from "next";
import { Suspense } from "react";

import { RatingScreen } from "@/components/booking/rating-screen";
import { AppSkeleton } from "@/components/shared/app-skeleton";
import { ROUTE_METADATA } from "@/lib/config/routes";

const meta = ROUTE_METADATA.rideRating;

export const metadata: Metadata = {
  title: meta.title,
  description: meta.description,
};

export default function RideRatingPage() {
  // `useSearchParams` needs a Suspense boundary when the page is prerendered.
  return (
    <Suspense fallback={<AppSkeleton />}>
      <RatingScreen />
    </Suspense>
  );
}
