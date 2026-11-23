import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';

const AUTH_KEY = 'ego:auth:v1';
const DEMO_PHONE = '9000000001';
const DEMO_PASSWORD = 'EgoDemo@123';

/**
 * Load the store and the repositories freshly.
 *
 * The env flag is stubbed before the import, so the demo mode of the mock
 * repository matches the test.
 */
async function loadStore(demoMode: boolean) {
  vi.resetModules();
  vi.stubEnv('NEXT_PUBLIC_ENABLE_DEMO_AUTH', demoMode ? 'true' : 'false');

  const repositories = await import('@/lib/repositories');
  const authModule = await import('@/stores/auth-store');
  const selectors = await import('@/stores/selectors');

  repositories.setRepositoriesForTests(repositories.createRepositories({ latencyMs: 0 }));

  return { store: authModule.useAuthStore, selectors };
}

beforeEach(() => {
  window.localStorage.clear();
});

afterEach(() => {
  vi.unstubAllEnvs();
  vi.resetModules();
});

describe('login', () => {
  it('signs the demo user in and persists only the three fields', async () => {
    const { store } = await loadStore(true);

    const result = await store.getState().login(DEMO_PHONE, DEMO_PASSWORD);
    expect(result.ok).toBe(true);

    const state = store.getState();
    expect(state.user?.fullName).toBe('E-GO Demo User');
    expect(state.user?.phone).toBe('+919000000001');
    expect(state.session).not.toBeNull();
    expect(state.onboardingSeen).toBe(true);
    expect(state.pending).toBeNull();
    expect(state.lastError).toBeNull();

    const raw = window.localStorage.getItem(AUTH_KEY);
    expect(raw).not.toBeNull();
    const stored = JSON.parse(raw ?? '{}') as {
      schemaVersion: number;
      data: Record<string, unknown>;
    };
    expect(stored.schemaVersion).toBe(1);
    expect(Object.keys(stored.data).sort()).toEqual(['onboardingSeen', 'session', 'user']);
  });

  it('keeps the error and stays signed out on a failure', async () => {
    const { store } = await loadStore(true);

    const result = await store.getState().login('9876543210', 'wrong-password');
    expect(result.ok).toBe(false);

    const state = store.getState();
    expect(state.session).toBeNull();
    expect(state.user).toBeNull();
    expect(state.lastError?.code).toBe('not_found');
    expect(state.pending).toBeNull();
  });
});

describe('otp', () => {
  it('starts the cooldown after a successful request', async () => {
    const { store } = await loadStore(true);

    const before = Date.now();
    const result = await store.getState().requestOtp(DEMO_PHONE);
    expect(result.ok).toBe(true);

    const cooldownUntil = store.getState().otpCooldownUntil;
    expect(cooldownUntil).not.toBeNull();
    expect(cooldownUntil ?? 0).toBeGreaterThan(before);
    expect(store.getState().lastError).toBeNull();
  });

  it('reports the error of a failed request', async () => {
    const { store } = await loadStore(true);

    const result = await store.getState().requestOtp('9876543210');
    expect(result.ok).toBe(false);
    expect(store.getState().lastError?.code).toBe('not_found');
    expect(store.getState().otpCooldownUntil).toBeNull();
    expect(store.getState().otpPreview).toBeNull();
  });

  it('keeps the generated mock code outside demo mode so the OTP screen can show it', async () => {
    const { store } = await loadStore(false);

    const registered = await store.getState().register({
      fullName: 'Web User',
      phone: '9876543222',
      password: 'Password@123',
    });
    expect(registered.ok).toBe(true);

    const requested = await store.getState().requestOtp('9876543222');
    expect(requested.ok).toBe(true);
    if (!requested.ok) return;

    expect(requested.data.devOtp).toMatch(/^\d{6}$/);
    expect(store.getState().otpPreview).toBe(requested.data.devOtp);

    const verified = await store.getState().verifyOtp('9876543222', requested.data.devOtp ?? '');
    expect(verified.ok).toBe(true);
  });

  it('verifies the demo code without a prior request', async () => {
    const { store } = await loadStore(true);

    const result = await store.getState().verifyOtp(DEMO_PHONE, '123456');
    expect(result.ok).toBe(true);

    const state = store.getState();
    expect(state.user?.fullName).toBe('E-GO Demo User');
    expect(state.session).not.toBeNull();
    expect(state.onboardingSeen).toBe(true);
  });
});

describe('profile, logout and expiry', () => {
  it('updates the profile of the signed-in user', async () => {
    const { store } = await loadStore(true);
    await store.getState().verifyOtp(DEMO_PHONE, '123456');

    const result = await store.getState().updateProfile({ fullName: 'Demo Renamed' });
    expect(result.ok).toBe(true);
    expect(store.getState().user?.fullName).toBe('Demo Renamed');
  });

  it('fails without a signed-in user', async () => {
    const { store } = await loadStore(true);

    const result = await store.getState().updateProfile({ fullName: 'Nobody' });
    expect(result.ok).toBe(false);
    expect(store.getState().user).toBeNull();
  });

  it('clears the session on logout but keeps the onboarding flag', async () => {
    const { store } = await loadStore(true);
    await store.getState().verifyOtp(DEMO_PHONE, '123456');

    const result = await store.getState().logout();
    expect(result.ok).toBe(true);

    const state = store.getState();
    expect(state.session).toBeNull();
    expect(state.user).toBeNull();
    expect(state.onboardingSeen).toBe(true);
    expect(state.hasValidSession()).toBe(false);
  });

  it('expires an old session', async () => {
    const { store } = await loadStore(true);

    store.setState({
      user: {
        id: 'demo-ego-001',
        fullName: 'E-GO Demo User',
        phone: '+919000000001',
        profileComplete: true,
        createdAt: '2026-01-01T00:00:00.000Z',
      },
      session: {
        userId: 'demo-ego-001',
        token: 'token',
        issuedAt: '2026-01-01T00:00:00.000Z',
        expiresAt: '2026-01-02T00:00:00.000Z',
      },
    });

    const expired = await store.getState().expireIfNeeded();
    expect(expired).toBe(true);
    expect(store.getState().session).toBeNull();
    expect(store.getState().user).toBeNull();
    expect(store.getState().hasValidSession()).toBe(false);
  });

  it('keeps a valid session', async () => {
    const { store } = await loadStore(true);

    const expiresAt = new Date(Date.now() + 60_000).toISOString();
    store.setState({
      session: {
        userId: 'demo-ego-001',
        token: 'token',
        issuedAt: new Date().toISOString(),
        expiresAt,
      },
    });

    const expired = await store.getState().expireIfNeeded();
    expect(expired).toBe(false);
    expect(store.getState().session).not.toBeNull();
    expect(store.getState().hasValidSession()).toBe(true);
  });
});

describe('selectors', () => {
  it('builds the initials of a name', async () => {
    const { selectors } = await loadStore(true);

    expect(selectors.selectInitials('Asha Verma')).toBe('AV');
    expect(selectors.selectInitials('E-GO Demo User')).toBe('EU');
    expect(selectors.selectInitials('Asha')).toBe('AS');
    expect(selectors.selectInitials('   ')).toBe('');
  });

  it('greets by the time of the day', async () => {
    const { selectors } = await loadStore(true);

    expect(selectors.selectGreeting('Asha Verma', new Date(2026, 0, 1, 9, 30))).toBe(
      'Good morning, Asha',
    );
    expect(selectors.selectGreeting('Asha Verma', new Date(2026, 0, 1, 14, 0))).toBe(
      'Good afternoon, Asha',
    );
    expect(selectors.selectGreeting('Asha Verma', new Date(2026, 0, 1, 20, 15))).toBe(
      'Good evening, Asha',
    );
    expect(selectors.selectGreeting('', new Date(2026, 0, 1, 9, 30))).toBe('Good morning');
  });

  it('reads the user and the session from the state', async () => {
    const { store, selectors } = await loadStore(true);

    expect(selectors.selectUser(store.getState())).toBeNull();
    expect(selectors.selectSession(store.getState())).toBeNull();
    expect(selectors.selectIsAuthenticated(store.getState())).toBe(false);
    expect(selectors.selectNeedsProfileSetup(store.getState())).toBe(false);

    await store.getState().verifyOtp(DEMO_PHONE, '123456');

    expect(selectors.selectUser(store.getState())?.fullName).toBe('E-GO Demo User');
    expect(selectors.selectSession(store.getState())).not.toBeNull();
    expect(selectors.selectIsAuthenticated(store.getState())).toBe(true);
  });
});
