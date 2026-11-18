'use client';

import { useEffect, useMemo, useRef, type ClipboardEvent, type KeyboardEvent } from 'react';

import { cn } from '@/lib/utils/cn';

export interface OtpInputProps {
  /** The digits of the code (without spaces). */
  value: string;
  /** Called with the joined digits after every change. */
  onChange: (value: string) => void;
  /** The number of digits. */
  length?: number;
  disabled?: boolean;
  /** The validation error of the code. */
  error?: string;
  autoFocus?: boolean;
  /** Called when every digit is filled. */
  onComplete?: (value: string) => void;
  /** The accessible name of the group. */
  label?: string;
}

/**
 * The one time password input.
 *
 * Every digit has its own field, so a phone number can be typed digit by
 * digit (or pasted at once). Only digits are accepted, the fields move with
 * the arrow keys and the backspace.
 */
export function OtpInput({
  value,
  onChange,
  length = 6,
  disabled = false,
  error,
  autoFocus = false,
  onComplete,
  label = 'One-time password',
}: OtpInputProps) {
  const inputs = useRef<Array<HTMLInputElement | null>>([]);
  const errorId = 'otp-input-error';

  /** The digits of the code, one slot per field. */
  const digits = useMemo(() => {
    const chars = value.replace(/\D/g, '').split('').slice(0, length);
    return Array.from({ length }, (_unused, index) => chars[index] ?? '');
  }, [value, length]);

  useEffect(() => {
    if (autoFocus) inputs.current[0]?.focus();
  }, [autoFocus]);

  /** The digits as they would be stored. */
  const joined = (slots: string[]): string => slots.join('').slice(0, length);

  const handleChange = (index: number, raw: string) => {
    if (disabled) return;

    const digit = raw.replace(/\D/g, '').slice(0, 1);
    const slots = [...digits];
    slots[index] = digit;

    const next = joined(slots);
    onChange(next);

    if (digit) {
      const nextIndex = Math.min(index + 1, length - 1);
      inputs.current[nextIndex]?.focus();
    }
    if (next.length === length) onComplete?.(next);
  };

  const handleKeyDown = (index: number, event: KeyboardEvent<HTMLInputElement>) => {
    if (disabled) return;

    if (event.key === 'Backspace') {
      event.preventDefault();
      const slots = [...digits];
      if (slots[index]) {
        slots[index] = '';
        onChange(joined(slots));
        return;
      }
      if (index > 0) {
        slots[index - 1] = '';
        onChange(joined(slots));
        inputs.current[index - 1]?.focus();
      }
      return;
    }

    if (event.key === 'ArrowLeft' && index > 0) {
      event.preventDefault();
      inputs.current[index - 1]?.focus();
      return;
    }

    if (event.key === 'ArrowRight' && index < length - 1) {
      event.preventDefault();
      inputs.current[index + 1]?.focus();
    }
  };

  const handlePaste = (event: ClipboardEvent<HTMLInputElement>) => {
    if (disabled) return;
    event.preventDefault();

    const pasted = event.clipboardData.getData('text').replace(/\D/g, '');
    if (pasted.length === 0) return;

    const slots = Array.from({ length }, (_unused, index) => pasted[index] ?? '');
    const next = joined(slots);
    onChange(next);

    if (next.length === length) {
      onComplete?.(next);
      return;
    }
    inputs.current[Math.min(pasted.length, length - 1)]?.focus();
  };

  return (
    <div role="group" aria-label={label} aria-describedby={error ? errorId : undefined}>
      <div className="flex items-center justify-center gap-2">
        {digits.map((digit, index) => (
          <input
            key={index}
            ref={(element) => {
              inputs.current[index] = element;
            }}
            type="text"
            inputMode="numeric"
            autoComplete={index === 0 ? 'one-time-code' : 'off'}
            pattern="[0-9]*"
            maxLength={1}
            value={digit}
            disabled={disabled}
            onChange={(event) => handleChange(index, event.target.value)}
            onKeyDown={(event) => handleKeyDown(index, event)}
            onPaste={handlePaste}
            aria-label={`Digit ${index + 1} of ${length}`}
            aria-invalid={error ? true : undefined}
            className={cn(
              'size-12 rounded-field border bg-white text-center text-xl font-semibold text-navy',
              'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy',
              'disabled:bg-surface disabled:text-muted',
              error ? 'border-danger' : 'border-line',
            )}
          />
        ))}
      </div>

      {error ? (
        <p id={errorId} role="alert" className="mt-2 text-center text-sm text-danger">
          {error}
        </p>
      ) : null}
    </div>
  );
}
