/**
 * The preferences store.
 *
 * Two switches only: the notifications and the reduced motion override. The
 * store is persisted separately from the session, so a logout does not reset
 * the settings of the passenger.
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import { STORAGE_KEYS } from '@/lib/config/constants';
import { persistedPreferencesSchema } from '@/lib/domain/schemas';
import { createEgoPersistStorage } from '@/stores/persist-storage';

/** The state of the preferences. */
export interface PreferencesState {
  notifications: boolean;
  reducedMotion: boolean;
  /** True once the persisted state was read. */
  hasHydrated: boolean;
}

/** The actions of the preferences store. */
export interface PreferencesActions {
  setNotifications(value: boolean): void;
  setReducedMotion(value: boolean): void;
  setHasHydrated(value: boolean): void;
}

/** The complete store. */
export type PreferencesStore = PreferencesState & PreferencesActions;

export const usePreferencesStore = create<PreferencesStore>()(
  persist(
    (set) => ({
      notifications: true,
      reducedMotion: false,
      hasHydrated: false,

      setNotifications: (value: boolean) => {
        set({ notifications: value });
      },

      setReducedMotion: (value: boolean) => {
        set({ reducedMotion: value });
      },

      setHasHydrated: (value: boolean) => {
        set({ hasHydrated: value });
      },
    }),
    {
      name: STORAGE_KEYS.prefs,
      storage: createEgoPersistStorage(STORAGE_KEYS.prefs, persistedPreferencesSchema),
      skipHydration: true,
      partialize: (state) => ({
        notifications: state.notifications,
        reducedMotion: state.reducedMotion,
      }),
      version: 1,
    },
  ),
);
