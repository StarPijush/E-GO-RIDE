import { Card, Skeleton } from "@/components/ui";

/** The placeholder while the details of a ride load. */
export default function RideDetailsLoading() {
  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <div className="mb-5 flex flex-col gap-2">
        <Skeleton className="h-8 w-40" />
        <Skeleton className="h-4 w-24" />
      </div>

      <div className="flex flex-col gap-3">
        <Card padding="lg" className="flex flex-col gap-3">
          <Skeleton className="h-5 w-1/3" />
          <Skeleton className="h-4 w-2/3" />
          <Skeleton className="h-4 w-1/2" />
        </Card>

        <Card padding="lg" className="flex flex-col gap-3">
          <Skeleton className="h-4 w-full" />
          <Skeleton className="h-4 w-4/5" />
          <Skeleton className="h-4 w-3/5" />
        </Card>

        <Card padding="lg" className="flex flex-col gap-3">
          <Skeleton className="h-12 w-12 rounded-full" />
          <Skeleton className="h-4 w-1/2" />
        </Card>
      </div>
    </div>
  );
}
