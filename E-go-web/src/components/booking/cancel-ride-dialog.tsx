'use client';

import { useState } from 'react';

import { Button, Dialog } from '@/components/ui';
import { cancellationReasonOptions } from '@/lib/domain/labels';
import type { CancellationReason } from '@/lib/domain/types';

export interface CancelRideDialogProps {
  /** The dialog is open. */
  open: boolean;
  /** Called when the dialog closes. */
  onClose: () => void;
  /** Called with the chosen reason. The parent closes the dialog on success. */
  onConfirm: (reason: CancellationReason) => void | Promise<void>;
  /** The cancellation is running. */
  pending?: boolean;
  title?: string;
  description?: string;
}

/**
 * The dialog that asks why a ride is cancelled.
 *
 * The dialog stays open when the cancellation fails, so the passenger can
 * try again or keep the ride.
 */
export function CancelRideDialog({
  open,
  onClose,
  onConfirm,
  pending = false,
  title = 'Cancel ride?',
  description = 'Are you sure you want to cancel this ride?',
}: CancelRideDialogProps) {
  const [reason, setReason] = useState<CancellationReason>('changed_plan');

  const handleClose = () => {
    setReason('changed_plan');
    onClose();
  };

  return (
    <Dialog
      open={open}
      onClose={handleClose}
      title={title}
      description={description}
      footer={
        <>
          <Button variant="secondary" onClick={handleClose} disabled={pending}>
            Keep ride
          </Button>
          <Button variant="danger" onClick={() => onConfirm(reason)} loading={pending} disabled={pending}>
            Cancel ride
          </Button>
        </>
      }
    >
      <fieldset className="flex flex-col gap-1">
        <legend className="mb-2 text-sm font-medium text-navy">Why are you cancelling?</legend>

        {cancellationReasonOptions.map((option) => (
          <label
            key={option.value}
            className="flex min-h-14 cursor-pointer items-center gap-3 rounded-field px-2 transition-colors hover:bg-navy-soft focus-within:ring-2 focus-within:ring-navy focus-within:ring-offset-2"
          >
            <input
              type="radio"
              name="cancellation-reason"
              value={option.value}
              checked={reason === option.value}
              onChange={() => setReason(option.value)}
              className="size-4 accent-navy"
            />
            <span className="text-sm text-navy">{option.label}</span>
          </label>
        ))}
      </fieldset>

      <p className="mt-4 text-xs text-muted">
        You can cancel free of charge while searching or before the trip starts.
      </p>
    </Dialog>
  );
}
