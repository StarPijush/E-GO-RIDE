'use client';

import Image from 'next/image';
import { Bike, CheckCircle2, Users } from 'lucide-react';

import { Badge } from '@/components/ui/badge';
import { formatDistanceKm } from '@/lib/domain/geo';
import { formatINR } from '@/lib/domain/fare';
import { vehicleCopy } from '@/lib/domain/labels';
import type { VehicleOption } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

export interface VehicleCardProps {
  /** The vehicle of the card. */
  option: VehicleOption;
  /** The card is the chosen one. */
  selected: boolean;
  onSelect: (option: VehicleOption) => void;
  /** The minutes the trip takes. */
  tripMinutes: number;
  /** The distance of the route in kilometres. */
  distanceKm: number;
  disabled?: boolean;
}

/**
 * One vehicle of the choice.
 *
 * The card is a real radio button (visually hidden), so the keyboard and the
 * screen readers behave as they should.
 */
export function VehicleCard({
  option,
  selected,
  onSelect,
  tripMinutes,
  distanceKm,
  disabled = false,
}: VehicleCardProps) {
  const copy = vehicleCopy[option.type];

  return (
    <label className={cn('block', disabled ? 'cursor-not-allowed' : 'cursor-pointer')}>
      <input
        type="radio"
        name="vehicle"
        value={option.type}
        checked={selected}
        disabled={disabled}
        onChange={() => onSelect(option)}
        className="peer sr-only"
      />

      <span
        className={cn(
          'flex min-h-[92px] items-center gap-3 rounded-card border-2 bg-white p-4 transition-colors',
          'peer-focus-visible:ring-2 peer-focus-visible:ring-navy peer-focus-visible:ring-offset-2',
          selected
            ? 'border-brand shadow-[0_0_0_4px_rgba(255,201,40,0.18)]'
            : 'border-line hover:border-navy-soft',
          disabled && 'opacity-60',
        )}
      >
        <span className="flex size-14 shrink-0 items-center justify-center rounded-card bg-brand-soft">
          {option.type === 'bike' ? (
            <Bike aria-hidden="true" className="size-7 text-navy" />
          ) : (
            <Image
              src="/branding/ego_logo_icon.png"
              alt=""
              width={28}
              height={28}
              className="size-7 object-contain"
            />
          )}
        </span>

        <span className="flex min-w-0 flex-1 flex-col gap-1">
          <span className="flex items-center gap-2">
            <span className="font-display text-base font-semibold text-navy">{copy.name}</span>

            {copy.capacity > 1 ? (
              <Badge tone="neutral">
                <Users aria-hidden="true" className="size-3" />
                {copy.capacity}
              </Badge>
            ) : null}

            {selected ? (
              <CheckCircle2 aria-hidden="true" className="size-5 text-navy" />
            ) : null}
          </span>

          <span className="text-xs text-muted">{copy.description}</span>

          <span className="text-xs text-muted">
            {option.estimatedArrivalMinutes} min arrival · {tripMinutes} min trip
          </span>
        </span>

        <span className="flex shrink-0 flex-col items-end">
          <span className="font-display text-lg font-bold text-navy">
            {formatINR(option.fare)}
          </span>
          <span className="text-xs text-muted">{formatDistanceKm(distanceKm)}</span>
        </span>
      </span>
    </label>
  );
}
