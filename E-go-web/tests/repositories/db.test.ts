import { afterEach, describe, expect, it, vi } from "vitest";

const DB_KEY = "ego:db:v1";
const LEGACY_PREFIX = "ego:legacy:ego:db:v1:";

/**
 * Import the database module freshly.
 *
 * The module keeps its database in memory, so every test needs its own
 * instance (and therefore its own module registry).
 */
async function loadFreshDb() {
  vi.resetModules();
  return await import("@/lib/mock/db");
}

afterEach(() => {
  window.localStorage.clear();
  vi.restoreAllMocks();
});

describe("mock database", () => {
  it("archives a corrupt payload and starts empty", async () => {
    window.localStorage.setItem(DB_KEY, "{bad json");
    const db = await loadFreshDb();

    const loaded = db.loadDb();
    expect(loaded.users).toHaveLength(0);
    expect(loaded.rides).toHaveLength(0);
    expect(loaded.savedPlaces).toHaveLength(0);

    const archived = Object.keys(window.localStorage).filter((key) => key.startsWith(LEGACY_PREFIX));
    expect(archived.length).toBeGreaterThan(0);
    expect(window.localStorage.getItem(archived[0])).toBe("{bad json");
  });

  it("archives a payload of a foreign schema version", async () => {
    window.localStorage.setItem(DB_KEY, JSON.stringify({ schemaVersion: 999, data: {} }));
    const db = await loadFreshDb();

    const loaded = db.loadDb();
    expect(loaded.users).toHaveLength(0);
    expect(loaded.rides).toHaveLength(0);

    const archived = Object.keys(window.localStorage).filter((key) => key.startsWith(LEGACY_PREFIX));
    expect(archived.length).toBeGreaterThan(0);
  });

  it("keeps the data in memory and reports a storage failure", async () => {
    const db = await loadFreshDb();

    const setItem = vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new DOMException("quota", "QuotaExceededError");
    });

    const events: CustomEvent[] = [];
    const listener = (event: Event) => {
      events.push(event as CustomEvent);
    };
    window.addEventListener("ego:storage-error", listener);

    const user = {
      id: "user-1",
      fullName: "Asha Verma",
      phone: "+919876543210",
      profileComplete: true,
      createdAt: new Date().toISOString(),
    };

    db.updateDb((database) => {
      database.users.push(user);
    });

    expect(events).toHaveLength(1);
    expect(events[0].detail?.message).toContain("Demo data could not be saved");
    expect(db.isPersistenceDisabled()).toBe(true);
    expect(db.loadDb().users.map((candidate) => candidate.id)).toContain("user-1");

    window.removeEventListener("ego:storage-error", listener);
    setItem.mockRestore();
  });
});
