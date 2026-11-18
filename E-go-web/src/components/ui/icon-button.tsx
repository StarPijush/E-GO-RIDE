import type { ButtonHTMLAttributes, ReactNode } from 'react';

import { cn } from '@/lib/utils/cn';

/** The looks of an icon button. */
export type IconButtonVariant = 'ghost' | 'secondary' | 'primary';

/** The size of an icon button. */
export type IconButtonSize = 'sm' | 'md';

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  /** The accessible name of the button (also its tooltip). */
  label: string;
  variant?: IconButtonVariant;
  size?: IconButtonSize;
  children?: ReactNode;
}

const VARIANT_CLASSES: Record<IconButtonVariant, string> = {
  ghost: 'text-navy hover:bg-navy-soft',
  secondary: 'bg-white text-navy border border-line hover:bg-navy-soft',
  primary: 'bg-brand text-navy hover:bg-brand-strong',
};

const SIZE_CLASSES: Record<IconButtonSize, string> = {
  sm: 'size-10',
  md: 'size-11',
};

/**
 * A square, round button that carries an icon.
 *
 * The label is mandatory: an icon alone is never announced, so the button
 * always has an accessible name.
 */
export function IconButton({
  label,
  variant = 'ghost',
  size = 'md',
  className,
  children,
  type = 'button',
  ...props
}: IconButtonProps) {
  return (
    <button
      type={type}
      aria-label={label}
      title={label}
      className={cn(
        'inline-flex items-center justify-center rounded-full',
        'transition-colors',
        'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
        'disabled:cursor-not-allowed disabled:opacity-45',
        VARIANT_CLASSES[variant],
        SIZE_CLASSES[size],
        className,
      )}
      {...props}
    >
      {children}
    </button>
  );
}
