'use client';

import { useState, type FormEvent } from 'react';
import { Check, Star } from 'lucide-react';

import { Avatar } from '@/components/ui/avatar';
import { Card } from '@/components/ui/card';
import { Textarea } from '@/components/ui/textarea';
import { ratingTagLimit, ratingTags, vehicleCopy } from '@/lib/domain/labels';
import type { Driver, VehicleType } from '@/lib/domain/types';
import { cn } from '@/lib/utils/cn';

/** The label of every star. */
const STAR_LABELS = ['Very poor', 'Poor', 'Okay', 'Good', 'Excellent!'] as const;

/** The values of a rating. */
export interface RatingFormValues {
  stars: 1 | 2 | 3 | 4 | 5;
  tags: string[];
  comment?: string;
}

export interface RatingFormProps {
  /** The driver of the ride. */
  driver?: Driver;
  /** The vehicle of the ride. */
  vehicle?: VehicleType;
  /** The rating is being stored. */
  pending: boolean;
  /** The error of the parent (e.g. the repository). */
  error?: string | null;
  /** The label of the submit button. */
  submitLabel?: string;
  /** The honest note under the button. */
  note?: string;
  onSubmit: (values: RatingFormValues) => void | Promise<void>;
}

/**
 * The rating form.
 *
 * It is used twice: for the ride that is still on the screen and for a ride
 * of the history (a deep link).
 */
export function RatingForm({
  driver,
  vehicle,
  pending,
  error,
  submitLabel = 'Submit rating',
  note = 'Ratings are stored in the demo only.',
  onSubmit,
}: RatingFormProps) {
  const [stars, setStars] = useState<0 | 1 | 2 | 3 | 4 | 5>(0);
  const [selectedTags, setSelectedTags] = useState<string[]>([]);
  const [comment, setComment] = useState('');
  const [localError, setLocalError] = useState<string | null>(null);

  const toggleTag = (tag: string) => {
    setSelectedTags((current) => {
      if (current.includes(tag)) return current.filter((entry) => entry !== tag);
      if (current.length >= ratingTagLimit) return current;
      return [...current, tag];
    });
  };

  const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setLocalError(null);

    if (stars === 0) {
      setLocalError('Please select a star rating.');
      return;
    }

    await onSubmit({
      stars,
      tags: selectedTags,
      comment: comment.trim() || undefined,
    });
  };

  return (
    <form noValidate onSubmit={handleSubmit} className="flex flex-col gap-4">
      <Card padding="lg" className="flex flex-col items-center gap-3 text-center">
        <Avatar name={driver?.name || 'Your driver'} size="lg" />

        <div className="flex flex-col">
          <span className="font-display text-base font-semibold text-navy">
            {driver?.name || 'Your driver'}
          </span>
          <span className="text-xs text-muted">
            {vehicle ? vehicleCopy[vehicle].name : 'Your vehicle'}
            {driver?.vehicleNumber ? ` · ${driver.vehicleNumber}` : ''}
          </span>
        </div>
      </Card>

      <Card padding="lg" className="flex flex-col items-center gap-3">
        <h2 className="font-display text-lg font-semibold text-navy">How was your ride?</h2>

        <fieldset className="w-full">
          <legend className="sr-only">Star rating</legend>

          <div className="flex items-center justify-center gap-1">
            {[1, 2, 3, 4, 5].map((value) => (
              <label
                key={value}
                className="cursor-pointer rounded-full p-1 focus-within:ring-2 focus-within:ring-navy focus-within:ring-offset-2"
              >
                <input
                  type="radio"
                  name="rating-stars"
                  value={value}
                  checked={stars === value}
                  onChange={() => setStars(value as 1 | 2 | 3 | 4 | 5)}
                  className="sr-only peer"
                />

                <Star
                  aria-hidden="true"
                  className={cn(
                    'size-10 rounded-full transition-colors',
                    'peer-focus-visible:ring-2 peer-focus-visible:ring-navy peer-focus-visible:ring-offset-2',
                    value <= stars ? 'fill-brand text-navy' : 'text-navy-soft',
                  )}
                />

                <span className="sr-only">
                  {value} star{value === 1 ? '' : 's'} - {STAR_LABELS[value - 1]}
                </span>
              </label>
            ))}
          </div>
        </fieldset>

        <p aria-live="polite" className="text-sm font-medium text-navy">
          {stars > 0 ? STAR_LABELS[stars - 1] : 'Tap a star to rate'}
        </p>
      </Card>

      <Card padding="lg" className="flex flex-col gap-3">
        <fieldset className="flex flex-col gap-2">
          <legend className="mb-1 text-sm font-medium text-navy">What went well?</legend>

          <div className="flex flex-wrap gap-2">
            {ratingTags.map((tag) => {
              const selected = selectedTags.includes(tag);
              const disabled = !selected && selectedTags.length >= ratingTagLimit;

              return (
                <label
                  key={tag}
                  className={cn(
                    'inline-flex min-h-11 items-center gap-1.5 rounded-pill border px-3 text-sm transition-colors',
                    'focus-within:ring-2 focus-within:ring-navy focus-within:ring-offset-2',
                    selected
                      ? 'border-brand bg-brand-soft font-medium text-navy'
                      : 'border-line bg-white text-muted',
                    disabled ? 'cursor-not-allowed opacity-60' : 'cursor-pointer hover:bg-navy-soft',
                  )}
                >
                  <input
                    type="checkbox"
                    checked={selected}
                    disabled={disabled}
                    onChange={() => toggleTag(tag)}
                    className="sr-only"
                  />

                  {selected ? <Check aria-hidden="true" className="size-3.5" /> : null}

                  {tag}
                </label>
              );
            })}
          </div>
        </fieldset>

        <Textarea
          label="Add a comment (optional)"
          rows={3}
          maxLength={300}
          value={comment}
          hint="Up to 300 characters."
          onChange={(event) => setComment(event.target.value)}
        />
      </Card>

      {localError || error ? (
        <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
          {localError ?? error}
        </p>
      ) : null}

      <button
        type="submit"
        disabled={pending}
        className={cn(
          'inline-flex h-12 w-full items-center justify-center rounded-pill bg-brand px-5 font-semibold text-navy transition-colors hover:bg-brand-strong',
          'focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-navy focus-visible:ring-offset-2',
          'disabled:cursor-not-allowed disabled:opacity-45',
        )}
      >
        {submitLabel}
      </button>

      <p className="text-center text-xs text-muted">{note}</p>
    </form>
  );
}
