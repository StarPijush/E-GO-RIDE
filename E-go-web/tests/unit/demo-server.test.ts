import { afterEach, describe, expect, it, vi } from "vitest";

async function loadDemoServer() {
  vi.resetModules();
  return import("@/lib/config/demo-server");
}

afterEach(() => {
  vi.unstubAllEnvs();
  vi.resetModules();
});

describe("demo server config", () => {
  it("reads the configured demo login and OTP", async () => {
    vi.stubEnv("NEXT_PUBLIC_ENABLE_DEMO_AUTH", "true");
    vi.stubEnv("DEMO_LOGIN_PHONE", "9000000001");
    vi.stubEnv("DEMO_LOGIN_PASSWORD", "EgoDemo@123");
    vi.stubEnv("DEMO_LOGIN_OTP", "123456");

    const { getDemoLogin, getDemoOtp } = await loadDemoServer();

    expect(getDemoLogin()).toEqual({
      phone: "9000000001",
      password: "EgoDemo@123",
    });
    expect(getDemoOtp()).toBe("123456");
  });

  it("returns null when demo auth is disabled", async () => {
    vi.stubEnv("NEXT_PUBLIC_ENABLE_DEMO_AUTH", "false");
    vi.stubEnv("DEMO_LOGIN_PHONE", "9000000001");
    vi.stubEnv("DEMO_LOGIN_PASSWORD", "EgoDemo@123");
    vi.stubEnv("DEMO_LOGIN_OTP", "123456");

    const { getDemoLogin, getDemoOtp } = await loadDemoServer();

    expect(getDemoLogin()).toBeNull();
    expect(getDemoOtp()).toBeNull();
  });
});
