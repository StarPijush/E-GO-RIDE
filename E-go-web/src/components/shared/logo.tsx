import Image from 'next/image';
import Link from 'next/link';

import { authCopy } from '@/lib/domain/labels';
import { cn } from '@/lib/utils/cn';

/** The size of the logo. */
export type LogoSize = 'sm' | 'md' | 'lg';

export interface LogoProps {
  /** The link of the logo. `null` renders a plain element (no navigation). */
  href?: string | null;
  size?: LogoSize;
  /** Shows the tagline under the wordmark. */
  showTagline?: boolean;
  className?: string;
}

const IMAGE_CLASSES: Record<LogoSize, string> = {
  sm: 'h-7 w-auto',
  md: 'h-8 w-auto',
  lg: 'h-10 w-auto',
};

/**
 * The wordmark of E-GO.
 *
 * The wordmark is an official asset (`/branding/ego_logo_wordmark.png`), so
 * the brand stays exactly as it was designed - no drawn substitute.
 */
export function Logo({ href = '/', size = 'md', showTagline = false, className }: LogoProps) {
  const content = (
    <span className="flex flex-col items-start gap-1">
      <Image
        src="/branding/ego_logo_wordmark.png"
        alt="E-GO"
        width={432}
        height={130}
        className={cn('object-contain', IMAGE_CLASSES[size])}
      />
      {showTagline ? <span className="text-xs text-muted">{authCopy.appTagline}</span> : null}
    </span>
  );

  if (href === null) {
    return <div className={cn('inline-flex items-center', className)}>{content}</div>;
  }

  return (
    <Link
      href={href}
      aria-label="E-GO home"
      className={cn(
        'inline-flex items-center rounded-card',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
        className,
      )}
    >
      {content}
    </Link>
  );
}
