import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';
import type { ReactNode } from 'react';

import { cn } from '@/lib/utils/cn';

export interface PageHeaderProps {
  title: string;
  description?: string;
  /** A small line above the title. */
  eyebrow?: string;
  /** The page the back link points to. */
  backHref?: string;
  /** The action on the right (a button, a link, ...). */
  action?: ReactNode;
  className?: string;
}

/** The headline of a screen. */
export function PageHeader({
  title,
  description,
  eyebrow,
  backHref,
  action,
  className,
}: PageHeaderProps) {
  return (
    <div
      className={cn(
        'flex flex-col gap-3 sm:flex-row sm:items-start sm:justify-between',
        className,
      )}
    >
      <div className="flex items-start gap-3">
        {backHref ? (
          <Link
            href={backHref}
            aria-label="Go back"
            className={cn(
              'inline-flex size-11 shrink-0 items-center justify-center rounded-full text-navy',
              'transition-colors hover:bg-navy-soft',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
            )}
          >
            <ArrowLeft aria-hidden="true" className="size-5" />
          </Link>
        ) : null}

        <div className="space-y-1">
          {eyebrow ? (
            <p className="text-xs font-semibold uppercase tracking-wider text-muted">{eyebrow}</p>
          ) : null}
          <h1 className="font-display text-2xl font-bold text-navy lg:text-3xl">{title}</h1>
          {description ? <p className="text-sm text-muted">{description}</p> : null}
        </div>
      </div>

      {action ? (
        <div className="flex shrink-0 items-center gap-2 sm:justify-end">{action}</div>
      ) : null}
    </div>
  );
}
