import { Star } from 'lucide-react';

import { cn } from '@/lib/utils/cn';

export interface RatingStarsProps {
  /** The number of stars (1 - 5). */
  stars: number;
  /** The size of the stars. */
  size?: 'sm' | 'md';
  className?: string;
  /** Renders the screen reader text ("n out of 5 stars"). */
  label?: boolean;
}

const SIZE_CLASSES: Record<'sm' | 'md', string> = {
  sm: 'size-4',
  md: 'size-5',
};

/** The stars of a rating. */
export function RatingStars({ stars, size = 'md', className, label = true }: RatingStarsProps) {
  return (
    <span className={cn('inline-flex items-center gap-0.5', className)}>
      {label ? <span className="sr-only">{stars} out of 5 stars</span> : null}

      {[1, 2, 3, 4, 5].map((value) => (
        <Star
          key={value}
          aria-hidden="true"
          className={cn(SIZE_CLASSES[size], value <= stars ? 'fill-brand text-navy' : 'text-navy-soft')}
        />
      ))}
    </span>
  );
}
