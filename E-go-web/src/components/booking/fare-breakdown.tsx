import { FARE_RULES, formatINR } from '@/lib/domain/fare';
import type { FareBreakdown } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface FareBreakdownRowsProps {
  /** The stored fare - the rows never calculate anything themselves. */
  fare: FareBreakdown;
  /** Adds the payment row. */
  showPayment?: boolean;
  /** The label of the payment row. */
  paymentLabel?: string;
  /** The label of the total row. */
  totalLabel?: string;
  className?: string;
}

/** The rows of a fare estimate. */
export function FareBreakdownRows({
  fare,
  showPayment = false,
  paymentLabel = 'Cash',
  totalLabel = 'Total estimate',
  className,
}: FareBreakdownRowsProps) {
  const rate = FARE_RULES[fare.vehicle].distanceRatePerKm;

  return (
    <dl aria-label="Fare breakdown" className={cn('flex flex-col gap-2', className)}>
      <div className="flex items-center justify-between gap-3">
        <dt className="text-sm text-muted">Base fare</dt>
        <dd className="text-sm font-medium text-navy">{formatINR(fare.baseFare)}</dd>
      </div>

      <div className="flex items-center justify-between gap-3">
        <dt className="text-sm text-muted">
          Distance ({fare.distanceKm} km × ₹{rate}/km)
        </dt>
        <dd className="text-sm font-medium text-navy">{formatINR(fare.distanceFare)}</dd>
      </div>

      <div className="flex items-center justify-between gap-3">
        <dt className="text-sm text-muted">Platform fee</dt>
        <dd className="text-sm font-medium text-navy">{formatINR(fare.platformFee)}</dd>
      </div>

      {showPayment ? (
        <div className="flex items-center justify-between gap-3">
          <dt className="text-sm text-muted">Payment</dt>
          <dd className="text-sm font-medium text-navy">{paymentLabel}</dd>
        </div>
      ) : null}

      <div aria-hidden="true" className="my-1 h-px bg-line" />

      <div className="flex items-center justify-between gap-3">
        <dt className="text-base font-semibold text-navy">{totalLabel}</dt>
        <dd className="text-base font-semibold text-navy">{formatINR(fare.total)}</dd>
      </div>
    </dl>
  );
}
