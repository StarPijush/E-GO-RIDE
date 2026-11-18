import type { HTMLAttributes } from 'react';

import { cn } from '@/lib/utils/cn';

/** The element a card is rendered as. */
export type CardElement = 'div' | 'section' | 'article';

/** The inner spacing of a card. */
export type CardPadding = 'none' | 'sm' | 'md' | 'lg';

export interface CardProps extends HTMLAttributes<HTMLDivElement> {
  as?: CardElement;
  padding?: CardPadding;
  /** The card casts a shadow (use it for the cards that float above the page). */
  elevated?: boolean;
}

const PADDING_CLASSES: Record<CardPadding, string> = {
  none: '',
  sm: 'p-3',
  md: 'p-4',
  lg: 'p-6',
};

/** The white surface every screen of E-GO Web is built of. */
export function Card({
  as = 'div',
  padding = 'md',
  elevated = false,
  className,
  children,
  ...props
}: CardProps) {
  const Tag = as;

  return (
    <Tag
      className={cn(
        'rounded-card border border-line bg-white',
        PADDING_CLASSES[padding],
        elevated && 'shadow-card',
        className,
      )}
      {...props}
    >
      {children}
    </Tag>
  );
}
