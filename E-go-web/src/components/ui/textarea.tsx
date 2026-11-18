'use client';

import { forwardRef, useId, type TextareaHTMLAttributes } from 'react';

import { Field } from '@/components/ui/field';
import { cn } from '@/lib/utils/cn';

export interface TextareaProps extends TextareaHTMLAttributes<HTMLTextAreaElement> {
  /** The label of the textarea. */
  label?: string;
  /** The validation error of the textarea. */
  error?: string;
  /** The help text under the textarea. */
  hint?: string;
  /** The class of the wrapper (the label, the textarea and the messages). */
  containerClassName?: string;
}

/** A multi line input with its label, its hint and its error. */
export const Textarea = forwardRef<HTMLTextAreaElement, TextareaProps>(function Textarea(
  { label, error, hint, containerClassName, className, id, rows = 4, ...props },
  ref,
) {
  const generatedId = useId();
  const textareaId = id ?? generatedId;
  const errorId = `${textareaId}-error`;
  const hintId = `${textareaId}-hint`;
  const describedBy =
    [hint ? hintId : null, error ? errorId : null].filter(Boolean).join(' ') || undefined;

  return (
    <Field
      label={label}
      htmlFor={textareaId}
      hint={hint}
      error={error}
      required={props.required}
      className={containerClassName}
    >
      <textarea
        ref={ref}
        id={textareaId}
        rows={rows}
        aria-invalid={!!error}
        aria-describedby={describedBy}
        className={cn(
          'min-h-28 w-full rounded-field border bg-white px-4 py-3 text-base text-navy',
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

Textarea.displayName = 'Textarea';
