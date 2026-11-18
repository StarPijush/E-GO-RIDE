import type { ReactNode } from 'react';

import { Card } from '@/components/ui/card';
import { EmptyState } from '@/components/ui/empty-state';
import { ErrorState } from '@/components/ui/error-state';
import { Skeleton } from '@/components/ui/skeleton';
import { errorMessage } from '@/lib/domain/labels';
import type { AppError } from '@/lib/domain/types';

export interface ScreenGuardProps {
  /** The data is still loading. */
  loading: boolean;
  /** The data could not be loaded. */
  error: AppError | null;
  /** The retry handler of the error state. */
  onRetry?: () => void;
  /** The list has no entries. */
  empty?: boolean;
  /** The placeholder of the empty list. */
  emptyState?: ReactNode;
  /** The placeholder of the loading state. */
  skeleton?: ReactNode;
  children: ReactNode;
}

/**
 * The loading, error and empty states of a screen.
 *
 * The component is presentational: the screen decides what it renders.
 */
export function ScreenGuard({
  loading,
  error,
  onRetry,
  empty = false,
  emptyState,
  skeleton,
  children,
}: ScreenGuardProps) {
  if (loading) {
    if (skeleton) return <>{skeleton}</>;

    return (
      <div role="status" aria-busy="true" className="flex flex-col gap-4">
        <span className="sr-only">Loading…</span>
        {[0, 1, 2].map((index) => (
          <Card key={index} padding="lg" className="flex flex-col gap-3">
            <Skeleton className="h-5 w-2/5" />
            <Skeleton className="h-4 w-full" />
            <Skeleton className="h-4 w-4/5" />
          </Card>
        ))}
      </div>
    );
  }

  if (error) {
    return <ErrorState message={errorMessage(error)} onRetry={onRetry} />;
  }

  if (empty) {
    return <>{emptyState ?? <EmptyState title="Nothing here yet" />}</>;
  }

  return <>{children}</>;
}
