import { TriangleAlert } from 'lucide-react';

import { Button } from '@/components/ui/button';
import { cn } from '@/lib/utils/cn';

export interface ErrorStateProps {
  /** The headline of the error. */
  title?: string;
  /** What went wrong. */
  message: string;
  /** The retry handler - without it no button is shown. */
  onRetry?: () => void;
  /** The label of the retry button. */
  retryLabel?: string;
  className?: string;
}

/** The placeholder of a screen that could not load its data. */
export function ErrorState({
  title = 'Something went wrong',
  message,
  onRetry,
  retryLabel = 'Try again',
  className,
}: ErrorStateProps) {
  return (
    <div
      role="alert"
      className={cn(
        'flex flex-col items-center justify-center gap-3 py-10 text-center',
        className,
      )}
    >
      <span className="flex size-14 items-center justify-center rounded-full bg-danger-soft text-danger">
        <TriangleAlert aria-hidden="true" className="size-6" />
      </span>

      <h3 className="font-display text-lg font-semibold text-navy">{title}</h3>
      <p className="max-w-sm text-sm text-muted">{message}</p>

      {onRetry ? (
        <Button variant="secondary" onClick={onRetry} className="mt-1">
          {retryLabel}
        </Button>
      ) : null}
    </div>
  );
}
