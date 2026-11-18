import { describe, expect, it } from 'vitest';

import {
  createRepositories,
  getRepositories,
  setRepositoriesForTests,
  type Repositories,
} from "@/lib/repositories/index";

describe("repository factory", () => {
  it("returns the same repositories on every call", () => {
    const first = getRepositories();
    const second = getRepositories();

    expect(second).toBe(first);
    expect(first.auth).toBeDefined();
    expect(first.rides).toBeDefined();
    expect(first.places).toBeDefined();
    expect(first.payments).toBeDefined();
    expect(first.notifications).toBeDefined();
  });

  it("creates independent instances", () => {
    const first = createRepositories({ latencyMs: 0 });
    const second = createRepositories({ latencyMs: 0 });

    expect(first).not.toBe(second);
    expect(first.auth).not.toBe(second.auth);
    expect(first.rides).not.toBe(second.rides);
    expect(first.places).not.toBe(second.places);
    expect(first.payments).not.toBe(second.payments);
    expect(first.notifications).not.toBe(second.notifications);
  });

  it("can be replaced for tests and restored afterwards", () => {
    const original = getRepositories();
    const custom = createRepositories({ latencyMs: 0 });

    setRepositoriesForTests(custom);
    expect(getRepositories()).toBe(custom);

    setRepositoriesForTests(null);
    const restored = getRepositories();
    expect(restored).not.toBe(custom);
    expect(restored.auth).toBeDefined();
    expect(restored.rides).toBeDefined();
    expect(restored.places).toBeDefined();
    expect(restored.payments).toBeDefined();
    expect(restored.notifications).toBeDefined();
    expect(restored).not.toBe(original);
  });

  it("builds a complete set of adapters", () => {
    const repositories: Repositories = createRepositories({ latencyMs: 0 });

    expect(Object.keys(repositories).sort()).toEqual([
      "auth",
      "notifications",
      "payments",
      "places",
      "rides",
    ]);
  });
});
