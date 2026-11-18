import type { ReactNode } from 'react';

import { cn } from '@/lib/utils/cn';

export interface FieldProps {
  /** The label of the control. */
  label?: ReactNode;
  /** The id of the control the label belongs to. */
  htmlFor?: string;
  /** A short help text under the control. */
  hint?: string;
  /** The validation error of the control. */
  error?: string;
  /** Marks the control as required (the asterisk is decorative). */
  required?: boolean;
  className?: string;
  children: ReactNode;
  /** `fieldset` turns the field into a group of options. */
  as?: 'div' | 'fieldset';
  /** The legend of a group of options. */
  legend?: string;
}

/**
 * The label, the hint and the error of a form control.
 *
 * The component is presentational: the caller owns the control and passes
 * the ids of the hint and the error through `aria-describedby`
 * (`{htmlFor}-hint` and `{htmlFor}-error`).
 */
export function Field({
  label,
  htmlFor,
  hint,
  error,
  required = false,
  className,
  children,
  as = 'div',
  legend,
}: FieldProps) {
  const Tag = as;
  const errorId = htmlFor ? `${htmlFor}-error` : undefined;
  const hintId = htmlFor ? `${htmlFor}-hint` : undefined;
  const isGroup = as === 'fieldset' && legend !== undefined;

  return (
    <Tag className={cn('flex flex-col gap-1.5', className)}>
      {isGroup ? (
        <legend className="text-sm font-medium text-navy">
          {legend}
          {required ? (
            <span aria-hidden="true" className="text-danger">
              {' *'}
            </span>
          ) : null}
        </legend>
      ) : label ? (
        <label htmlFor={htmlFor} className="text-sm font-medium text-navy">
          {label}
          {required ? (
            <span aria-hidden="true" className="text-danger">
              {' *'}
            </span>
          ) : null}
        </label>
      ) : null}

      {children}

      {hint ? (
        <p id={hintId} className="text-sm text-muted">
          {hint}
        </p>
      ) : null}

      {error ? (
        <p id={errorId} role="alert" className="text-sm text-danger">
          {error}
        </p>
      ) : null}
    </Tag>
  );
}
