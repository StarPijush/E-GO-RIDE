/**
 * Canonical E-GO Web domain types.
 *
 * This module is the single source of truth for the domain layer: stores,
 * repositories and mock implementations must speak these types.
 *
 * Conventions (enforced by the whole app):
 * - Money is always an integer number of rupees, never a float.
 * - Coordinates are plain numbers (WGS84 degrees).
 * - Timestamps are ISO-8601 strings (`new Date().toISOString()`).
 * - Identifiers are strings (`crypto.randomUUID()` for new records).
 */

/** Vehicles E-GO offers. */
export const VEHICLE_TYPES = ['bike', 'toto'] as const;
export type VehicleType = (typeof VEHICLE_TYPES)[number];

/**
 * The canonical booking/ride lifecycle (16 states).
 * Line-for-line port of `E-go/lib/core/booking_state.dart`.
 */
export const BOOKING_STATUSES = [
  'idle',
  'selectingPickup',
  'selectingDestination',
  'selectingVehicle',
  'reviewingFare',
  'confirmingBooking',
  'searchingDriver',
  'driverAssigned',
  'driverArriving',
  'driverArrived',
  'tripInProgress',
  'tripCompleted',
  'awaitingRating',
  'rated',
  'cancelled',
  'failed',
] as const;
export type BookingStatus = (typeof BOOKING_STATUSES)[number];

/** Single canonical status enum for rides (rides and bookings share one FSM). */
export type RideStatus = BookingStatus;

/** Payment methods known to the app. Only `cash` is selectable today (A9). */
export const PAYMENT_METHOD_TYPES = ['cash', 'upi', 'card', 'wallet'] as const;
export type PaymentMethodType = (typeof PAYMENT_METHOD_TYPES)[number];

export interface LatLng {
  lat: number;
  lng: number;
}

export interface Place extends LatLng {
  id: string;
  label: string;
  address: string;
  kind: 'pickup' | 'destination' | 'saved' | 'poi';
}

export interface SavedPlace extends Place {
  savedId: string;
  tag: 'home' | 'work' | 'other';
}

export interface User {
  id: string;
  fullName: string;
  phone: string;
  email?: string;
  avatarUrl?: string;
  profileComplete: boolean;
  /** ISO timestamp. */
  createdAt: string;
}

export interface AuthSession {
  userId: string;
  token: string;
  /** ISO timestamp. */
  issuedAt: string;
  /** ISO timestamp. */
  expiresAt: string;
}

export interface VehicleOption {
  type: VehicleType;
  name: string;
  description: string;
  capacity: number;
  estimatedArrivalMinutes: number;
  /** Total fare in whole rupees. */
  fare: number;
}

export interface FareBreakdown {
  vehicle: VehicleType;
  baseFare: number;
  distanceFare: number;
  platformFee: number;
  /** baseFare + distanceFare + platformFee, in whole rupees. */
  total: number;
  /** Effective distance rounded to 1 decimal, for display only. */
  distanceKm: number;
  estimatedMinutes: number;
  estimatedArrivalMinutes: number;
  currency: 'INR';
}

export interface Driver {
  id: string;
  name: string;
  rating: number;
  ridesCompleted: number;
  vehicleType: VehicleType;
  vehicleModel: string;
  vehicleNumber: string;
  location: LatLng;
  etaMinutes: number;
}

export interface Rating {
  rideId: string;
  stars: 1 | 2 | 3 | 4 | 5;
  comment?: string;
  tags: string[];
  /** ISO timestamp. */
  createdAt: string;
}

export interface PaymentMethod {
  id: string;
  type: PaymentMethodType;
  label: string;
  masked?: string;
  isDefault: boolean;
}

/** One entry of a ride's status timeline. */
export interface RideTimelineEvent {
  status: RideStatus;
  /** ISO timestamp of the transition. */
  at: string;
}

export interface Ride {
  id: string;
  userId: string;
  pickup: Place;
  destination: Place;
  vehicle: VehicleType;
  fare: FareBreakdown;
  status: RideStatus;
  driver?: Driver;
  paymentMethodId: string;
  /** ISO timestamp the ride was created. */
  createdAt: string;
  /** ISO timestamp the current phase started. */
  phaseStartedAt: string;
  /** ISO timestamp the next simulated transition is due, when one is scheduled. */
  nextTransitionAt?: string;
  /** ISO timestamp, set once the trip completed. */
  completedAt?: string;
  /** ISO timestamp, set when the ride was cancelled. */
  cancelledAt?: string;
  cancellationReason?: CancellationReason;
  rating?: Rating;
  timeline: RideTimelineEvent[];
}

export interface BookingDraft {
  pickup?: Place;
  destination?: Place;
  vehicle?: VehicleType;
  fare?: FareBreakdown;
  paymentMethodId?: string;
}

export interface AppNotification {
  id: string;
  kind: 'ride' | 'payment' | 'promo' | 'system';
  title: string;
  body: string;
  /** ISO timestamp. */
  createdAt: string;
  read: boolean;
}

export type CancellationReason =
  | 'driver_too_far'
  | 'waiting_too_long'
  | 'changed_plan'
  | 'other';

export type AppErrorCode =
  | 'invalid_phone'
  | 'invalid_otp'
  | 'otp_expired'
  | 'otp_cooldown'
  | 'invalid_credentials'
  | 'account_exists'
  | 'not_found'
  | 'invalid_transition'
  | 'storage_corrupt'
  | 'demo_disabled'
  | 'unknown';

export interface AppError {
  code: AppErrorCode;
  message: string;
  /** Optional form field the error belongs to. */
  field?: string;
}

/**
 * Result of any operation that can fail with an expected error.
 * Repositories never throw for expected failures (architecture §6).
 */
export type Result<T> = { ok: true; data: T } | { ok: false; error: AppError };

/** Filters offered by "My Rides" (A10). */
export type RideFilter = 'all' | 'completed' | 'cancelled';
