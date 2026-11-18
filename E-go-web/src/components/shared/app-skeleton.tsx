import { Card } from '@/components/ui/card';
import { Skeleton } from '@/components/ui/skeleton';

/**
 * The placeholder of a screen that is not ready yet.
 *
 * It shows the shape of the page (a header and three cards), so the layout
 * does not jump when the data arrives.
 */
export function AppSkeleton() {
  return (
    <div role="status" aria-busy="true" className="min-h-screen bg-surface">
      <span className="sr-only">Loading…</span>

      <div className="mx-auto w-full max-w-[1200px] px-4 py-6 md:px-6 lg:px-8">
        <div className="mb-6 flex items-center justify-between gap-4">
          <Skeleton className="h-9 w-32 rounded-pill" />
          <Skeleton className="h-9 w-24 rounded-pill" />
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <Card padding="lg" className="flex flex-col gap-3">
            <Skeleton className="h-5 w-2/5" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-4/5" />
          </Card>

          <Card padding="lg" className="flex flex-col gap-3">
            <Skeleton className="h-5 w-3/5" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-3/5" />
          </Card>

          <Card padding="lg" className="flex flex-col gap-3 md:col-span-2">
            <Skeleton className="h-5 w-1/4" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-2/3" />
          </Card>
        </div>
      </div>
    </div>
  );
}
