'use client';

import Link from 'next/link';
import type { ReactNode } from 'react';
import { ChevronRight, MapPin } from 'lucide-react';

import type { Place } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface PlaceRowProps {
  /** The place of the row. */
  place: Place;
  /** Called when the row is pressed (without a `href`). */
  onSelect?: (place: Place) => void;
  /** A link target - the row becomes a link then. */
  href?: string;
  /** Replaces the chevron. */
  trailing?: ReactNode;
  /** Replaces the address. */
  subtitle?: string;
  /** Replaces the leading icon. */
  icon?: ReactNode;
}

/**
 * One place of a list.
 *
 * The row is either a link or a real button - never a `<div>` with a click
 * handler, and it never nests interactive elements.
 */
export function PlaceRow({
  place,
  onSelect,
  href,
  trailing,
  subtitle,
  icon,
}: PlaceRowProps) {
  const content = (
    <>
      <span className="flex size-10 shrink-0 items-center justify-center rounded-full bg-navy-soft text-navy">
        {icon ?? <MapPin aria-hidden="true" className="size-5" />}
      </span>

      <span className="flex min-w-0 flex-1 flex-col">
        <span className="truncate text-sm font-semibold text-navy">{place.label}</span>
        <span className="line-clamp-1 text-xs text-muted">{subtitle ?? place.address}</span>
      </span>

      {trailing ?? <ChevronRight aria-hidden="true" className="size-5 shrink-0 text-muted" />}
    </>
  );

  const className = cn(
    'flex min-h-14 w-full items-center gap-3 px-2 py-2 text-left',
    'transition-colors hover:bg-navy-soft',
    'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
  );

  if (href) {
    return (
      <Link href={href} className={className}>
        {content}
      </Link>
    );
  }

  return (
    <button type="button" onClick={() => onSelect?.(place)} className={className}>
      {content}
    </button>
  );
}
