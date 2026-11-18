'use client';

import { useEffect, useRef } from 'react';

/**
 * The lifecycle of a native `<dialog>`.
 *
 * The dialog shows itself modally (`showModal()` locks the page scroll and
 * traps the focus), closes on Escape and restores the focus of the element
 * that was active before it opened.
 */
export function useNativeDialog(
  open: boolean,
  onClose: () => void,
): React.RefObject<HTMLDialogElement | null> {
  const ref = useRef<HTMLDialogElement | null>(null);

  // Open and close the dialog.
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    if (open && !element.open) {
      // The modal API is missing in some environments (jsdom) - the dialog
      // then opens as an ordinary (non modal) element instead of breaking
      // the page.
      if (typeof element.showModal === 'function') {
        element.showModal();
      } else {
        element.setAttribute('open', '');
      }
    } else if (!open && element.open) {
      if (typeof element.close === 'function') {
        element.close();
      } else {
        element.removeAttribute('open');
      }
    }
  }, [open]);

  // Escape closes the dialog - but the parent decides (it may refuse).
  useEffect(() => {
    const element = ref.current;
    if (!element) return;

    const handleCancel = (event: Event) => {
      event.preventDefault();
      onClose();
    };

    element.addEventListener('cancel', handleCancel);
    return () => element.removeEventListener('cancel', handleCancel);
  }, [onClose]);

  // Give the focus back to the element that had it before.
  useEffect(() => {
    if (!open) return;

    const previouslyFocused = document.activeElement as HTMLElement | null;
    return () => {
      previouslyFocused?.focus?.();
    };
  }, [open]);

  return ref;
}
