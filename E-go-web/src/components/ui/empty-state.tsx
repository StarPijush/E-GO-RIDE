import type { ReactNode } from 'react';

import { cn } from '@/lib/utils/cn';

export interface EmptyStateProps {
  /** The icon of the empty state (a circle carries it). */
  icon?: ReactNode;
  title: string;
  description?: string;
  /** The call to action under the description. */
  action?: ReactNode;
  className?: string;
}

/** The placeholder of a list that has nothing to show yet. */
export function EmptyState({
  icon,
  title,
  description,
  action,
  className,
}: EmptyStateProps) {
  return (
    <div
      className={cn(
        'flex flex-col items-center justify-center gap-3 py-10 text-center',
        className,
      )}
    >
      {icon ? (
        <span className="flex size-14 items-center justify-center rounded-full bg-navy-soft text-navy">
          {icon}
        </span>
      ) : null}

      <h3 className="font-display text-lg font-semibold text-navy">{title}</h3>

      {description ? <p className="max-w-sm text-sm text-muted">{description}</p> : null}

      {action ? <div className="mt-1">{action}</div> : null}
    </div>
  );
}
