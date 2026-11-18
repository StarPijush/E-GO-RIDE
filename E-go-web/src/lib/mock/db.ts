/**
 * Versioned mock database.
 *
 * The mock DB is the only owner of the `ego:db:v1` payload. It holds the
 * accounts, users, rides, saved places, payment methods and notifications of
 * the demo app. Repositories read and write it through the helpers below.
 *
 * The payload is defensive: an unknown shape, a corrupt JSON string or a
 * foreign `schemaVersion` is archived (`ego:legacy:<key>:<ts>`) and an empty
 * database is used instead. Storage is never touched at module scope.
 *
 * The database also lives in memory: when the browser storage is full or
 * blocked, the in-memory copy keeps the demo working for the tab and the app
 * is told about it through the `ego:storage-error` window event.
 */

import { z } from 'zod';

import { SCHEMA_VERSION, STORAGE_KEYS } from '@/lib/config/constants';
import {
  notificationSchema,
  paymentMethodSchema,
  persistedEnvelope,
  rideSchema,
  savedPlaceSchema,
  userSchema,
} from '@/lib/domain/schemas';
import type { AppNotification, PaymentMethod, Ride, SavedPlace, User } from '@/lib/domain/types';
import { readRaw, writeJsonResult, writeRaw } from '@/lib/utils/storage';

/** localStorage key of the mock database. */
export const dbStorageKey = STORAGE_KEYS.db;

/** Event dispatched when the database can no longer be persisted. */
export const STORAGE_ERROR_EVENT = 'ego:storage-error';

/** A login capable account. Only the salted hash is stored, never a password. */
export interface MockAccount {
  userId: string;
  /** Normalized phone number (E.164). */
  phone: string;
  passwordSalt: string;
  passwordHash: string;
  profileComplete: boolean;
  createdAt: string;
}

/** A saved place, scoped to the user it belongs to. */
export type StoredSavedPlace = SavedPlace & { userId: string };

/** A payment method, scoped to the user it belongs to. */
export type StoredPaymentMethod = PaymentMethod & { userId: string };

/** A notification, scoped to the user it belongs to. */
export type StoredNotification = AppNotification & { userId: string };

/** The persisted collections of the mock database. */
export interface MockDbData {
  users: User[];
  accounts: MockAccount[];
  rides: Ride[];
  savedPlaces: StoredSavedPlace[];
  paymentMethods: StoredPaymentMethod[];
  notifications: StoredNotification[];
}

/** The mock database, including the schema version it was written with. */
export interface MockDb extends MockDbData {
  schemaVersion: typeof SCHEMA_VERSION;
}

const mockAccountSchema = z.object({
  userId: z.string().min(1),
  phone: z.string().min(1),
  passwordSalt: z.string().min(1),
  passwordHash: z.string().min(1),
  profileComplete: z.boolean(),
  createdAt: z.iso.datetime(),
});

const storedSavedPlaceSchema = savedPlaceSchema.extend({ userId: z.string().min(1) });
const storedPaymentMethodSchema = paymentMethodSchema.extend({ userId: z.string().min(1) });
const storedNotificationSchema = notificationSchema.extend({ userId: z.string().min(1) });

export { storedSavedPlaceSchema, storedPaymentMethodSchema, storedNotificationSchema };

const mockDbDataSchema = z.object({
  users: z.array(userSchema),
  accounts: z.array(mockAccountSchema),
  rides: z.array(rideSchema),
  savedPlaces: z.array(storedSavedPlaceSchema),
  paymentMethods: z.array(storedPaymentMethodSchema),
  notifications: z.array(storedNotificationSchema),
});

const mockDbSchema = persistedEnvelope(mockDbDataSchema);

/** The in-memory copy of the database (the fallback when storage fails). */
let memoryDb: MockDb | null = null;

/** True while the database cannot be written to the browser storage. */
let persistenceDisabled = false;

/** True when the database can no longer be persisted (quota, blocked storage). */
export function isPersistenceDisabled(): boolean {
  return persistenceDisabled;
}

/** An empty database. */
export function createEmptyDb(): MockDb {
  return {
    schemaVersion: SCHEMA_VERSION,
    users: [],
    accounts: [],
    rides: [],
    savedPlaces: [],
    paymentMethods: [],
    notifications: [],
  };
}

/** Parse a stored payload. Returns `null` for anything unusable. */
function parseStoredDb(raw: string): MockDb | null {
  let decoded: unknown;
  try {
    decoded = JSON.parse(raw);
  } catch {
    return null;
  }
  const result = mockDbSchema.safeParse(decoded);
  if (!result.success) return null;
  return { schemaVersion: SCHEMA_VERSION, ...result.data.data };
}

/** Keep a corrupt payload around so it can be inspected later. */
function archiveCorruptPayload(raw: string): void {
  writeRaw(`ego:legacy:${dbStorageKey}:${Date.now()}`, raw);
}

/**
 * The stored database.
 *
 * The in-memory copy wins when it exists (it holds the writes of this tab).
 * Otherwise the payload is read from storage; a corrupt or foreign payload is
 * archived and an empty database is returned. Never throws.
 */
export function loadDb(): MockDb {
  if (memoryDb) return memoryDb;

  const raw = readRaw(dbStorageKey);
  if (raw === null) {
    memoryDb = createEmptyDb();
    return memoryDb;
  }

  const parsed = parseStoredDb(raw);
  if (!parsed) {
    archiveCorruptPayload(raw);
    memoryDb = createEmptyDb();
    return memoryDb;
  }

  memoryDb = parsed;
  return memoryDb;
}

/** Tell the app that the demo data can no longer be saved. */
function dispatchStorageError(reason?: 'unavailable' | 'quota' | 'serialize'): void {
  if (typeof window === 'undefined' || typeof window.dispatchEvent !== 'function') return;
  window.dispatchEvent(
    new CustomEvent(STORAGE_ERROR_EVENT, {
      detail: {
        message: 'Demo data could not be saved. Changes will be lost when you close this tab.',
        reason,
      },
    }),
  );
}

/**
 * Persist the database.
 *
 * The in-memory copy is always updated, so a failing storage never loses
 * data of the running tab. Returns `false` when the database could not be
 * written.
 */
export function saveDb(db: MockDb): boolean {
  memoryDb = db;

  const result = writeJsonResult(dbStorageKey, {
    schemaVersion: SCHEMA_VERSION,
    data: {
      users: db.users,
      accounts: db.accounts,
      rides: db.rides,
      savedPlaces: db.savedPlaces,
      paymentMethods: db.paymentMethods,
      notifications: db.notifications,
    },
  });

  if (result.ok) {
    persistenceDisabled = false;
    return true;
  }

  if (!persistenceDisabled) {
    persistenceDisabled = true;
    dispatchStorageError(result.reason);
  }
  return false;
}

/** Replace the stored database with an empty one. */
export function resetDb(): MockDb {
  const db = createEmptyDb();
  memoryDb = db;
  saveDb(db);
  return db;
}

/**
 * Read the database, apply `mutate` to it and persist the result.
 * The callback may mutate the database in place.
 */
export function updateDb<T>(mutate: (db: MockDb) => T): T {
  const db = loadDb();
  const result = mutate(db);
  saveDb(db);
  return result;
}
