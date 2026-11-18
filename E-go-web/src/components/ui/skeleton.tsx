import { cn } from '@/lib/utils/cn';

/** The shape of a skeleton. */
export type SkeletonRounded = 'sm' | 'md' | 'full';

export interface SkeletonProps {
  className?: string;
  rounded?: SkeletonRounded;
}

const ROUNDED_CLASSES: Record<SkeletonRounded, string> = {
  sm: 'rounded-sm',
  md: 'rounded-md',
  full: 'rounded-full',
};

/**
 * The placeholder of a loading screen.
 *
 * It is decorative: the surrounding screen announces what is loading.
 */
export function Skeleton({ className, rounded = 'md' }: SkeletonProps) {
  return (
    <span
      aria-hidden="true"
      className={cn('block animate-pulse bg-navy-soft', ROUNDED_CLASSES[rounded], className)}
    />
  );
}
