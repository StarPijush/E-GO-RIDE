/**
 * The authentication store.
 *
 * The store owns the user, the session and the onboarding flag. The data
 * itself lives in the repositories - the store never caches anything else and
 * never reads the storage at module scope.
 *
 * The store is persisted under `ego:auth:v1` with the shared persist storage,
 * so a corrupt payload is archived and the app starts signed out instead of
 * crashing.
 */

import { create } from 'zustand';
import { persist } from 'zustand/middleware';

import { STORAGE_KEYS } from '@/lib/config/constants';
import { persistedAuthSchema } from '@/lib/domain/schemas';
import type { AppError, AuthSession, Result, User } from '@/lib/domain/types';
import { getRepositories } from '@/lib/repositories';
import type {
  AuthResult,
  OtpRequestResult,
  OtpVerifyResult,
  ProfilePatch,
  RegisterInput,
} from '@/lib/repositories/types';
import { createEgoPersistStorage } from '@/stores/persist-storage';

/** The state of the authentication. */
export interface AuthState {
  user: User | null;
  session: AuthSession | null;
  onboardingSeen: boolean;
  /** True once the persisted state was read (the gates wait for it). */
  hasHydrated: boolean;
  /** The running request, if any. */
  pending: 'login' | 'register' | 'requestOtp' | 'verifyOtp' | 'profile' | null;
  lastError: AppError | null;
  /** Epoch milliseconds until another OTP may be requested. */
  otpCooldownUntil: number | null;
}

/** The actions of the authentication store. */
export interface AuthActions {
  login(phone: string, password: string): Promise<Result<AuthResult>>;
  register(input: RegisterInput): Promise<Result<{ phone: string }>>;
  requestOtp(phone: string): Promise<Result<OtpRequestResult>>;
  verifyOtp(phone: string, code: string): Promise<Result<OtpVerifyResult>>;
  updateProfile(patch: ProfilePatch): Promise<Result<User>>;
  logout(): Promise<Result<null>>;
  /** Forget the session without touching the mock database. */
  expireSession(): void;
  /** Expire the session when it is over. Returns true when it expired. */
  expireIfNeeded(): Promise<boolean>;
  setOnboardingSeen(): void;
  clearError(): void;
  hasValidSession(): boolean;
  setHasHydrated(value: boolean): void;
}

/** The complete store. */
export type AuthStore = AuthState & AuthActions;

/** The error of an unexpected failure. */
const UNKNOWN_ERROR: AppError = {
  code: 'unknown',
  message: 'Something went wrong. Please try again.',
};

const initialState: AuthState = {
  user: null,
  session: null,
  onboardingSeen: false,
  hasHydrated: false,
  pending: null,
  lastError: null,
  otpCooldownUntil: null,
};

export const useAuthStore = create<AuthStore>()(
  persist(
    (set, get) => ({
      ...initialState,

      login: async (phone, password) => {
        set({ pending: 'login', lastError: null });
        try {
          const result = await getRepositories().auth.login(phone, password);
          if (!result.ok) {
            set({ lastError: result.error });
            return result;
          }
          set({
            user: result.data.user,
            session: result.data.session,
            onboardingSeen: true,
            lastError: null,
          });
          return result;
        } catch {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        } finally {
          set({ pending: null });
        }
      },

      register: async (input) => {
        set({ pending: 'register', lastError: null });
        try {
          const result = await getRepositories().auth.register(input);
          if (!result.ok) {
            set({ lastError: result.error });
            return result;
          }
          set({ lastError: null });
          return result;
        } catch {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        } finally {
          set({ pending: null });
        }
      },

      requestOtp: async (phone) => {
        set({ pending: 'requestOtp', lastError: null });
        try {
          const result = await getRepositories().auth.requestOtp(phone);
          if (!result.ok) {
            set({ lastError: result.error });
            return result;
          }
          set({
            otpCooldownUntil: Date.now() + result.data.cooldownSeconds * 1000,
            lastError: null,
          });
          return result;
        } catch {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        } finally {
          set({ pending: null });
        }
      },

      verifyOtp: async (phone, code) => {
        set({ pending: 'verifyOtp', lastError: null });
        try {
          const result = await getRepositories().auth.verifyOtp(phone, code);
          if (!result.ok) {
            set({ lastError: result.error });
            return result;
          }
          set({
            user: result.data.user,
            session: result.data.session,
            onboardingSeen: true,
            lastError: null,
          });
          return result;
        } catch {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        } finally {
          set({ pending: null });
        }
      },

      updateProfile: async (patch) => {
        const user = get().user;
        if (!user) {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        }

        set({ pending: 'profile', lastError: null });
        try {
          const result = await getRepositories().auth.updateProfile(user.id, patch);
          if (!result.ok) {
            set({ lastError: result.error });
            return result;
          }
          set({ user: result.data, lastError: null });
          return result;
        } catch {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        } finally {
          set({ pending: null });
        }
      },

      logout: async () => {
        set({ lastError: null });
        try {
          const result = await getRepositories().auth.logout();
          set({
            user: null,
            session: null,
            onboardingSeen: true,
            otpCooldownUntil: null,
            lastError: null,
          });

          // The booking store is imported lazily: it would be a cycle here.
          try {
            const { useBookingStore } = await import('@/stores/booking-store');
            useBookingStore.getState().resetForLogout();
          } catch {
            // No booking store (yet) - nothing to reset.
          }

          return result;
        } catch {
          set({ lastError: UNKNOWN_ERROR });
          return { ok: false, error: UNKNOWN_ERROR };
        }
      },

      expireSession: () => {
        set({
          user: null,
          session: null,
          otpCooldownUntil: null,
          lastError: null,
        });
      },

      expireIfNeeded: async () => {
        const session = get().session;
        if (!session) return false;
        if (Date.parse(session.expiresAt) > Date.now()) return false;

        get().expireSession();
        return true;
      },

      setOnboardingSeen: () => {
        set({ onboardingSeen: true });
      },

      clearError: () => {
        set({ lastError: null });
      },

      hasValidSession: () => {
        const session = get().session;
        if (!session) return false;
        return Date.parse(session.expiresAt) > Date.now();
      },

      setHasHydrated: (value: boolean) => {
        set({ hasHydrated: value });
      },
    }),
    {
      name: STORAGE_KEYS.auth,
      storage: createEgoPersistStorage(STORAGE_KEYS.auth, persistedAuthSchema),
      skipHydration: true,
      partialize: (state) => ({
        user: state.user,
        session: state.session,
        onboardingSeen: state.onboardingSeen,
      }),
      version: 1,
    },
  ),
);
