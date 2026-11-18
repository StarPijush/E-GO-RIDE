import { Card, Skeleton } from "@/components/ui";

/** The placeholder while the history loads. */
export default function MyRidesLoading() {
  return (
    <div className="mx-auto w-full max-w-3xl px-4 py-5 sm:px-6 lg:px-8">
      <div className="mb-5 flex flex-col gap-2">
        <Skeleton className="h-8 w-40" />
        <Skeleton className="h-4 w-64" />
      </div>

      <Skeleton className="mb-4 h-11 w-full rounded-pill" />

      <div className="grid gap-3 md:grid-cols-2">
        {[0, 1, 2].map((index) => (
          <Card key={index} padding="md" className="flex flex-col gap-3">
            <Skeleton className="h-5 w-1/3" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-4/5" />
          </Card>
        ))}
      </div>
    </div>
  );
}
