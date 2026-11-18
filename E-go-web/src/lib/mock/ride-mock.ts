/**
 * Mock ride repository.
 *
 * DEVELOPMENT ONLY - rides live in the browser database (`ego:db:v1`). There
 * is no dispatch, no driver and no payment behind them: the lifecycle is
 * simulated by `lib/domain/ride-orchestrator.ts`.
 *
 * The repository owns the persistence of a ride (create, save, cancel, rate),
 * the history lists and the notifications that a status change produces.
 * Every expected failure is returned as a `Result` error, never thrown.
 */

import { isCancelableStatus, transitionRide } from '@/lib/domain/booking-fsm';
import { formatINR } from '@/lib/domain/fare';
import { bookingStatusCopy } from '@/lib/domain/labels';
import { ratingSchema, rideSchema } from '@/lib/domain/schemas';
import type {
  AppErrorCode,
  CancellationReason,
  Rating,
  Result,
  Ride,
  RideFilter,
  RideStatus,
} from '@/lib/domain/types';
import { loadDb, updateDb, type MockDb, type StoredNotification } from '@/lib/mock/db';
import { mockDelay, resolveLatency } from '@/lib/mock/mock-delay';
import type { RideRepository } from '@/lib/repositories/types';
import { newId } from '@/lib/utils/id';

/** Options of the mock repository (used to make tests deterministic). */
export interface MockRideOptions {
  /** Simulated latency in milliseconds. `0` disables the delay. */
  latencyMs?: number;
  /** Injectable clock, epoch milliseconds. */
  now?: () => number;
}

/** The statuses of a ride that is still on its way. */
const LIVE_STATUSES: readonly RideStatus[] = [
  'confirmingBooking',
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
  'tripInProgress',
  'tripCompleted',
  'awaitingRating',
];

/** The statuses of a finished ride (the history). */
const HISTORY_STATUSES: readonly RideStatus[] = [
  'tripCompleted',
  'awaitingRating',
  'rated',
  'cancelled',
];

/** The history filter "completed". */
const COMPLETED_STATUSES: readonly RideStatus[] = ['tripCompleted', 'awaitingRating', 'rated'];

/** The history filter "cancelled". */
const CANCELLED_STATUSES: readonly RideStatus[] = ['cancelled'];

/** The status changes that produce a notification. */
const NOTIFIED_STATUSES: readonly RideStatus[] = [
  'driverAssigned',
  'cancelled',
  'tripCompleted',
  'rated',
];

function failure(code: AppErrorCode, message: string, field?: string): Result<never> {
  return { ok: false, error: field ? { code, message, field } : { code, message } };
}

/** Newest ride first. */
function byCreatedAtDesc(left: Ride, right: Ride): number {
  return Date.parse(right.createdAt) - Date.parse(left.createdAt);
}

/** The mock ride repository. */
export class MockRideRepository implements RideRepository {
  private readonly latencyMs: number;

  private readonly clock: () => number;

  constructor(options: MockRideOptions = {}) {
    this.latencyMs = resolveLatency({ latencyMs: options.latencyMs });
    this.clock = options.now ?? (() => Date.now());
  }

  /** Simulated network latency. */
  private async simulateLatency(): Promise<void> {
    await mockDelay(this.latencyMs);
  }

  /** The current time as an ISO timestamp. */
  private nowIso(): string {
    return new Date(this.clock()).toISOString();
  }

  /**
   * Append a notification for a status change.
   *
   * The id is derived from the ride and the status, so the same change never
   * produces a second notification.
   */
  private touchNotification(
    db: MockDb,
    userId: string,
    input: { rideId: string; status: RideStatus; title: string; body: string },
  ): void {
    const id = `notif-${input.rideId}-${input.status}`;
    if (db.notifications.some((notification) => notification.id === id)) return;

    const notification: StoredNotification = {
      id,
      kind: 'ride',
      title: input.title,
      body: input.body,
      createdAt: this.nowIso(),
      read: false,
      userId,
    };
    db.notifications.push(notification);
  }

  /** The notification of a status change. */
  private notificationFor(ride: Ride): {
    rideId: string;
    status: RideStatus;
    title: string;
    body: string;
  } {
    switch (ride.status) {
      case 'driverAssigned':
        return {
          rideId: ride.id,
          status: ride.status,
          title: bookingStatusCopy.driverAssigned.label,
          body: ride.driver
            ? `${ride.driver.name} is on the way to your pickup point.`
            : 'A driver is on the way to your pickup point.',
        };
      case 'cancelled':
        return {
          rideId: ride.id,
          status: ride.status,
          title: bookingStatusCopy.cancelled.label,
          body: 'Your ride was cancelled. No cancellation fee applies.',
        };
      case 'tripCompleted':
        return {
          rideId: ride.id,
          status: ride.status,
          title: bookingStatusCopy.tripCompleted.label,
          body: `Your fare for this ride is ${formatINR(ride.fare.total)}.`,
        };
      case 'rated':
        return {
          rideId: ride.id,
          status: ride.status,
          title: bookingStatusCopy.rated.label,
          body: 'Thanks for your feedback.',
        };
      default:
        return {
          rideId: ride.id,
          status: ride.status,
          title: bookingStatusCopy[ride.status].label,
          body: 'Your ride was updated.',
        };
    }
  }

  /**
   * Validate a ride and write it to the database.
   *
   * When the status changed, the matching notification is appended.
   */
  private persist(ride: Ride, previousStatus?: RideStatus): Result<Ride> {
    const validated = rideSchema.safeParse(ride);
    if (!validated.success) {
      return failure('unknown', `The ride "${ride.id}" is not valid and was not saved.`);
    }

    updateDb((db) => {
      const index = db.rides.findIndex((candidate) => candidate.id === ride.id);
      if (index === -1) {
        db.rides.push(ride);
      } else {
        db.rides[index] = ride;
      }

      const changed = previousStatus !== undefined && previousStatus !== ride.status;
      if (changed && NOTIFIED_STATUSES.includes(ride.status)) {
        this.touchNotification(db, ride.userId, this.notificationFor(ride));
      }
    });

    return { ok: true, data: ride };
  }

  async create(input: {
    userId: string;
    pickup: Ride['pickup'];
    destination: Ride['destination'];
    vehicle: Ride['vehicle'];
    fare: Ride['fare'];
    paymentMethodId: string;
  }): Promise<Result<Ride>> {
    await this.simulateLatency();

    const now = this.nowIso();
    const ride: Ride = {
      id: newId('ride'),
      userId: input.userId,
      pickup: input.pickup,
      destination: input.destination,
      vehicle: input.vehicle,
      fare: input.fare,
      status: 'confirmingBooking',
      paymentMethodId: input.paymentMethodId,
      createdAt: now,
      phaseStartedAt: now,
      timeline: [{ status: 'confirmingBooking', at: now }],
    };

    const validated = rideSchema.safeParse(ride);
    if (!validated.success) {
      return failure('unknown', 'The new ride could not be created: the data is not valid.');
    }

    updateDb((db) => {
      db.rides.push(ride);
    });

    return { ok: true, data: ride };
  }

  async save(ride: Ride): Promise<Result<Ride>> {
    await this.simulateLatency();

    const previous = loadDb().rides.find((candidate) => candidate.id === ride.id);
    return this.persist(ride, previous?.status);
  }

  async getActive(userId: string): Promise<Result<Ride | null>> {
    await this.simulateLatency();

    const rides = loadDb()
      .rides.filter((ride) => ride.userId === userId && LIVE_STATUSES.includes(ride.status))
      .sort(byCreatedAtDesc);

    return { ok: true, data: rides.length > 0 ? rides[0] : null };
  }

  async getById(rideId: string): Promise<Result<Ride>> {
    await this.simulateLatency();

    const ride = loadDb().rides.find((candidate) => candidate.id === rideId);
    if (!ride) return failure('not_found', `The ride "${rideId}" was not found.`);

    return { ok: true, data: ride };
  }

  async list(userId: string, filter: RideFilter = 'all'): Promise<Result<Ride[]>> {
    await this.simulateLatency();

    const statuses =
      filter === 'completed' ? COMPLETED_STATUSES : filter === 'cancelled' ? CANCELLED_STATUSES : HISTORY_STATUSES;

    const rides = loadDb()
      .rides.filter((ride) => ride.userId === userId && statuses.includes(ride.status))
      .sort(byCreatedAtDesc);

    return { ok: true, data: rides };
  }

  async cancel(rideId: string, reason: CancellationReason): Promise<Result<Ride>> {
    await this.simulateLatency();

    const ride = loadDb().rides.find((candidate) => candidate.id === rideId);
    if (!ride) return failure('not_found', `The ride "${rideId}" was not found.`);
    if (!isCancelableStatus(ride.status)) {
      return failure(
        'invalid_transition',
        `A ride in the status "${ride.status}" cannot be cancelled.`,
      );
    }

    const transitioned = transitionRide(ride, 'cancelled', this.nowIso());
    if (!transitioned.ok) return transitioned;

    const cancelled: Ride = { ...transitioned.data, cancellationReason: reason };
    return this.persist(cancelled, ride.status);
  }

  async rate(rideId: string, rating: Rating): Promise<Result<Ride>> {
    await this.simulateLatency();

    const ride = loadDb().rides.find((candidate) => candidate.id === rideId);
    if (!ride) return failure('not_found', `The ride "${rideId}" was not found.`);
    if (ride.status !== 'awaitingRating') {
      return failure(
        'invalid_transition',
        `Only a ride awaiting a rating can be rated (this one is "${ride.status}").`,
      );
    }

    const validated = ratingSchema.safeParse({ ...rating, rideId });
    if (!validated.success) {
      return failure('unknown', 'The rating is not valid and was not saved.', 'rating');
    }

    const transitioned = transitionRide(ride, 'rated', this.nowIso());
    if (!transitioned.ok) return transitioned;

    const rated: Ride = { ...transitioned.data, rating: validated.data };
    return this.persist(rated, ride.status);
  }
}

/** Create a repository, e.g. with a deterministic clock for tests. */
export function createMockRideRepository(options?: MockRideOptions): MockRideRepository {
  return new MockRideRepository(options);
}
