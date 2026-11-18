'use client';

import { useState } from 'react';
import { Briefcase, Home, MapPin, Trash2 } from 'lucide-react';

import { PageHeader } from '@/components/layout/page-header';
import {
  Button,
  Card,
  Dialog,
  EmptyState,
  ErrorState,
  IconButton,
  Input,
  Skeleton,
  useToast,
} from '@/components/ui';
import { MAP_CENTER } from '@/lib/config/constants';
import { ROUTES } from '@/lib/config/routes';
import type { Place, SavedPlace } from '@/lib/domain/types';
import { useAsyncData } from '@/lib/hooks/use-async-data';
import { getRepositories } from '@/lib/repositories';
import { cn } from '@/lib/utils/cn';
import { newId } from '@/lib/utils/id';
import { useAuthStore } from '@/stores/auth-store';

/** The types a saved place can have. */
const TAGS: readonly { value: SavedPlace['tag']; label: string }[] = [
  { value: 'home', label: 'Home' },
  { value: 'work', label: 'Work' },
  { value: 'other', label: 'Other' },
];

/** The icon of a tag. */
function TagIcon({ tag }: { tag: SavedPlace['tag'] }) {
  if (tag === 'home') return <Home aria-hidden="true" className="size-5 text-navy" />;
  if (tag === 'work') return <Briefcase aria-hidden="true" className="size-5 text-navy" />;
  return <MapPin aria-hidden="true" className="size-5 text-navy" />;
}

export function SavedPlacesScreen() {
  const { show } = useToast();

  const user = useAuthStore((state) => state.user);
  const userId = user?.id ?? '';

  const places = useAsyncData(
    () => getRepositories().places.listSaved(userId),
    [userId],
    { enabled: Boolean(user) },
  );

  const [dialogOpen, setDialogOpen] = useState(false);
  const [label, setLabel] = useState('');
  const [address, setAddress] = useState('');
  const [tag, setTag] = useState<SavedPlace['tag']>('home');
  const [dialogError, setDialogError] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [removingId, setRemovingId] = useState<string | null>(null);

  const openDialog = () => {
    setLabel('');
    setAddress('');
    setTag('home');
    setDialogError(null);
    setDialogOpen(true);
  };

  const closeDialog = () => {
    setDialogOpen(false);
    setDialogError(null);
  };

  const handleRemove = async (place: SavedPlace) => {
    setRemovingId(place.savedId);
    try {
      const result = await getRepositories().places.remove(userId, place.savedId);
      if (!result.ok) {
        show({ message: result.error.message, tone: 'danger' });
        return;
      }
      show({ message: 'Place removed.', tone: 'success' });
      places.reload();
    } finally {
      setRemovingId(null);
    }
  };

  const handleSave = async () => {
    setDialogError(null);

    const name = label.trim();
    if (name.length === 0) {
      setDialogError('Please enter a place name.');
      return;
    }

    const place: Place = {
      id: newId('place'),
      label: name,
      address: address.trim() || 'Jhargram area',
      kind: 'saved',
      lat: MAP_CENTER.lat,
      lng: MAP_CENTER.lng,
    };

    setSaving(true);
    try {
      const result = await getRepositories().places.save(userId, place, tag);
      if (!result.ok) {
        setDialogError(result.error.message);
        return;
      }
      show({ message: 'Place saved successfully!', tone: 'success' });
      closeDialog();
      places.reload();
    } finally {
      setSaving(false);
    }
  };

  return (
    <div className="mx-auto w-full max-w-2xl px-4 py-5 sm:px-6 lg:px-8">
      <PageHeader
        title="Saved places"
        description="Save Home, Work and frequent destinations for faster booking."
        backHref={ROUTES.home}
        className="mb-5"
      />

      {places.loading ? (
        <div className="flex flex-col gap-3">
          <Card padding="md" className="flex flex-col gap-2">
            <Skeleton className="h-5 w-1/3" />
            <Skeleton className="h-4 w-2/3" />
          </Card>
          <Card padding="md" className="flex flex-col gap-2">
            <Skeleton className="h-5 w-1/4" />
            <Skeleton className="h-4 w-1/2" />
          </Card>
        </div>
      ) : places.error ? (
        <ErrorState
          title="Saved places could not be loaded"
          message="Please try again."
          onRetry={places.reload}
        />
      ) : places.data && places.data.length > 0 ? (
        <>
          <div className="flex flex-col gap-3">
            {places.data.map((place) => (
              <Card key={place.savedId} padding="md" className="flex items-center gap-3">
                <span className="flex size-11 shrink-0 items-center justify-center rounded-full bg-brand-soft">
                  <TagIcon tag={place.tag} />
                </span>

                <span className="flex min-w-0 flex-1 flex-col">
                  <span className="truncate font-semibold text-navy">{place.label}</span>
                  <span className="truncate text-sm text-muted">{place.address}</span>
                </span>

                <IconButton
                  label={`Remove ${place.label}`}
                  size="sm"
                  disabled={removingId === place.savedId}
                  onClick={() => handleRemove(place)}
                  className="text-danger hover:bg-danger-soft"
                >
                  <Trash2 aria-hidden="true" className="size-4" />
                </IconButton>
              </Card>
            ))}
          </div>

          <Button fullWidth className="mt-4" onClick={openDialog}>
            Add a new place
          </Button>
        </>
      ) : (
        <EmptyState
          icon={<MapPin aria-hidden="true" className="size-7" />}
          title="No saved places yet"
          description="Save Home, Work and frequent destinations for faster booking"
          action={
            <Button variant="secondary" onClick={openDialog}>
              Add place
            </Button>
          }
        />
      )}

      <p className="mt-6 text-center text-xs text-muted">
        Saved places are stored locally in this demo.
      </p>

      <Dialog
        open={dialogOpen}
        onClose={closeDialog}
        title="Add Favorite Place"
        description="Save a place you book often."
        footer={
          <>
            <Button variant="secondary" onClick={closeDialog} disabled={saving}>
              Cancel
            </Button>
            <Button onClick={handleSave} loading={saving} disabled={saving}>
              Save
            </Button>
          </>
        }
      >
        <div className="flex flex-col gap-4">
          <Input
            label="Label"
            placeholder="e.g. Gym, Library, Friend's House"
            required
            value={label}
            disabled={saving}
            onChange={(event) => setLabel(event.target.value)}
          />

          <Input
            label="Address in Jhargram"
            placeholder="e.g. Near Jhargram College"
            value={address}
            disabled={saving}
            onChange={(event) => setAddress(event.target.value)}
          />

          <fieldset className="flex flex-col gap-2">
            <legend className="mb-1 text-sm font-medium text-navy">Type</legend>

            <div className="flex flex-wrap gap-2">
              {TAGS.map((option) => (
                <label
                  key={option.value}
                  className={cn(
                    'inline-flex min-h-11 cursor-pointer items-center gap-2 rounded-pill border px-4 text-sm transition-colors',
                    'focus-within:ring-2 focus-within:ring-navy focus-within:ring-offset-2',
                    tag === option.value
                      ? 'border-brand bg-brand-soft font-semibold text-navy'
                      : 'border-line bg-white text-muted hover:bg-navy-soft',
                  )}
                >
                  <input
                    type="radio"
                    name="place-tag"
                    value={option.value}
                    checked={tag === option.value}
                    onChange={() => setTag(option.value)}
                    className="sr-only"
                  />
                  <TagIcon tag={option.value} />
                  {option.label}
                </label>
              ))}
            </div>
          </fieldset>

          {dialogError ? (
            <p role="alert" className="rounded-field bg-danger-soft px-3 py-2 text-sm text-danger">
              {dialogError}
            </p>
          ) : null}
        </div>
      </Dialog>
    </div>
  );
}
