'use client';

import { useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';

import { IconButton, Input, type InputProps } from '@/components/ui';
import { cn } from '@/lib/utils/cn';

export interface PasswordInputProps extends Omit<InputProps, 'type'> {
  /** The accessible name of the button that shows the password. */
  showLabel?: string;
  /** The accessible name of the button that hides the password. */
  hideLabel?: string;
}

/**
 * A password field with a show/hide button.
 *
 * The button sits inside the field (absolutely positioned), so the layout
 * never changes while the password is toggled.
 */
export function PasswordInput({
  showLabel = 'Show password',
  hideLabel = 'Hide password',
  className,
  disabled,
  ...props
}: PasswordInputProps) {
  const [visible, setVisible] = useState(false);

  return (
    <div className="relative">
      <Input
        {...props}
        type={visible ? 'text' : 'password'}
        className={cn('pr-14', className)}
        disabled={disabled}
      />

      <IconButton
        label={visible ? hideLabel : showLabel}
        size="sm"
        disabled={disabled}
        onClick={() => setVisible((current) => !current)}
        className="absolute right-2 top-8"
      >
        {visible ? (
          <EyeOff aria-hidden="true" className="size-4" />
        ) : (
          <Eye aria-hidden="true" className="size-4" />
        )}
      </IconButton>
    </div>
  );
}
