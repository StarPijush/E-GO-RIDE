import { afterEach, describe, expect, it, vi } from "vitest";

import { STORAGE_KEYS } from "@/lib/config/constants";

/**
 * Load the mock auth repository with a controlled demo flag.
 *
 * `env.ts` reads `process.env` when it is first evaluated, so the module
 * registry is reset and the flag is stubbed before the import.
 */
async function loadAuthMock(demoMode: boolean) {
  vi.resetModules();
  vi.stubEnv("NEXT_PUBLIC_ENABLE_DEMO_AUTH", demoMode ? "true" : "false");
  return await import("@/lib/mock/auth-mock");
}

afterEach(() => {
  vi.unstubAllEnvs();
  vi.resetModules();
});

const DEMO_PHONE = "9000000001";
const DEMO_PASSWORD = "EgoDemo@123";

describe("demo account", () => {
  it("seeds the demo account while demo mode is on", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.login(DEMO_PHONE, DEMO_PASSWORD);

    expect(result.ok).toBe(true);
    if (result.ok) {
      expect(result.data.user.fullName).toBe("E-GO Demo User");
      expect(result.data.user.email).toBe("demo@ego.local");
      expect(result.data.user.phone).toBe("+919000000001");
      expect(result.data.user.profileComplete).toBe(true);
      expect(result.data.session.token.length).toBeGreaterThan(0);
    }
  });

  it("does not seed the demo account while demo mode is off", async () => {
    const { createMockAuthRepository } = await loadAuthMock(false);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.login(DEMO_PHONE, DEMO_PASSWORD);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("not_found");
      expect(result.error.message).toBe("No account found. Please create an account first.");
    }
  });
});

describe("login", () => {
  it("fails with the exact copy for an unknown account", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.login("9876543210", DEMO_PASSWORD);

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("not_found");
      expect(result.error.message).toBe("No account found. Please create an account first.");
    }
  });

  it("fails with the exact copy for a wrong password", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.login(DEMO_PHONE, "wrong-password");

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("invalid_credentials");
      expect(result.error.message).toBe("Incorrect phone number or password. Please try again.");
    }
  });

  it("rejects an invalid phone number", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.login("12345", DEMO_PASSWORD);

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe("invalid_phone");
  });
});

describe("registration and OTP", () => {
  it("registers, rejects a duplicate and verifies the OTP", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const registered = await repository.register({
      fullName: "Asha Verma",
      phone: "9876543210",
      email: "asha@example.com",
      password: "Passw0rd!",
    });
    expect(registered.ok).toBe(true);
    if (registered.ok) expect(registered.data.phone).toBe("+919876543210");

    const duplicate = await repository.register({
      fullName: "Asha Verma",
      phone: "9876543210",
      password: "Passw0rd!",
    });
    expect(duplicate.ok).toBe(false);
    if (!duplicate.ok) {
      expect(duplicate.error.code).toBe("account_exists");
      expect(duplicate.error.message).toBe(
        "An account with this phone number already exists. Please log in.",
      );
    }

    const requested = await repository.requestOtp("9876543210");
    expect(requested.ok).toBe(true);
    if (requested.ok) {
      expect(requested.data.cooldownSeconds).toBe(30);
      expect(requested.data.devOtp).toBeUndefined();
    }

    const verified = await repository.verifyOtp("9876543210", "123456");
    expect(verified.ok).toBe(true);
    if (verified.ok) {
      expect(verified.data.isNewUser).toBe(true);
      expect(verified.data.user.profileComplete).toBe(false);
      expect(verified.data.user.fullName).toBe("Asha Verma");
      expect(Date.parse(verified.data.session.expiresAt)).toBeGreaterThan(
        Date.parse(verified.data.session.issuedAt),
      );
    }
  });

  it("rejects an invalid registration input", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const shortName = await repository.register({
      fullName: "A",
      phone: "9876543211",
      password: "Passw0rd!",
    });
    expect(shortName.ok).toBe(false);

    const weakPassword = await repository.register({
      fullName: "Asha Verma",
      phone: "9876543211",
      password: "short",
    });
    expect(weakPassword.ok).toBe(false);

    const badEmail = await repository.register({
      fullName: "Asha Verma",
      phone: "9876543211",
      email: "not-an-email",
      password: "Passw0rd!",
    });
    expect(badEmail.ok).toBe(false);
  });

  it("fails with the exact copy for a wrong OTP", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Asha Verma",
      phone: "9876543212",
      password: "Passw0rd!",
    });
    await repository.requestOtp("9876543212");

    const result = await repository.verifyOtp("9876543212", "000000");

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("invalid_otp");
      expect(result.error.message).toBe("Invalid OTP. Please try again.");
    }
  });

  it("fails when no OTP was requested", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.verifyOtp("9876543213", "123456");

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe("invalid_otp");
  });

  it("refuses to send an OTP to an unknown phone number", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.requestOtp("9876543220");

    expect(result.ok).toBe(false);
    if (!result.ok) {
      expect(result.error.code).toBe("not_found");
      expect(result.error.message).toBe("No account found. Please create an account first.");
      expect(result.error.field).toBe("phone");
    }
  });

  it("rate limits the OTP requests with a cooldown", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Test User",
      phone: "9876543214",
      password: "Password@123",
    });

    const first = await repository.requestOtp("9876543214");
    expect(first.ok).toBe(true);

    const second = await repository.requestOtp("9876543214");
    expect(second.ok).toBe(false);
    if (!second.ok) expect(second.error.code).toBe("otp_cooldown");
  });

  it("generates a random OTP while demo mode is off", async () => {
    const { createMockAuthRepository } = await loadAuthMock(false);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Test User",
      phone: "9876543215",
      password: "Password@123",
    });

    const requested = await repository.requestOtp("9876543215");

    expect(requested.ok).toBe(true);
    if (requested.ok) {
      expect(requested.data.devOtp).toMatch(/^\d{6}$/);
      expect(requested.data.devOtp).not.toBe("123456");
    }
  });
});

describe("OTP edge cases", () => {
  it("expires the OTP after ten minutes", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    let now = Date.parse("2026-11-15T10:00:00.000Z");
    const repository = createMockAuthRepository({ latencyMs: 0, now: () => now });

    await repository.register({
      fullName: "Asha Verma",
      phone: "9876543218",
      password: "Password@123",
    });
    const requested = await repository.requestOtp("9876543218");
    expect(requested.ok).toBe(true);

    now += 11 * 60 * 1000;

    const verified = await repository.verifyOtp("9876543218", "123456");
    expect(verified.ok).toBe(false);
    if (!verified.ok) {
      expect(verified.error.code).toBe("otp_expired");
      expect(verified.error.message).toBe("OTP expired. Please request a new code.");
    }
  });

  it("accepts the demo OTP with a new repository instance (page reload)", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const first = createMockAuthRepository({ latencyMs: 0 });
    const seeded = await first.login(DEMO_PHONE, DEMO_PASSWORD);
    expect(seeded.ok).toBe(true);

    // A new instance has no in-memory OTP entry - the demo code still works.
    const afterReload = createMockAuthRepository({ latencyMs: 0 });
    const verified = await afterReload.verifyOtp(DEMO_PHONE, "123456");

    expect(verified.ok).toBe(true);
    if (verified.ok) {
      expect(verified.data.user.fullName).toBe("E-GO Demo User");
      expect(verified.data.user.phone).toBe("+919000000001");
      expect(verified.data.isNewUser).toBe(false);
      expect(verified.data.session.token.length).toBeGreaterThan(0);
    }
  });

  it("burns the OTP after five wrong attempts", async () => {
    const { createMockAuthRepository } = await loadAuthMock(false);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Asha Verma",
      phone: "9876543219",
      password: "Password@123",
    });
    const requested = await repository.requestOtp("9876543219");
    expect(requested.ok).toBe(true);
    if (!requested.ok) return;
    const code = requested.data.devOtp ?? "";
    expect(code).toMatch(/^\d{6}$/);

    for (let attempt = 0; attempt < 5; attempt += 1) {
      const result = await repository.verifyOtp("9876543219", "000000");
      expect(result.ok).toBe(false);
      if (!result.ok) expect(result.error.code).toBe("invalid_otp");
    }

    const afterBurn = await repository.verifyOtp("9876543219", code);
    expect(afterBurn.ok).toBe(false);
    if (!afterBurn.ok) expect(afterBurn.error.code).toBe("invalid_otp");
  });
});

describe("stored credentials", () => {
  it("never stores the password in plain text", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Asha Verma",
      phone: "9876543216",
      password: "Passw0rd!",
    });
    await repository.login(DEMO_PHONE, DEMO_PASSWORD);

    const raw = window.localStorage.getItem(STORAGE_KEYS.db) ?? "";
    expect(raw).not.toContain("Passw0rd!");
    expect(raw).not.toContain(DEMO_PASSWORD);

    const stored = JSON.parse(raw) as {
      data: { accounts: { passwordHash: string; passwordSalt: string }[] };
    };
    expect(stored.data.accounts).toHaveLength(2);
    for (const account of stored.data.accounts) {
      expect(account.passwordHash).not.toContain("Passw0rd!");
      expect(account.passwordHash.length).toBeGreaterThan(0);
      expect(account.passwordSalt.length).toBeGreaterThan(0);
    }
  });

  it("stores no plain text password when registering", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Asha Verma",
      phone: "9876543221",
      password: "Password@123",
    });

    const raw = window.localStorage.getItem(STORAGE_KEYS.db) ?? "";
    expect(raw).not.toContain("Password@123");
    expect(raw).toContain("passwordHash");
    expect(raw).toContain("passwordSalt");
  });
});

describe("profile", () => {
  it("updates the profile and completes it", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    await repository.register({
      fullName: "Asha Verma",
      phone: "9876543217",
      password: "Passw0rd!",
    });
    await repository.requestOtp("9876543217");
    const verified = await repository.verifyOtp("9876543217", "123456");
    expect(verified.ok).toBe(true);
    if (!verified.ok) return;

    const updated = await repository.updateProfile(verified.data.user.id, {
      fullName: "Asha V",
      email: "asha@example.com",
    });

    expect(updated.ok).toBe(true);
    if (updated.ok) {
      expect(updated.data.fullName).toBe("Asha V");
      expect(updated.data.email).toBe("asha@example.com");
      expect(updated.data.profileComplete).toBe(true);
    }
  });

  it("fails for an unknown user", async () => {
    const { createMockAuthRepository } = await loadAuthMock(true);
    const repository = createMockAuthRepository({ latencyMs: 0 });

    const result = await repository.updateProfile("does-not-exist", { fullName: "Nobody" });

    expect(result.ok).toBe(false);
    if (!result.ok) expect(result.error.code).toBe("not_found");
  });
});
