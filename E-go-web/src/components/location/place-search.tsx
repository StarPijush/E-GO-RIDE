'use client';

import { useEffect, useState } from 'react';
import { Search, X } from 'lucide-react';

import { PlaceRow } from '@/components/location/place-row';
import { Card, EmptyState, ErrorState, IconButton, Input, Skeleton } from '@/components/ui';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { emptyStateCopy, errorMessage } from '@/lib/domain/labels';
import type { Place, SavedPlace } from '@/lib/domain/types';
import { getRepositories } from '@/lib/repositories';

export interface PlaceSearchProps {
  /** Called when a place of the result list is chosen. */
  onSelect: (place: Place) => void;
  placeholder?: string;
  label?: string;
  autoFocus?: boolean;
  disabled?: boolean;
  /** The saved places of the passenger (shown while the query is empty). */
  savedPlaces?: readonly SavedPlace[];
  onSelectSaved?: (place: SavedPlace) => void;
}

/** How long the typing is paused before the search runs. */
const DEBOUNCE_MS = 250;

export function PlaceSearch({
  onSelect,
  placeholder,
  label = 'Search for a place',
  autoFocus = false,
  disabled = false,
  savedPlaces,
  onSelectSaved,
}: PlaceSearchProps) {
  const [query, setQuery] = useState('');
  const [debounced, setDebounced] = useState('');

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(query.trim()), DEBOUNCE_MS);
    return () => clearTimeout(timer);
  }, [query]);

  const results = useAsyncData(
    () => getRepositories().places.search(debounced),
    [debounced],
    { enabled: !disabled },
  );

  const places = results.data ?? [];
  const showSaved = debounced.length === 0 && (savedPlaces?.length ?? 0) > 0;

  return (
    <div className="flex flex-col">
      <div className="relative">
        <Input
          label={label}
          placeholder={placeholder}
          value={query}
          autoFocus={autoFocus}
          disabled={disabled}
          className="pl-10 pr-11"
          onChange={(event) => setQuery(event.target.value)}
        />

        <Search
          aria-hidden="true"
          className="pointer-events-none absolute left-3 top-11 size-4 text-muted"
        />

        {query.length > 0 ? (
          <IconButton
            label="Clear search"
            size="sm"
            onClick={() => setQuery('')}
            className="absolute right-2 top-8"
          >
            <X aria-hidden="true" className="size-4" />
          </IconButton>
        ) : null}
      </div>

      <p className="sr-only" aria-live="polite">
        {places.length} places found
      </p>

      <Card padding="none" className="mt-3 max-h-72 divide-y divide-line overflow-y-auto">
        {results.loading ? (
          <div className="flex flex-col gap-3 p-4">
            <Skeleton className="h-12 w-full" />
            <Skeleton className="h-12 w-full" />
            <Skeleton className="h-12 w-full" />
          </div>
        ) : results.error ? (
          <ErrorState
            title="Search failed"
            message={errorMessage(results.error)}
            onRetry={results.reload}
            className="py-6"
          />
        ) : places.length === 0 && !showSaved ? (
          <EmptyState
            title={emptyStateCopy.places.title}
            description={emptyStateCopy.places.description}
          />
        ) : (
          <>
            {showSaved ? (
              <>
                <p className="px-4 pt-3 text-xs font-semibold uppercase tracking-wider text-muted">
                  Saved places
                </p>
                {savedPlaces?.map((place) => (
                  <PlaceRow
                    key={place.savedId}
                    place={place}
                    onSelect={() => onSelectSaved?.(place)}
                  />
                ))}
                <p className="px-4 pt-3 text-xs font-semibold uppercase tracking-wider text-muted">
                  All places
                </p>
              </>
            ) : null}

            {places.map((place) => (
              <PlaceRow key={place.id} place={place} onSelect={onSelect} />
            ))}
          </>
        )}
      </Card>
    </div>
  );
}
