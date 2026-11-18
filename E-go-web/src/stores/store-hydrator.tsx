'use client';

/**
 * The hydration of the persisted stores.
 *
 * The component is mounted once in the root layout. It reads the persisted
 * state (the stores are created with `skipHydration`, so nothing is read
 * before this runs), prepares the demo data and lets the booking catch up
 * with the wall clock.
 *
 * Nothing is read or written during the render.
 */

import { useEffect } from 'react';

import { STORAGE_KEYS } from '@/lib/config/constants';
import { initializeMockData } from '@/lib/repositories';
import { useAuthStore } from '@/stores/auth-store';
import { useBookingStore } from '@/stores/booking-store';
import { usePreferencesStore } from '@/stores/preferences-store';

/** The hydration runs once per page (React 19 may mount an effect twice). */
let hydratedOnce = false;

export function StoreHydrator() {
  useEffect(() => {
    let cancelled = false;

    const hydrate = async () => {
      try {
        if (!hydratedOnce) {
          hydratedOnce = true;

          await Promise.all([
            useAuthStore.persist.rehydrate(),
            useBookingStore.persist.rehydrate(),
            usePreferencesStore.persist.rehydrate(),
          ]);

          initializeMockData();

          await useAuthStore.getState().expireIfNeeded();
          await useBookingStore.getState().resume();
        }
      } finally {
        if (cancelled) return;
        useAuthStore.getState().setHasHydrated(true);
        useBookingStore.getState().setHasHydrated(true);
        usePreferencesStore.getState().setHasHydrated(true);
      }
    };

    void hydrate();

    // Another tab changed the session or the booking.
    const handleStorage = (event: StorageEvent) => {
      if (event.key === STORAGE_KEYS.auth) {
        void (async () => {
          await useAuthStore.persist.rehydrate();
          await useAuthStore.getState().expireIfNeeded();
        })();
      }

      if (event.key === STORAGE_KEYS.booking) {
        void (async () => {
          await useBookingStore.persist.rehydrate();
          await useBookingStore.getState().resume();
        })();
      }
    };

    window.addEventListener('storage', handleStorage);

    return () => {
      cancelled = true;
      window.removeEventListener('storage', handleStorage);
    };
  }, []);

  return null;
}
