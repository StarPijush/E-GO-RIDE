/**
 * Persisted storage for the Zustand stores.
 *
 * Every store of E-GO Web is persisted through this adapter:
 * - the payload carries the schema version and is validated with Zod before
 *   it enters the app;
 * - a payload that cannot be read is archived (`ego:legacy:<key>:<ts>`) and
 *   the store starts fresh instead of crashing;
 * - a storage that cannot be written (full quota, blocked storage) keeps the
 *   state in memory and reports it once through the `ego:storage-error`
 *   event.
 *
 * Storage is never touched at module scope.
 */

import type { PersistStorage, StorageValue } from 'zustand/middleware';
import type { ZodType } from 'zod';

import { SCHEMA_VERSION } from '@/lib/config/constants';
import { readRaw, removeEgoKeys, removeKey, writeRawResult } from '@/lib/utils/storage';

/** Event dispatched when the app can no longer save its state. */
export const STORAGE_ERROR_EVENT = 'ego:storage-error';

/** The error is reported once per page - the app shows one toast. */
let storageErrorReported = false;

/** Keep an unreadable payload around so it can be inspected later. */
function archiveCorruptPayload(key: string, raw: string): void {
  try {
    window.localStorage.setItem(`ego:legacy:${key}:${Date.now()}`, raw);
  } catch {
    // Nothing to do: the payload is lost either way.
  }
}

/** Tell the app that the state can no longer be saved. */
function reportStorageError(): void {
  if (storageErrorReported) return;
  storageErrorReported = true;
  if (typeof window === 'undefined' || typeof window.dispatchEvent !== 'function') return;

  window.dispatchEvent(
    new CustomEvent(STORAGE_ERROR_EVENT, {
      detail: {
        message: 'Your changes could not be saved. They will be lost when you close this tab.',
      },
    }),
  );
}

/**
 * A persist storage for one store.
 *
 * @param key the localStorage key of the store
 * @param schema the Zod schema of the persisted payload
 */
export function createEgoPersistStorage<S>(
  key: string,
  schema: ZodType<{ schemaVersion: typeof SCHEMA_VERSION; data: S }>,
): PersistStorage<S> {
  return {
    getItem: (name: string): StorageValue<S> | null => {
      const raw = readRaw(name);
      if (raw === null) return null;

      let decoded: unknown;
      try {
        decoded = JSON.parse(raw);
      } catch {
        archiveCorruptPayload(key, raw);
        return null;
      }

      const parsed = schema.safeParse(decoded);
      if (!parsed.success) {
        archiveCorruptPayload(key, raw);
        return null;
      }

      return { state: parsed.data.data, version: parsed.data.schemaVersion };
    },

    setItem: (name: string, value: StorageValue<S>): void => {
      const payload = {
        schemaVersion: SCHEMA_VERSION,
        data: value.state,
      };

      let encoded: string;
      try {
        encoded = JSON.stringify(payload);
      } catch {
        reportStorageError();
        return;
      }

      const result = writeRawResult(name, encoded);
      if (!result.ok) reportStorageError();
    },

    removeItem: (name: string): void => {
      removeKey(name);
    },
  };
}

/** Remove every `ego:*` key (used by "clear demo data"). */
export function clearEgoPersistence(): void {
  removeEgoKeys();
}
