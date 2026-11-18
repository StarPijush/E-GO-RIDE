import { cn } from '@/lib/utils/cn';

/** The size of a spinner. */
export type SpinnerSize = 'sm' | 'md' | 'lg';

export interface SpinnerProps {
  size?: SpinnerSize;
  /** The text a screen reader announces. Without it the spinner is hidden. */
  label?: string;
  className?: string;
}

const SIZE_CLASSES: Record<SpinnerSize, string> = {
  sm: 'size-4 border-2',
  md: 'size-6 border-2',
  lg: 'size-8 border-[3px]',
};

/**
 * The loading indicator of E-GO Web.
 *
 * The animation is disabled by the global `prefers-reduced-motion` rule.
 */
export function Spinner({ size = 'md', label, className }: SpinnerProps) {
  return (
    <>
      <span
        aria-hidden={label ? undefined : true}
        className={cn(
          'inline-block animate-spin rounded-full border-navy/20 border-t-navy',
          SIZE_CLASSES[size],
          className,
        )}
      />
      {label ? <span className="sr-only">{label}</span> : null}
    </>
  );
}
