import { describe, expect, it } from "vitest";

import { rideSchema } from "@/lib/domain/schemas";
import { createEmptyDb } from "@/lib/mock/db";
import {
  DEMO_NOTIFICATIONS,
  DEMO_PAYMENT_METHODS,
  DEMO_RIDES,
  DEMO_SAVED_PLACES,
  ensureDemoSeedData,
} from "@/lib/mock/seeds";

const DEMO_USER_ID = "demo-ego-001";

describe("demo rides", () => {
  it("ships three historical rides for the demo user", () => {
    expect(DEMO_RIDES).toHaveLength(3);
    expect(DEMO_RIDES.map((ride) => ride.status)).toEqual(["rated", "awaitingRating", "cancelled"]);

    for (const ride of DEMO_RIDES) {
      const parsed = rideSchema.safeParse(ride);
      expect(parsed.success, ride.id).toBe(true);
      expect(ride.userId).toBe(DEMO_USER_ID);
      expect(ride.nextTransitionAt).toBeUndefined();
      expect(ride.timeline.length).toBeGreaterThan(0);
      expect(ride.timeline.at(-1)?.status).toBe(ride.status);
    }
  });

  it("seeds no live ride", () => {
    const live = DEMO_RIDES.filter((ride) =>
      ["confirmingBooking", "searchingDriver", "driverAssigned", "driverArriving", "driverArrived", "tripInProgress"].includes(
        ride.status,
      ),
    );
    expect(live).toHaveLength(0);
  });
});

describe("ensureDemoSeedData", () => {
  it("adds the demo records exactly once", () => {
    const db = createEmptyDb();

    expect(ensureDemoSeedData(db)).toBe(true);
    expect(db.savedPlaces).toHaveLength(2);
    expect(db.paymentMethods).toHaveLength(1);
    expect(db.notifications).toHaveLength(4);
    expect(db.rides).toHaveLength(3);

    expect(ensureDemoSeedData(db)).toBe(false);
    expect(db.savedPlaces).toHaveLength(2);
    expect(db.paymentMethods).toHaveLength(1);
    expect(db.notifications).toHaveLength(4);
    expect(db.rides).toHaveLength(3);
  });

  it("scopes every seeded record to the demo user", () => {
    for (const place of DEMO_SAVED_PLACES) {
      expect(place.userId).toBe(DEMO_USER_ID);
    }
    for (const method of DEMO_PAYMENT_METHODS) {
      expect(method.userId).toBe(DEMO_USER_ID);
    }
    for (const notification of DEMO_NOTIFICATIONS) {
      expect(notification.userId).toBe(DEMO_USER_ID);
    }
  });
});
