/**
 * Mock authentication repository.
 *
 * DEVELOPMENT ONLY - there is no backend, no SMS gateway and no real
 * session. Everything lives in the browser: accounts in the mock DB
 * (`ego:db:v1`), OTP codes in memory.
 *
 * Passwords are never stored in plain text: only a salted PBKDF2-SHA-256
 * hash (Web Crypto) is written to the database. The comparison is a
 * length + XOR loop, which is good enough for a demo and no more than a
 * mock should pretend to be.
 *
 * The demo account is seeded lazily (on the first call) and only while demo
 * mode is enabled. Codes are always random. Outside demo mode the generated
 * code is returned as `devOtp` so the UI can show it in place of an SMS; in
 * demo mode the fixed code is verified against its PBKDF2 verifier and shown
 * by the server-provided hint instead.
 */

import {
  MAX_OTP_ATTEMPTS,
  OTP_COOLDOWN_SECONDS,
  OTP_EXPIRY_MINUTES,
  SESSION_TTL_DAYS,
} from '@/lib/config/constants';
import { authErrorMessages } from '@/lib/domain/labels';
import { emailSchema } from '@/lib/domain/schemas';
import type { AppErrorCode, AuthSession, Result, User } from '@/lib/domain/types';
import {
  DEMO_OTP_VERIFIER,
  DEMO_PASSWORD_VERIFIER,
  isDemoMode,
} from '@/lib/mock/demo-credentials';
import { loadDb, saveDb, type MockAccount } from '@/lib/mock/db';
import { mockDelay, resolveLatency } from '@/lib/mock/mock-delay';
import { DEMO_PHONE_E164, DEMO_USER, ensureDemoSeedData } from '@/lib/mock/seeds';
import type {
  AuthRepository,
  AuthResult,
  OtpRequestResult,
  OtpVerifyResult,
  ProfilePatch,
  RegisterInput,
} from '@/lib/repositories/types';
import { newId } from '@/lib/utils/id';
import { normalizePhone } from '@/lib/utils/phone';

/** User facing copy of the expected auth failures (sourced from the labels). */
export const AUTH_ERROR_MESSAGES = authErrorMessages;

/** Iterations of the mock password hashing (Web Crypto PBKDF2). */
const PBKDF2_ITERATIONS = 10_000;

/** Length of the random salt in bytes. */
const SALT_BYTES = 16;

/** The normalized phone number of the seeded demo account. */
const DEMO_NORMALIZED_PHONE = DEMO_PHONE_E164;

/** The in-flight demo seeding, shared by every repository instance. */
let demoSeedPromise: Promise<void> | null = null;

/** Options of the mock repository (used to make tests deterministic). */
export interface MockAuthOptions {
  /** Simulated latency in milliseconds. `0` disables the delay. */
  latencyMs?: number;
  /** Injectable clock, epoch milliseconds. */
  now?: () => number;
}

/** An issued OTP. Codes live in memory only, never in storage. */
interface OtpEntry {
  code: string;
  expiresAt: number;
  attempts: number;
  requestedAt: number;
}

function failure(code: AppErrorCode, message: string, field?: string): Result<never> {
  return { ok: false, error: field ? { code, message, field } : { code, message } };
}

function toHex(bytes: Uint8Array): string {
  return Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('');
}

function fromHex(hex: string): Uint8Array<ArrayBuffer> {
  const bytes = new Uint8Array(new ArrayBuffer(hex.length / 2));
  for (let index = 0; index < bytes.length; index += 1) {
    bytes[index] = Number.parseInt(hex.slice(index * 2, index * 2 + 2), 16);
  }
  return bytes;
}

function randomBytes(length: number): Uint8Array<ArrayBuffer> {
  const bytes = new Uint8Array(new ArrayBuffer(length));
  const webCrypto = globalThis.crypto;
  if (typeof webCrypto?.getRandomValues === 'function') {
    webCrypto.getRandomValues(bytes);
    return bytes;
  }
  for (let index = 0; index < length; index += 1) {
    bytes[index] = Math.floor(Math.random() * 256);
  }
  return bytes;
}

/** Length + XOR comparison; avoids leaking the position of a mismatch. */
function safeEqual(left: string, right: string): boolean {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let index = 0; index < left.length; index += 1) {
    difference |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return difference === 0;
}

/** A random six digit OTP code. */
function generateOtpCode(): string {
  const value = randomBytes(4);
  const number = new DataView(value.buffer).getUint32(0) % 1_000_000;
  return String(number).padStart(6, '0');
}

/** Derive the PBKDF2 hash of a password, or `null` when Web Crypto is missing. */
async function deriveHash(password: string, saltHex: string): Promise<string | null> {
  const subtle = globalThis.crypto?.subtle;
  if (!subtle) return null;
  const key = await subtle.importKey(
    'raw',
    new TextEncoder().encode(password),
    'PBKDF2',
    false,
    ['deriveBits'],
  );
  const bits = await subtle.deriveBits(
    { name: 'PBKDF2', salt: fromHex(saltHex), iterations: PBKDF2_ITERATIONS, hash: 'SHA-256' },
    key,
    256,
  );
  return toHex(new Uint8Array(bits));
}

/** Hash a password with a fresh random salt. */
async function hashPassword(password: string): Promise<{ salt: string; hash: string } | null> {
  const salt = toHex(randomBytes(SALT_BYTES));
  const hash = await deriveHash(password, salt);
  return hash === null ? null : { salt, hash };
}

/** Verify a password against a stored salt and hash. */
async function verifyPassword(
  password: string,
  salt: string,
  expectedHash: string,
): Promise<boolean> {
  const hash = await deriveHash(password, salt);
  return hash !== null && safeEqual(hash, expectedHash);
}

/** The mock auth repository. */
export class MockAuthRepository implements AuthRepository {
  private readonly latencyMs: number;

  private readonly clock: () => number;

  /** Issued OTPs, in memory only. */
  private readonly otpStore = new Map<string, OtpEntry>();

  constructor(options: MockAuthOptions = {}) {
    this.latencyMs = resolveLatency({ latencyMs: options.latencyMs });
    this.clock = options.now ?? (() => Date.now());
  }

  /** Simulated network latency. */
  private async simulateLatency(): Promise<void> {
    await mockDelay(this.latencyMs);
  }

  /**
   * Seed the demo account and the demo data once.
   *
   * The promise is shared by every repository instance of the tab, so
   * concurrent calls cannot seed twice. The database is only written when
   * something actually changed.
   */
  private ensureDemoAccount(): Promise<void> {
    if (!isDemoMode()) return Promise.resolve();
    if (demoSeedPromise) return demoSeedPromise;

    demoSeedPromise = this.runDemoSeed().catch((error: unknown) => {
      demoSeedPromise = null;
      throw error;
    });
    return demoSeedPromise;
  }

  /** Create the demo user, its account and the demo data. */
  private async runDemoSeed(): Promise<void> {
    const db = loadDb();
    let changed = ensureDemoSeedData(db);

    if (!db.accounts.some((account) => account.phone === DEMO_NORMALIZED_PHONE)) {
      const createdAt = new Date(this.clock()).toISOString();
      db.users.push({ ...DEMO_USER, createdAt });
      db.accounts.push({
        userId: DEMO_USER.id,
        phone: DEMO_NORMALIZED_PHONE,
        passwordSalt: DEMO_PASSWORD_VERIFIER.salt,
        passwordHash: DEMO_PASSWORD_VERIFIER.hash,
        profileComplete: true,
        createdAt,
      });
      changed = true;
    }

    if (changed) saveDb(db);
  }

  /** Create an opaque session for a user. */
  private createSession(userId: string): AuthSession {
    const issuedAtMs = this.clock();
    return {
      userId,
      token: newId('sess'),
      issuedAt: new Date(issuedAtMs).toISOString(),
      expiresAt: new Date(issuedAtMs + SESSION_TTL_DAYS * 24 * 60 * 60 * 1000).toISOString(),
    };
  }

  /** The account of a normalized phone number, if there is one. */
  private findAccount(phone: string): MockAccount | undefined {
    const db = loadDb();
    return db.accounts.find((candidate) => candidate.phone === phone);
  }

  /** Start a session for a verified account. */
  private completeOtpVerification(account: MockAccount): Result<OtpVerifyResult> {
    const db = loadDb();
    const stored = db.users.find((candidate) => candidate.id === account.userId);
    if (!stored) return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'phone');

    const user: User = { ...stored, profileComplete: account.profileComplete };
    return {
      ok: true,
      data: { user, session: this.createSession(user.id), isNewUser: !account.profileComplete },
    };
  }

  async requestOtp(phone: string): Promise<Result<OtpRequestResult>> {
    await this.simulateLatency();
    await this.ensureDemoAccount();

    const normalized = normalizePhone(phone);
    if (!normalized) return failure('invalid_phone', AUTH_ERROR_MESSAGES.invalidPhone, 'phone');

    // Only an existing account may receive a code.
    if (!this.findAccount(normalized)) {
      return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'phone');
    }

    const now = this.clock();
    const existing = this.otpStore.get(normalized);
    if (existing) {
      const remaining = OTP_COOLDOWN_SECONDS - Math.floor((now - existing.requestedAt) / 1000);
      if (remaining > 0) {
        return failure(
          'otp_cooldown',
          `Please wait ${remaining} second${remaining === 1 ? '' : 's'} before requesting another OTP.`,
          'otp',
        );
      }
    }

    const code = generateOtpCode();
    this.otpStore.set(normalized, {
      code,
      expiresAt: now + OTP_EXPIRY_MINUTES * 60 * 1000,
      attempts: 0,
      requestedAt: now,
    });

    // Demo mode has no `devOtp`: the UI receives the fixed demo code as a
    // server prop instead.
    return {
      ok: true,
      data: { cooldownSeconds: OTP_COOLDOWN_SECONDS, devOtp: isDemoMode() ? undefined : code },
    };
  }

  async verifyOtp(phone: string, code: string): Promise<Result<OtpVerifyResult>> {
    await this.simulateLatency();
    await this.ensureDemoAccount();

    const normalized = normalizePhone(phone);
    if (!normalized) return failure('invalid_phone', AUTH_ERROR_MESSAGES.invalidPhone, 'phone');

    const entry = this.otpStore.get(normalized);
    const trimmed = code.trim();
    const demoCode =
      isDemoMode() &&
      (await verifyPassword(trimmed, DEMO_OTP_VERIFIER.salt, DEMO_OTP_VERIFIER.hash));

    if (!entry) {
      // Demo recovery: a page refresh wipes the in-memory OTP store, so the
      // fixed demo code still works for an existing account.
      if (demoCode) {
        const account = this.findAccount(normalized);
        if (account) return this.completeOtpVerification(account);
      }
      return failure('invalid_otp', AUTH_ERROR_MESSAGES.invalidOtp, 'otp');
    }

    if (entry.expiresAt <= this.clock()) {
      this.otpStore.delete(normalized);
      return failure('otp_expired', AUTH_ERROR_MESSAGES.otpExpired, 'otp');
    }
    if (entry.attempts >= MAX_OTP_ATTEMPTS) {
      this.otpStore.delete(normalized);
      return failure('invalid_otp', AUTH_ERROR_MESSAGES.invalidOtp, 'otp');
    }
    // The issued demo code is random and never returned to the UI, so accept
    // the fixed demo code whenever it matches its verifier.
    if (demoCode) {
      this.otpStore.delete(normalized);
      const account = this.findAccount(normalized);
      if (!account) return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'phone');
      return this.completeOtpVerification(account);
    }
    if (!safeEqual(entry.code, trimmed)) {
      entry.attempts += 1;
      if (entry.attempts >= MAX_OTP_ATTEMPTS) this.otpStore.delete(normalized);
      return failure('invalid_otp', AUTH_ERROR_MESSAGES.invalidOtp, 'otp');
    }
    this.otpStore.delete(normalized);

    const account = this.findAccount(normalized);
    if (!account) return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'phone');
    return this.completeOtpVerification(account);
  }

  async login(phone: string, password: string): Promise<Result<AuthResult>> {
    await this.simulateLatency();
    await this.ensureDemoAccount();

    const normalized = normalizePhone(phone);
    if (!normalized) return failure('invalid_phone', AUTH_ERROR_MESSAGES.invalidPhone, 'phone');

    const db = loadDb();
    const account = db.accounts.find((candidate) => candidate.phone === normalized);
    if (!account) return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'phone');

    const matches = await verifyPassword(password, account.passwordSalt, account.passwordHash);
    if (!matches) {
      return failure('invalid_credentials', AUTH_ERROR_MESSAGES.invalidCredentials, 'password');
    }

    const stored = db.users.find((candidate) => candidate.id === account.userId);
    if (!stored) return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'phone');

    const user: User = { ...stored, profileComplete: account.profileComplete };
    return { ok: true, data: { user, session: this.createSession(user.id) } };
  }

  async register(input: RegisterInput): Promise<Result<{ phone: string }>> {
    await this.simulateLatency();
    await this.ensureDemoAccount();

    const fullName = input.fullName.trim();
    if (fullName.length < 2) return failure('unknown', AUTH_ERROR_MESSAGES.invalidName, 'fullName');

    const normalized = normalizePhone(input.phone);
    if (!normalized) return failure('invalid_phone', AUTH_ERROR_MESSAGES.invalidPhone, 'phone');

    if (input.password.length < 8 || input.password.trim().length === 0) {
      return failure('unknown', AUTH_ERROR_MESSAGES.weakPassword, 'password');
    }

    const email = input.email?.trim() ? input.email.trim() : undefined;
    if (email !== undefined && !emailSchema.safeParse(email).success) {
      return failure('unknown', AUTH_ERROR_MESSAGES.invalidEmail, 'email');
    }

    const db = loadDb();
    if (db.accounts.some((candidate) => candidate.phone === normalized)) {
      return failure('account_exists', AUTH_ERROR_MESSAGES.accountExists, 'phone');
    }

    const credentials = await hashPassword(input.password);
    if (!credentials) return failure('unknown', AUTH_ERROR_MESSAGES.hashingUnavailable, 'password');

    const createdAt = new Date(this.clock()).toISOString();
    const userId = newId('user');
    db.users.push({
      id: userId,
      fullName,
      phone: normalized,
      email,
      profileComplete: false,
      createdAt,
    });
    db.accounts.push({
      userId,
      phone: normalized,
      passwordSalt: credentials.salt,
      passwordHash: credentials.hash,
      profileComplete: false,
      createdAt,
    });
    saveDb(db);

    return { ok: true, data: { phone: normalized } };
  }

  async updateProfile(userId: string, patch: ProfilePatch): Promise<Result<User>> {
    await this.simulateLatency();
    await this.ensureDemoAccount();

    const db = loadDb();
    const index = db.users.findIndex((candidate) => candidate.id === userId);
    if (index === -1) return failure('not_found', AUTH_ERROR_MESSAGES.accountNotFound, 'userId');

    const current = db.users[index];
    const fullName = patch.fullName === undefined ? current.fullName : patch.fullName.trim();
    if (patch.fullName !== undefined && fullName.length === 0) {
      return failure('unknown', AUTH_ERROR_MESSAGES.invalidName, 'fullName');
    }

    let email = current.email;
    if (patch.email !== undefined) {
      const trimmed = patch.email.trim();
      if (trimmed && !emailSchema.safeParse(trimmed).success) {
        return failure('unknown', AUTH_ERROR_MESSAGES.invalidEmail, 'email');
      }
      email = trimmed === '' ? undefined : trimmed;
    }

    const avatarUrl = patch.avatarUrl === undefined ? current.avatarUrl : patch.avatarUrl;
    const profileComplete = fullName.trim().length > 0;
    const updated: User = { ...current, fullName, email, avatarUrl, profileComplete };

    db.users[index] = updated;
    const account = db.accounts.find((candidate) => candidate.userId === userId);
    if (account) account.profileComplete = profileComplete;
    saveDb(db);

    return { ok: true, data: updated };
  }

  async logout(): Promise<Result<null>> {
    // The mock has no server side session; the store clears the persisted one.
    await this.simulateLatency();
    return { ok: true, data: null };
  }
}

/** Create a repository, e.g. with a deterministic clock for tests. */
export function createMockAuthRepository(options?: MockAuthOptions): MockAuthRepository {
  return new MockAuthRepository(options);
}

/** The shared repository instance used by the app. */
export const mockAuthRepository = new MockAuthRepository();
