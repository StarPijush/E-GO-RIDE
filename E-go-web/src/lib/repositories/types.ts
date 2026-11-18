/**
 * Repository interfaces.
 *
 * Screens and stores talk to these interfaces only; the mock adapters live in
 * `lib/mock/*`. A future HTTP adapter implements the same interfaces, so the
 * swap is additive (architecture §6).
 *
 * Repositories never throw for expected failures: every operation returns a
 * `Result` from `lib/domain/types`.
 */

import type {
  AppNotification,
  AuthSession,
  CancellationReason,
  FareBreakdown,
  PaymentMethod,
  Place,
  Rating,
  Result,
  Ride,
  RideFilter,
  SavedPlace,
  User,
  VehicleType,
} from '@/lib/domain/types';

export type { Result } from '@/lib/domain/types';

/** Input of {@link AuthRepository.register}. */
export interface RegisterInput {
  fullName: string;
  phone: string;
  email?: string;
  password: string;
}

/** Patch of {@link AuthRepository.updateProfile}. */
export interface ProfilePatch {
  fullName?: string;
  email?: string;
  avatarUrl?: string;
}

/** Result of {@link AuthRepository.requestOtp}. */
export interface OtpRequestResult {
  /** Seconds the user has to wait before another code may be requested. */
  cooldownSeconds: number;
  /**
   * The generated code. Only returned by the mock adapters so the demo UI can
   * show it - a real API never returns the code it sent.
   */
  devOtp?: string;
}

/** A signed-in user with a session. */
export interface AuthResult {
  user: User;
  session: AuthSession;
}

/** Result of {@link AuthRepository.verifyOtp}. */
export interface OtpVerifyResult extends AuthResult {
  /** True when the account still has to complete its profile. */
  isNewUser: boolean;
}

/** Authentication, session and profile. */
export interface AuthRepository {
  /** Request an OTP; fails with `otp_cooldown` while the cooldown runs. */
  requestOtp(phone: string): Promise<Result<OtpRequestResult>>;
  /** Verify an OTP and start a session. */
  verifyOtp(phone: string, code: string): Promise<Result<OtpVerifyResult>>;
  /** Sign in with phone number and password. */
  login(phone: string, password: string): Promise<Result<AuthResult>>;
  /** Create an account; the session starts after the OTP is verified. */
  register(input: RegisterInput): Promise<Result<{ phone: string }>>;
  /** Update the profile of a user and mark the profile as complete. */
  updateProfile(userId: string, patch: ProfilePatch): Promise<Result<User>>;
  /** End the session (the store clears the persisted session). */
  logout(): Promise<Result<null>>;
}

/** Rides and their lifecycle. */
export interface RideRepository {
  create(input: {
    userId: string;
    pickup: Place;
    destination: Place;
    vehicle: VehicleType;
    fare: FareBreakdown;
    paymentMethodId: string;
  }): Promise<Result<Ride>>;
  /** Persist a ride changed by the orchestrator. */
  save(ride: Ride): Promise<Result<Ride>>;
  /** The ride that is currently active for a user. */
  getActive(userId: string): Promise<Result<Ride | null>>;
  getById(rideId: string): Promise<Result<Ride>>;
  list(userId: string, filter?: RideFilter): Promise<Result<Ride[]>>;
  cancel(rideId: string, reason: CancellationReason): Promise<Result<Ride>>;
  rate(rideId: string, rating: Rating): Promise<Result<Ride>>;
}

/** Place search and saved places. */
export interface PlacesRepository {
  search(query: string): Promise<Result<Place[]>>;
  listSaved(userId: string): Promise<Result<SavedPlace[]>>;
  save(userId: string, place: Place, tag: SavedPlace['tag']): Promise<Result<SavedPlace>>;
  remove(userId: string, savedId: string): Promise<Result<null>>;
}

/** (Mock) payment methods. */
export interface PaymentRepository {
  list(userId: string): Promise<Result<PaymentMethod[]>>;
  add(userId: string, method: Omit<PaymentMethod, 'id'>): Promise<Result<PaymentMethod>>;
  remove(userId: string, id: string): Promise<Result<null>>;
  setDefault(userId: string, id: string): Promise<Result<PaymentMethod[]>>;
}

/** (Mock) notifications. */
export interface NotificationRepository {
  list(userId: string): Promise<Result<AppNotification[]>>;
  markRead(userId: string, id: string): Promise<Result<AppNotification[]>>;
  markAllRead(userId: string): Promise<Result<AppNotification[]>>;
}
