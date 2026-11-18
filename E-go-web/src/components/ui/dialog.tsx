'use client';

import { useId, type MouseEvent, type ReactNode } from 'react';
import { X } from 'lucide-react';

import { IconButton } from '@/components/ui/icon-button';
import { useNativeDialog } from '@/components/ui/use-native-dialog';
import { cn } from '@/lib/utils/cn';

/** The width of a dialog. */
export type DialogSize = 'sm' | 'md' | 'lg';

export interface DialogProps {
  /** The dialog is open. */
  open: boolean;
  /** Called when the dialog wants to close. */
  onClose: () => void;
  title: string;
  description?: string;
  footer?: ReactNode;
  size?: DialogSize;
  children?: ReactNode;
}

const SIZE_CLASSES: Record<DialogSize, string> = {
  sm: 'max-w-sm',
  md: 'max-w-md',
  lg: 'max-w-lg',
};

/**
 * A modal dialog on a native `<dialog>` element.
 *
 * The native element brings the focus trap, the Escape key and the locked
 * page scroll - no scroll hack needed.
 */
export function Dialog({
  open,
  onClose,
  title,
  description,
  footer,
  size = 'md',
  children,
}: DialogProps) {
  const dialogRef = useNativeDialog(open, onClose);
  const titleId = useId();
  const descriptionId = useId();

  const handleBackdropClick = (event: MouseEvent<HTMLDialogElement>) => {
    // A click on the backdrop hits the dialog element itself.
    if (event.target === dialogRef.current) onClose();
  };

  return (
    <dialog
      ref={dialogRef}
      aria-labelledby={titleId}
      aria-describedby={description ? descriptionId : undefined}
      onClick={handleBackdropClick}
      className={cn(
        'w-[calc(100%-2rem)] rounded-card border border-line bg-white p-0 text-navy shadow-float',
        SIZE_CLASSES[size],
      )}
    >
      <div className="flex items-start justify-between gap-4 border-b border-line p-4">
        <div className="flex flex-col gap-1">
          <h2 id={titleId} className="font-display text-lg font-semibold">
            {title}
          </h2>
          {description ? (
            <p id={descriptionId} className="text-sm text-muted">
              {description}
            </p>
          ) : null}
        </div>
        <IconButton label="Close" size="sm" onClick={onClose}>
          <X aria-hidden="true" className="size-5" />
        </IconButton>
      </div>

      <div className="p-4">{children}</div>

      {footer ? (
        <div className="flex items-center justify-end gap-2 border-t border-line p-4">{footer}</div>
      ) : null}
    </dialog>
  );
}
