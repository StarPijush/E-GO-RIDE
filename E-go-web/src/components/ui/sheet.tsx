'use client';

import { useId, type ReactNode } from 'react';
import { X } from 'lucide-react';

import { IconButton } from '@/components/ui/icon-button';
import { useNativeDialog } from '@/components/ui/use-native-dialog';
import { cn } from '@/lib/utils/cn';

/** The side a sheet slides in from. */
export type SheetSide = 'bottom' | 'right';

export interface SheetProps {
  /** The sheet is open. */
  open: boolean;
  /** Called when the sheet wants to close. */
  onClose: () => void;
  title: string;
  description?: string;
  footer?: ReactNode;
  /** The side the sheet comes from. */
  side?: SheetSide;
  children?: ReactNode;
}

/**
 * A sheet on a native `<dialog>` element.
 *
 * The bottom sheet is the mobile pattern of the app, the right sheet the
 * desktop one.
 */
export function Sheet({
  open,
  onClose,
  title,
  description,
  footer,
  side = 'bottom',
  children,
}: SheetProps) {
  const sheetRef = useNativeDialog(open, onClose);
  const titleId = useId();
  const descriptionId = useId();

  return (
    <dialog
      ref={sheetRef}
      aria-labelledby={titleId}
      aria-describedby={description ? descriptionId : undefined}
      className={cn(
        'border-line bg-white p-0 text-navy shadow-float',
        side === 'bottom' &&
          'fixed inset-x-0 bottom-0 m-0 w-full max-w-none rounded-b-none rounded-t-[24px] max-h-[85dvh] overflow-y-auto',
        side === 'right' &&
          'fixed inset-y-0 right-0 m-0 h-dvh max-h-dvh w-full max-w-md rounded-none overflow-y-auto',
      )}
    >
      {side === 'bottom' ? (
        <span
          aria-hidden="true"
          className="mx-auto mt-3 block h-1 w-10 rounded-full bg-navy-soft"
        />
      ) : null}

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
