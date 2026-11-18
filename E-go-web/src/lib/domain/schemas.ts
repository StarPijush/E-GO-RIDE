/**
 * Zod 4 schemas for every persisted entity and every form input.
 *
 * The schemas mirror `src/lib/domain/types.ts` - the types stay the single
 * source of truth for the shapes, the schemas validate them at every trust
 * boundary (forms, repository inputs, persisted payloads).
 *
 * Rules that are ported from Flutter live here:
 * - phone normalization (`utils/phone.ts`, a port of `AuthValidators`);
 * - registration password: at least 8 characters and not whitespace only;
 * - login password: any non-empty input (the repository decides);
 * - email: the same pattern as `AuthValidators.isValidEmail`.
 */

import { z } from 'zod';

import { SCHEMA_VERSION } from '@/lib/config/constants';
import {
  BOOKING_STATUSES,
  PAYMENT_METHOD_TYPES,
  VEHICLE_TYPES,
  type BookingStatus,
  type CancellationReason,
} from '@/lib/domain/types';
import { normalizePhone } from '@/lib/utils/phone';

/** Runtime mirror of the `CancellationReason` union in `types.ts`. */
export const CANCELLATION_REASONS = [
  'driver_too_far',
  'waiting_too_long',
  'changed_plan',
  'other',
] as const satisfies readonly CancellationReason[];

/** Copy for an invalid phone number (ported from the Flutter validators). */
export const PHONE_ERROR_MESSAGE = 'Please enter a valid 10-digit mobile number.';

/** Email pattern, ported from `AuthValidators.isValidEmail`. */
export const EMAIL_PATTERN = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

/**
 * A phone number, normalized to E.164 (`+919000000001`).
 * Invalid input fails validation.
 */
export const phoneSchema = z
  .string()
  .transform((value) => normalizePhone(value) ?? '')
  .refine((value) => value.length > 0, { message: PHONE_ERROR_MESSAGE });

/** Exactly six digits. */
export const otpSchema = z
  .string()
  .regex(/^\d{6}$/, { message: 'Please enter the 6-digit OTP.' });

/** Registration policy: at least 8 characters and not whitespace only. */
export const registrationPasswordSchema = z
  .string()
  .min(8, { message: 'Password must be at least 8 characters.' })
  .refine((value) => value.trim().length > 0, { message: 'Password must be at least 8 characters.' });

/** Login policy: any non-empty input, the repository decides. */
export const loginPasswordSchema = z
  .string()
  .min(1, { message: 'Please enter your password.' });

/** A valid email address. */
export const emailSchema = z
  .string()
  .trim()
  .regex(EMAIL_PATTERN, { message: 'Please enter a valid email address.' });

/** An optional email: an empty string is treated as "not set". */
export const optionalEmailSchema = z.preprocess(
  (value) => (typeof value === 'string' && value.trim() === '' ? undefined : value),
  emailSchema.optional(),
);

/** A geographic coordinate pair. */
export const latLngSchema = z.object({
  lat: z.number().finite().min(-90).max(90),
  lng: z.number().finite().min(-180).max(180),
});

/** A named location. */
export const placeSchema = z.object({
  id: z.string().min(1),
  label: z.string().min(1),
  address: z.string().min(1),
  kind: z.enum(['pickup', 'destination', 'saved', 'poi']),
  lat: latLngSchema.shape.lat,
  lng: latLngSchema.shape.lng,
});

/** A place the user saved for later. */
export const savedPlaceSchema = placeSchema.extend({
  savedId: z.string().min(1),
  tag: z.enum(['home', 'work', 'other']),
});

/** A user profile. */
export const userSchema = z.object({
  id: z.string().min(1),
  fullName: z.string().min(1),
  phone: phoneSchema,
  email: optionalEmailSchema,
  avatarUrl: z.string().min(1).optional(),
  profileComplete: z.boolean(),
  createdAt: z.iso.datetime(),
});

/** A session; the expiry must be after the issue time. */
export const authSessionSchema = z
  .object({
    userId: z.string().min(1),
    token: z.string().min(1),
    issuedAt: z.iso.datetime(),
    expiresAt: z.iso.datetime(),
  })
  .superRefine((session, ctx) => {
    if (Date.parse(session.expiresAt) <= Date.parse(session.issuedAt)) {
      ctx.addIssue({
        code: 'custom',
        path: ['expiresAt'],
        message: 'Session expiry must be after the issue time.',
      });
    }
  });

/** The fare of a ride, in whole rupees. */
export const fareBreakdownSchema = z
  .object({
    vehicle: z.enum(VEHICLE_TYPES),
    baseFare: z.number().int().min(0),
    distanceFare: z.number().int().min(0),
    platformFee: z.number().int().min(0),
    total: z.number().int().min(0),
    distanceKm: z.number().min(0.5),
    estimatedMinutes: z.number().int().min(0),
    estimatedArrivalMinutes: z.number().int().min(0),
    currency: z.literal('INR'),
  })
  .superRefine((fare, ctx) => {
    const sum = fare.baseFare + fare.distanceFare + fare.platformFee;
    if (fare.total !== sum) {
      ctx.addIssue({
        code: 'custom',
        path: ['total'],
        message: 'Total fare must equal base fare + distance fare + platform fee.',
      });
    }
  });

/** A simulated driver. */
export const driverSchema = z.object({
  id: z.string().min(1),
  name: z.string().min(1),
  rating: z.number().min(0).max(5),
  ridesCompleted: z.number().int().min(0),
  vehicleType: z.enum(VEHICLE_TYPES),
  vehicleModel: z.string().min(1),
  vehicleNumber: z.string().min(1),
  location: latLngSchema,
  etaMinutes: z.number().int().min(0),
});

/** A passenger rating. */
export const ratingSchema = z.object({
  rideId: z.string().min(1),
  stars: z.union([z.literal(1), z.literal(2), z.literal(3), z.literal(4), z.literal(5)]),
  comment: z.string().max(300).optional(),
  tags: z.array(z.string()).max(5),
  createdAt: z.iso.datetime(),
});

/** A (mock) payment method. */
export const paymentMethodSchema = z.object({
  id: z.string().min(1),
  type: z.enum(PAYMENT_METHOD_TYPES),
  label: z.string().min(1),
  masked: z.string().min(1).optional(),
  isDefault: z.boolean(),
});

/** An in-app notification. */
export const notificationSchema = z.object({
  id: z.string().min(1),
  kind: z.enum(['ride', 'payment', 'promo', 'system']),
  title: z.string().min(1),
  body: z.string().min(1),
  createdAt: z.iso.datetime(),
  read: z.boolean(),
});

/** One entry of a ride timeline. */
export const rideTimelineEventSchema = z.object({
  status: z.enum(BOOKING_STATUSES),
  at: z.iso.datetime(),
});

/** The timeline of a ride. */
export const rideTimelineSchema = z.array(rideTimelineEventSchema).min(1);

/**
 * A ride.
 *
 * Terminal consistency (architecture §4):
 * - `completedAt` is required for `tripCompleted`, `awaitingRating` and `rated`;
 * - a `rating` may only exist on a `rated` ride (skipping the rating is
 *   allowed, so it is not required);
 * - `cancelledAt` may only exist on a `cancelled` ride.
 */
export const rideSchema = z
  .object({
    id: z.string().min(1),
    userId: z.string().min(1),
    pickup: placeSchema,
    destination: placeSchema,
    vehicle: z.enum(VEHICLE_TYPES),
    fare: fareBreakdownSchema,
    status: z.enum(BOOKING_STATUSES),
    driver: driverSchema.optional(),
    paymentMethodId: z.string().min(1),
    createdAt: z.iso.datetime(),
    phaseStartedAt: z.iso.datetime(),
    nextTransitionAt: z.iso.datetime().optional(),
    completedAt: z.iso.datetime().optional(),
    cancelledAt: z.iso.datetime().optional(),
    cancellationReason: z.enum(CANCELLATION_REASONS).optional(),
    rating: ratingSchema.optional(),
    timeline: rideTimelineSchema,
  })
  .superRefine((ride, ctx) => {
    const isCompleted =
      ride.status === 'tripCompleted' || ride.status === 'awaitingRating' || ride.status === 'rated';

    if (isCompleted && !ride.completedAt) {
      ctx.addIssue({
        code: 'custom',
        path: ['completedAt'],
        message: `A "${ride.status}" ride must carry a completion timestamp.`,
      });
    }
    if (ride.status !== 'rated' && ride.rating) {
      ctx.addIssue({
        code: 'custom',
        path: ['rating'],
        message: 'Only a rated ride may carry a rating.',
      });
    }
    if (ride.status !== 'cancelled' && ride.cancelledAt) {
      ctx.addIssue({
        code: 'custom',
        path: ['cancelledAt'],
        message: 'Only a cancelled ride may carry a cancellation timestamp.',
      });
    }
  });

/** The in-progress booking. */
export const bookingDraftSchema = z.object({
  pickup: placeSchema.optional(),
  destination: placeSchema.optional(),
  vehicle: z.enum(VEHICLE_TYPES).optional(),
  fare: fareBreakdownSchema.optional(),
  paymentMethodId: z.string().min(1).optional(),
});

/** Wrap a payload with the schema version it was written with. */
export function persistedEnvelope<T extends z.ZodType>(data: T) {
  return z.object({
    schemaVersion: z.literal(SCHEMA_VERSION),
    data,
  });
}

/**
 * The payload persisted under `ego:auth:v1`.
 *
 * `session` and `user` are nullable - a signed-out app still persists the
 * onboarding flag - but they are never half-populated: either both are
 * present or both are `null`.
 */
export const persistedAuthSchema = persistedEnvelope(
  z
    .object({
      session: authSessionSchema.nullable(),
      user: userSchema.nullable(),
      onboardingSeen: z.boolean(),
    })
    .refine((value) => (value.session === null) === (value.user === null), {
      message: 'A persisted session and user must be present together.',
    }),
);

/**
 * The payload persisted under `ego:booking:v1`.
 *
 * The booking status and the active ride must agree: a live status always
 * carries its ride, and a ride is never in another status than the booking.
 */
export const persistedBookingSchema = persistedEnvelope(
  z
    .object({
      status: z.enum(BOOKING_STATUSES),
      draft: bookingDraftSchema,
      activeRide: rideSchema.nullable(),
    })
    .superRefine((value, ctx) => {
      if (value.activeRide && value.activeRide.status !== value.status) {
        ctx.addIssue({
          code: 'custom',
          path: ['status'],
          message: 'Active ride status must match the booking status.',
        });
      }

      const live: readonly BookingStatus[] = [
        'searchingDriver',
        'driverAssigned',
        'driverArriving',
        'driverArrived',
        'tripInProgress',
        'tripCompleted',
        'awaitingRating',
      ];
      if (live.includes(value.status) && !value.activeRide) {
        ctx.addIssue({
          code: 'custom',
          path: ['activeRide'],
          message: 'A live booking status requires an active ride.',
        });
      }
    }),
);

/** The payload persisted under `ego:prefs:v1`. */
export const persistedPreferencesSchema = persistedEnvelope(
  z.object({
    notifications: z.boolean(),
    reducedMotion: z.boolean(),
  }),
);

export type PhoneInput = z.input<typeof phoneSchema>;
export type OtpInput = z.infer<typeof otpSchema>;
export type UserInput = z.input<typeof userSchema>;
export type User = z.infer<typeof userSchema>;
export type AuthSession = z.infer<typeof authSessionSchema>;
export type LatLng = z.infer<typeof latLngSchema>;
export type Place = z.infer<typeof placeSchema>;
export type SavedPlace = z.infer<typeof savedPlaceSchema>;
export type FareBreakdown = z.infer<typeof fareBreakdownSchema>;
export type Driver = z.infer<typeof driverSchema>;
export type Rating = z.infer<typeof ratingSchema>;
export type PaymentMethod = z.infer<typeof paymentMethodSchema>;
export type Notification = z.infer<typeof notificationSchema>;
export type RideTimelineEvent = z.infer<typeof rideTimelineEventSchema>;
export type Ride = z.infer<typeof rideSchema>;
export type BookingDraft = z.infer<typeof bookingDraftSchema>;
export type PersistedAuth = z.infer<typeof persistedAuthSchema>;
export type PersistedBooking = z.infer<typeof persistedBookingSchema>;
export type PersistedPreferences = z.infer<typeof persistedPreferencesSchema>;
