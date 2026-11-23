/**
 * Deterministic seed data of the E-GO demo.
 *
 * Everything the demo shows lives here: the driver pool, the places of
 * Jhargram, the saved places, the payment methods, the notifications and the
 * historical rides of the demo account.
 *
 * The records have fixed ids, so seeding is idempotent: running it twice
 * changes nothing. No active ride is seeded - a new ride always starts from
 * `idle`.
 */

import {
  DEMO_EMAIL,
  DEMO_NAME,
  DEMO_PHONE,
  DEMO_USER_ID,
  isDemoMode,
} from '@/lib/mock/demo-credentials';
import {
  loadDb,
  saveDb,
  type MockDb,
  type StoredNotification,
  type StoredPaymentMethod,
  type StoredSavedPlace,
} from '@/lib/mock/db';
import type { Driver, Place, Ride, User } from '@/lib/domain/types';
import { normalizePhone } from '@/lib/utils/phone';

/** The phone number of the demo account, normalized. */
export const DEMO_PHONE_E164 = normalizePhone(DEMO_PHONE) ?? DEMO_PHONE;

/**
 * The profile of the demo account.
 *
 * The credential hash is not part of it - the auth repository owns that.
 */
export const DEMO_USER: Omit<User, 'createdAt'> = {
  id: DEMO_USER_ID,
  fullName: DEMO_NAME,
  phone: DEMO_PHONE_E164,
  email: DEMO_EMAIL,
  profileComplete: true,
};

/** The demo driver pool: two bikes and three totos around Jhargram. */
export const DEMO_DRIVERS: readonly Driver[] = [
  {
    id: 'driver-001',
    name: 'Rajan Kumar',
    rating: 4.8,
    ridesCompleted: 324,
    vehicleType: 'bike',
    vehicleModel: 'Hero Splendor',
    vehicleNumber: 'WB 32 D 1234',
    location: { lat: 22.455, lng: 86.902 },
    etaMinutes: 3,
  },
  {
    id: 'driver-002',
    name: 'Suresh Das',
    rating: 4.6,
    ridesCompleted: 211,
    vehicleType: 'toto',
    vehicleModel: 'E-Rickshaw',
    vehicleNumber: 'WB 32 E 5678',
    location: { lat: 22.455, lng: 86.902 },
    etaMinutes: 5,
  },
  {
    id: 'driver-003',
    name: 'Imran Ali',
    rating: 4.7,
    ridesCompleted: 158,
    vehicleType: 'bike',
    vehicleModel: 'Bajaj Pulsar',
    vehicleNumber: 'WB 32 D 7788',
    location: { lat: 22.4571, lng: 86.9038 },
    etaMinutes: 3,
  },
  {
    id: 'driver-004',
    name: 'Madan Mahato',
    rating: 4.9,
    ridesCompleted: 402,
    vehicleType: 'toto',
    vehicleModel: 'E-Rickshaw',
    vehicleNumber: 'WB 32 E 2211',
    location: { lat: 22.4512, lng: 86.8987 },
    etaMinutes: 5,
  },
  {
    id: 'driver-005',
    name: 'Bapi Roy',
    rating: 4.5,
    ridesCompleted: 97,
    vehicleType: 'toto',
    vehicleModel: 'E-Rickshaw',
    vehicleNumber: 'WB 32 E 9090',
    location: { lat: 22.4602, lng: 86.9075 },
    etaMinutes: 5,
  },
];

const demoDrivers = new Map(DEMO_DRIVERS.map((driver) => [driver.id, driver]));

/** A driver of the demo pool (module invariant: the id always exists). */
function demoDriver(id: string): Driver {
  const driver = demoDrivers.get(id);
  if (!driver) throw new Error(`Unknown demo driver "${id}".`);
  return driver;
}

/** The places of Jhargram the demo can search and book. */
export const PLACES: readonly Place[] = [
  {
    id: 'place-001',
    label: 'Jhargram Railway Station',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4529,
    lng: 86.9003,
  },
  {
    id: 'place-002',
    label: 'Jhargram Bus Stand',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.458,
    lng: 86.905,
  },
  {
    id: 'place-003',
    label: 'Jhargram Market',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4701,
    lng: 86.9152,
  },
  {
    id: 'place-004',
    label: 'Jhargram District Hospital',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.44,
    lng: 86.88,
  },
  {
    id: 'place-005',
    label: 'Jhargram Police Station',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4565,
    lng: 86.9085,
  },
  {
    id: 'place-006',
    label: 'Jhargram College',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.461,
    lng: 86.912,
  },
  {
    id: 'place-007',
    label: 'Netaji Subhas Chowk',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4535,
    lng: 86.8975,
  },
  {
    id: 'place-008',
    label: 'Jhargram Stadium',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4472,
    lng: 86.9035,
  },
  {
    id: 'place-009',
    label: 'Rani Rashmoni Road',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4558,
    lng: 86.8942,
  },
  {
    id: 'place-010',
    label: 'Sabuj Sangha More',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4495,
    lng: 86.8895,
  },
  {
    id: 'place-011',
    label: 'Jhargram Court',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4435,
    lng: 86.8975,
  },
  {
    id: 'place-012',
    label: 'Gopiballavpur Road',
    address: 'Jhargram, West Bengal',
    kind: 'poi',
    lat: 22.4315,
    lng: 86.8845,
  },
];

const places = new Map(PLACES.map((place) => [place.id, place]));

/** A place of the demo (module invariant: the id always exists). */
function demoPlace(id: string): Place {
  const place = places.get(id);
  if (!place) throw new Error(`Unknown demo place "${id}".`);
  return place;
}

/** The saved places of the demo account. */
export const DEMO_SAVED_PLACES: readonly StoredSavedPlace[] = [
  {
    id: 'place-001',
    savedId: 'saved-demo-home',
    label: 'Home',
    address: 'Jhargram, West Bengal',
    kind: 'saved',
    tag: 'home',
    lat: demoPlace('place-001').lat,
    lng: demoPlace('place-001').lng,
    userId: DEMO_USER_ID,
  },
  {
    id: 'place-006',
    savedId: 'saved-demo-work',
    label: 'Work',
    address: 'Jhargram, West Bengal',
    kind: 'saved',
    tag: 'work',
    lat: demoPlace('place-006').lat,
    lng: demoPlace('place-006').lng,
    userId: DEMO_USER_ID,
  },
];

/** The payment methods of the demo account (cash only, per A9). */
export const DEMO_PAYMENT_METHODS: readonly StoredPaymentMethod[] = [
  {
    id: 'cash-demo-001',
    type: 'cash',
    label: 'Cash',
    isDefault: true,
    userId: DEMO_USER_ID,
  },
];

/** The notifications of the demo account. */
export const DEMO_NOTIFICATIONS: readonly StoredNotification[] = [
  {
    id: 'notif-demo-001',
    kind: 'ride',
    title: 'Driver assigned',
    body: 'Madan Mahato is on the way to your pickup point.',
    createdAt: '2026-11-12T07:46:30.000Z',
    read: false,
    userId: DEMO_USER_ID,
  },
  {
    id: 'notif-demo-002',
    kind: 'system',
    title: 'Welcome to E-GO!',
    body: 'Book your first ride and move your way.',
    createdAt: '2026-11-11T09:15:00.000Z',
    read: false,
    userId: DEMO_USER_ID,
  },
  {
    id: 'notif-demo-003',
    kind: 'promo',
    title: 'Ride across Jhargram',
    body: 'Book bike and Toto rides across Jhargram anytime.',
    createdAt: '2026-11-09T16:00:00.000Z',
    read: true,
    userId: DEMO_USER_ID,
  },
  {
    id: 'notif-demo-004',
    kind: 'payment',
    title: 'Cash payment selected',
    body: 'Cash is your default payment method in this demo.',
    createdAt: '2026-11-02T09:21:00.000Z',
    read: true,
    userId: DEMO_USER_ID,
  },
];

/**
 * The three historical rides of the demo account:
 * one rated, one completed but unrated and one cancelled.
 */
export const DEMO_RIDES: readonly Ride[] = [
  {
    id: 'ride-demo-001',
    userId: DEMO_USER_ID,
    pickup: { ...demoPlace('place-003'), kind: 'pickup' },
    destination: { ...demoPlace('place-001'), kind: 'destination' },
    vehicle: 'toto',
    fare: {
      vehicle: 'toto',
      baseFare: 15,
      distanceFare: 35,
      platformFee: 2,
      total: 52,
      distanceKm: 5,
      estimatedMinutes: 30,
      estimatedArrivalMinutes: 5,
      currency: 'INR',
    },
    status: 'rated',
    driver: demoDriver('driver-002'),
    paymentMethodId: 'cash-demo-001',
    createdAt: '2026-11-02T09:12:00.000Z',
    phaseStartedAt: '2026-11-02T09:26:00.000Z',
    completedAt: '2026-11-02T09:21:00.000Z',
    rating: {
      rideId: 'ride-demo-001',
      stars: 5,
      comment: 'Great driver',
      tags: ['Great driver', 'On time'],
      createdAt: '2026-11-02T09:26:00.000Z',
    },
    timeline: [
      { status: 'confirmingBooking', at: '2026-11-02T09:12:00.000Z' },
      { status: 'searchingDriver', at: '2026-11-02T09:12:30.000Z' },
      { status: 'driverAssigned', at: '2026-11-02T09:13:00.000Z' },
      { status: 'driverArriving', at: '2026-11-02T09:13:30.000Z' },
      { status: 'driverArrived', at: '2026-11-02T09:15:00.000Z' },
      { status: 'tripInProgress', at: '2026-11-02T09:16:00.000Z' },
      { status: 'tripCompleted', at: '2026-11-02T09:21:00.000Z' },
      { status: 'awaitingRating', at: '2026-11-02T09:21:30.000Z' },
      { status: 'rated', at: '2026-11-02T09:26:00.000Z' },
    ],
  },
  {
    id: 'ride-demo-002',
    userId: DEMO_USER_ID,
    pickup: { ...demoPlace('place-006'), kind: 'pickup' },
    destination: { ...demoPlace('place-002'), kind: 'destination' },
    vehicle: 'bike',
    fare: {
      vehicle: 'bike',
      baseFare: 20,
      distanceFare: 20,
      platformFee: 3,
      total: 43,
      distanceKm: 2,
      estimatedMinutes: 9,
      estimatedArrivalMinutes: 3,
      currency: 'INR',
    },
    status: 'awaitingRating',
    driver: demoDriver('driver-001'),
    paymentMethodId: 'cash-demo-001',
    createdAt: '2026-11-09T18:30:00.000Z',
    phaseStartedAt: '2026-11-09T18:38:30.000Z',
    completedAt: '2026-11-09T18:38:00.000Z',
    timeline: [
      { status: 'confirmingBooking', at: '2026-11-09T18:30:00.000Z' },
      { status: 'searchingDriver', at: '2026-11-09T18:30:30.000Z' },
      { status: 'driverAssigned', at: '2026-11-09T18:31:00.000Z' },
      { status: 'driverArriving', at: '2026-11-09T18:31:30.000Z' },
      { status: 'driverArrived', at: '2026-11-09T18:33:00.000Z' },
      { status: 'tripInProgress', at: '2026-11-09T18:34:00.000Z' },
      { status: 'tripCompleted', at: '2026-11-09T18:38:00.000Z' },
      { status: 'awaitingRating', at: '2026-11-09T18:38:30.000Z' },
    ],
  },
  {
    id: 'ride-demo-003',
    userId: DEMO_USER_ID,
    pickup: { ...demoPlace('place-007'), kind: 'pickup' },
    destination: { ...demoPlace('place-011'), kind: 'destination' },
    vehicle: 'toto',
    fare: {
      vehicle: 'toto',
      baseFare: 15,
      distanceFare: 21,
      platformFee: 2,
      total: 38,
      distanceKm: 3,
      estimatedMinutes: 20,
      estimatedArrivalMinutes: 5,
      currency: 'INR',
    },
    status: 'cancelled',
    driver: demoDriver('driver-004'),
    paymentMethodId: 'cash-demo-001',
    createdAt: '2026-11-12T07:45:00.000Z',
    phaseStartedAt: '2026-11-12T07:47:00.000Z',
    cancelledAt: '2026-11-12T07:47:00.000Z',
    cancellationReason: 'changed_plan',
    timeline: [
      { status: 'confirmingBooking', at: '2026-11-12T07:45:00.000Z' },
      { status: 'searchingDriver', at: '2026-11-12T07:45:30.000Z' },
      { status: 'driverAssigned', at: '2026-11-12T07:46:00.000Z' },
      { status: 'driverArriving', at: '2026-11-12T07:46:30.000Z' },
      { status: 'cancelled', at: '2026-11-12T07:47:00.000Z' },
    ],
  },
];

/**
 * Add the missing demo records to a database.
 *
 * Only records of the demo account are touched and every record is keyed by
 * its fixed id, so calling this twice changes nothing. Returns `true` when
 * the database was changed.
 */
export function ensureDemoSeedData(db: MockDb): boolean {
  let changed = false;

  for (const place of DEMO_SAVED_PLACES) {
    if (!db.savedPlaces.some((existing) => existing.savedId === place.savedId)) {
      db.savedPlaces.push(place);
      changed = true;
    }
  }

  for (const method of DEMO_PAYMENT_METHODS) {
    if (!db.paymentMethods.some((existing) => existing.id === method.id)) {
      db.paymentMethods.push(method);
      changed = true;
    }
  }

  for (const notification of DEMO_NOTIFICATIONS) {
    if (!db.notifications.some((existing) => existing.id === notification.id)) {
      db.notifications.push(notification);
      changed = true;
    }
  }

  for (const ride of DEMO_RIDES) {
    if (!db.rides.some((existing) => existing.id === ride.id)) {
      db.rides.push(ride);
      changed = true;
    }
  }

  return changed;
}

/** The in-flight seed, so concurrent callers share one run. */
let seedPromise: Promise<void> | null = null;

/**
 * Seed the demo data (demo mode only).
 *
 * The database is only written when something actually changed, and a
 * concurrent call reuses the running promise instead of seeding twice.
 */
export function seedDemoData(): void {
  if (!isDemoMode()) return;
  if (seedPromise) return;

  seedPromise = (async () => {
    const db = loadDb();
    if (ensureDemoSeedData(db)) saveDb(db);
  })()
    .catch(() => undefined)
    .finally(() => {
      seedPromise = null;
    });
}
