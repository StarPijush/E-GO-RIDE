/**
 * HTTP stub of the auth repository.
 *
 * The stub exists so the swap to a real API is additive: implement this class
 * and change `createRepositories()` - no screen changes (architecture §6).
 */

import type {
  AuthRepository,
  AuthResult,
  OtpRequestResult,
  OtpVerifyResult,
  ProfilePatch,
  RegisterInput,
} from '@/lib/repositories/types';
import type { Result, User } from '@/lib/domain/types';

/** The error every stub method returns until the adapter is implemented. */
export const NOT_IMPLEMENTED_ERROR = {
  code: 'unknown',
  message:
    'HTTP adapter is not implemented. Set NEXT_PUBLIC_API_BASE_URL and implement this adapter.',
} as const;

export class HttpAuthRepository implements AuthRepository {
  protected readonly baseUrl: string;

  protected readonly fetchImpl: typeof fetch;

  constructor(baseUrl: string, fetchImpl: typeof fetch = fetch) {
    this.baseUrl = baseUrl;
    this.fetchImpl = fetchImpl;
  }

  async requestOtp(phone: string): Promise<Result<OtpRequestResult>> {
    void phone;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async verifyOtp(phone: string, code: string): Promise<Result<OtpVerifyResult>> {
    void phone;
    void code;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async login(phone: string, password: string): Promise<Result<AuthResult>> {
    void phone;
    void password;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async register(input: RegisterInput): Promise<Result<{ phone: string }>> {
    void input;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async updateProfile(userId: string, patch: ProfilePatch): Promise<Result<User>> {
    void userId;
    void patch;
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }

  async logout(): Promise<Result<null>> {
    return { ok: false, error: { ...NOT_IMPLEMENTED_ERROR } };
  }
}
