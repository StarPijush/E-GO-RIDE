'use client';

import { forwardRef, useId, type InputHTMLAttributes, type ReactNode } from 'react';

import { Field } from '@/components/ui/field';
import { cn } from '@/lib/utils/cn';

export interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  /** The label of the input (a node, so a badge may be added). */
  label?: ReactNode;
  /** The validation error of the input. */
  error?: string;
  /** The help text under the input. */
  hint?: string;
  /** The class of the wrapper (the label, the input and the messages). */
  containerClassName?: string;
}

/**
 * A text input with its label, its hint and its error.
 *
 * The input keeps its own id when none is given and points at the hint and
 * the error through `aria-describedby`.
 */
export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { label, error, hint, containerClassName, className, id, ...props },
  ref,
) {
  const generatedId = useId();
  const inputId = id ?? generatedId;
  const errorId = `${inputId}-error`;
  const hintId = `${inputId}-hint`;
  const describedBy =
    [hint ? hintId : null, error ? errorId : null].filter(Boolean).join(' ') || undefined;

  return (
    <Field
      label={label}
      htmlFor={inputId}
      hint={hint}
      error={error}
      required={props.required}
      className={containerClassName}
    >
      <input
        ref={ref}
        id={inputId}
        aria-invalid={!!error}
        aria-describedby={describedBy}
        className={cn(
          'h-[52px] w-full rounded-field border bg-white px-4 text-base text-navy',
          'placeholder:text-muted/70',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy',
          'disabled:bg-surface disabled:text-muted',
          error ? 'border-danger' : 'border-line',
          className,
        )}
        {...props}
      />
    </Field>
  );
});

Input.displayName = 'Input';
