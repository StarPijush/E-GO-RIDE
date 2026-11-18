import { Info } from 'lucide-react';

import { isDemoAuthEnabled } from '@/lib/config/env';
import { cn } from '@/lib/utils/cn';

export interface DemoBannerProps {
  className?: string;
}

/**
 * The notice that the app is a simulation.
 *
 * It is only rendered while demo mode is enabled (a build time flag), so a
 * production build never shows it.
 */
export function DemoBanner({ className }: DemoBannerProps) {
  if (!isDemoAuthEnabled) return null;

  return (
    <div
      role="note"
      className={cn(
        'inline-flex items-center gap-2 rounded-field bg-warning-soft px-3 py-2 text-xs font-medium text-warning',
        className,
      )}
    >
      <Info aria-hidden="true" className="size-4 shrink-0" />
      <span>
        Demo mode - rides, drivers, SMS and payments are simulated. No real driver is assigned.
      </span>
    </div>
  );
}
