import { describe, expect, it } from "vitest";

import {
  authSessionSchema,
  bookingDraftSchema,
  emailSchema,
  fareBreakdownSchema,
  loginPasswordSchema,
  notificationSchema,
  optionalEmailSchema,
  otpSchema,
  persistedEnvelope,
  persistedAuthSchema,
  phoneSchema,
  ratingSchema,
  registrationPasswordSchema,
  rideSchema,
  userSchema,
} from "@/lib/domain/schemas";
import { readJson } from "@/lib/utils/storage";

const place = {
  id: "place-1",
  label: "Jhargram Bus Stand",
  address: "Jhargram, West Bengal",
  kind: "pickup" as const,
  lat: 22.4529,
  lng: 86.9003,
};

const destination = {
  ...place,
  id: "place-2",
  label: "Kharagpur Station",
  address: "Kharagpur, West Bengal",
  kind: "destination" as const,
};

const fare = {
  vehicle: "bike" as const,
  baseFare: 20,
  distanceFare: 30,
  platformFee: 3,
  total: 53,
  distanceKm: 3,
  estimatedMinutes: 12,
  estimatedArrivalMinutes: 3,
  currency: "INR" as const,
};

const completedRide = {
  id: "EGO-1757928000000",
  userId: "user-1",
  pickup: place,
  destination,
  vehicle: "bike" as const,
  fare,
  status: "tripCompleted" as const,
  paymentMethodId: "payment-1",
  createdAt: "2026-11-15T10:00:00.000Z",
  phaseStartedAt: "2026-11-15T10:25:00.000Z",
  completedAt: "2026-11-15T10:25:00.000Z",
  timeline: [{ status: "tripCompleted" as const, at: "2026-11-15T10:25:00.000Z" }],
};

describe("phoneSchema", () => {
  it("normalizes to E.164", () => {
    expect(phoneSchema.parse("+91 90000-00001")).toBe("+919000000001");
    expect(phoneSchema.parse("09000000001")).toBe("+919000000001");
  });

  it("rejects an invalid number", () => {
    expect(phoneSchema.safeParse("12345").success).toBe(false);
  });
});

describe("otpSchema", () => {
  it("accepts exactly six digits", () => {
    expect(otpSchema.safeParse("123456").success).toBe(true);
  });

  it("rejects everything else", () => {
    for (const value of ["", "12345", "1234567", "abcdef", "12 345", "12345a"]) {
      expect(otpSchema.safeParse(value).success, value).toBe(false);
    }
  });
});

describe("password schemas", () => {
  it("requires at least 8 characters for registration", () => {
    expect(registrationPasswordSchema.safeParse("EgoDemo@123").success).toBe(true);
    expect(registrationPasswordSchema.safeParse("abcdefgh").success).toBe(true);
    expect(registrationPasswordSchema.safeParse("short").success).toBe(false);
  });

  it("rejects a whitespace only registration password", () => {
    expect(registrationPasswordSchema.safeParse("        ").success).toBe(false);
  });

  it("accepts any non-empty login password", () => {
    expect(loginPasswordSchema.safeParse("x").success).toBe(true);
    expect(loginPasswordSchema.safeParse("").success).toBe(false);
  });
});

describe("email schemas", () => {
  it("accepts a valid address", () => {
    expect(emailSchema.safeParse("demo@ego.local").success).toBe(true);
  });

  it("rejects an invalid address", () => {
    for (const value of ["demo", "demo@", "@ego.local", "demo@ego", "demo @ego.local"]) {
      expect(emailSchema.safeParse(value).success, value).toBe(false);
    }
  });

  it("treats an empty optional email as unset", () => {
    expect(optionalEmailSchema.parse("")).toBeUndefined();
    expect(optionalEmailSchema.parse(undefined)).toBeUndefined();
    expect(optionalEmailSchema.parse("demo@ego.local")).toBe("demo@ego.local");
  });
});

describe("user and session schemas", () => {
  const user = {
    id: "user-1",
    fullName: "E-GO Demo User",
    phone: "+919000000001",
    email: "demo@ego.local",
    profileComplete: true,
    createdAt: "2026-11-15T10:00:00.000Z",
  };

  it("accepts a valid user", () => {
    expect(userSchema.safeParse(user).success).toBe(true);
  });

  it("rejects a user with an invalid phone number", () => {
    expect(userSchema.safeParse({ ...user, phone: "12345" }).success).toBe(false);
  });

  it("requires the session to expire after it was issued", () => {
    const session = {
      userId: "user-1",
      token: "token",
      issuedAt: "2026-11-15T10:00:00.000Z",
      expiresAt: "2026-11-22T10:00:00.000Z",
    };
    expect(authSessionSchema.safeParse(session).success).toBe(true);
    expect(
      authSessionSchema.safeParse({ ...session, expiresAt: "2026-11-15T09:00:00.000Z" }).success,
    ).toBe(false);
    expect(
      authSessionSchema.safeParse({ ...session, expiresAt: session.issuedAt }).success,
    ).toBe(false);
  });
});

describe("fareBreakdownSchema", () => {
  it("accepts a consistent breakdown", () => {
    expect(fareBreakdownSchema.safeParse(fare).success).toBe(true);
  });

  it("rejects a total that does not match the parts", () => {
    expect(fareBreakdownSchema.safeParse({ ...fare, total: 60 }).success).toBe(false);
  });

  it("rejects negative or fractional amounts", () => {
    expect(fareBreakdownSchema.safeParse({ ...fare, baseFare: -1, total: 32 }).success).toBe(false);
    expect(fareBreakdownSchema.safeParse({ ...fare, distanceFare: 30.5, total: 53.5 }).success).toBe(
      false,
    );
  });

  it("rejects a distance below the minimum", () => {
    expect(fareBreakdownSchema.safeParse({ ...fare, distanceKm: 0.4 }).success).toBe(false);
  });
});

describe("ratingSchema", () => {
  const rating = {
    rideId: "EGO-1",
    stars: 4 as const,
    comment: "Smooth ride",
    tags: ["clean"],
    createdAt: "2026-11-15T10:30:00.000Z",
  };

  it("accepts a valid rating", () => {
    expect(ratingSchema.safeParse(rating).success).toBe(true);
  });

  it("rejects stars outside 1-5", () => {
    expect(ratingSchema.safeParse({ ...rating, stars: 0 }).success).toBe(false);
    expect(ratingSchema.safeParse({ ...rating, stars: 6 }).success).toBe(false);
  });

  it("rejects a comment longer than 300 characters", () => {
    expect(ratingSchema.safeParse({ ...rating, comment: "x".repeat(301) }).success).toBe(false);
  });

  it("rejects more than five tags", () => {
    expect(ratingSchema.safeParse({ ...rating, tags: ["a", "b", "c", "d", "e", "f"] }).success).toBe(
      false,
    );
  });
});

describe("notificationSchema", () => {
  it("accepts a valid notification", () => {
    expect(
      notificationSchema.safeParse({
        id: "notification-1",
        kind: "ride",
        title: "Driver assigned",
        body: "Rajan is on the way",
        createdAt: "2026-11-15T10:00:00.000Z",
        read: false,
      }).success,
    ).toBe(true);
  });
});

describe("rideSchema", () => {
  it("accepts a completed ride", () => {
    expect(rideSchema.safeParse(completedRide).success).toBe(true);
  });

  it("requires a completion timestamp for a completed ride", () => {
    const withoutCompletion = { ...completedRide, completedAt: undefined };
    expect(rideSchema.safeParse(withoutCompletion).success).toBe(false);
  });

  it("requires a completion timestamp for an awaiting rating ride", () => {
    const withoutCompletion = { ...completedRide, completedAt: undefined };
    expect(
      rideSchema.safeParse({ ...withoutCompletion, status: "awaitingRating" }).success,
    ).toBe(false);
  });

  it("rejects a rating on a ride that is not rated", () => {
    expect(
      rideSchema.safeParse({
        ...completedRide,
        rating: {
          rideId: completedRide.id,
          stars: 5,
          tags: [],
          createdAt: "2026-11-15T10:30:00.000Z",
        },
      }).success,
    ).toBe(false);
  });

  it("accepts a rating on a rated ride", () => {
    expect(
      rideSchema.safeParse({
        ...completedRide,
        status: "rated",
        rating: {
          rideId: completedRide.id,
          stars: 5,
          tags: [],
          createdAt: "2026-11-15T10:30:00.000Z",
        },
      }).success,
    ).toBe(true);
  });

  it("rejects a cancellation timestamp on a ride that is not cancelled", () => {
    expect(
      rideSchema.safeParse({ ...completedRide, cancelledAt: "2026-11-15T10:10:00.000Z" }).success,
    ).toBe(false);
  });

  it("rejects an empty timeline", () => {
    expect(rideSchema.safeParse({ ...completedRide, timeline: [] }).success).toBe(false);
  });

  it("rejects an unknown status", () => {
    expect(rideSchema.safeParse({ ...completedRide, status: "teleporting" }).success).toBe(false);
  });
});

describe("bookingDraftSchema", () => {
  it("accepts an empty draft", () => {
    expect(bookingDraftSchema.safeParse({}).success).toBe(true);
  });

  it("accepts a draft with a pickup and a vehicle", () => {
    expect(bookingDraftSchema.safeParse({ pickup: place, vehicle: "toto" }).success).toBe(true);
  });
});

describe("persisted payloads", () => {
  it("rejects an unknown schema version", () => {
    const envelope = persistedEnvelope(bookingDraftSchema);
    expect(envelope.safeParse({ schemaVersion: 2, data: {} }).success).toBe(false);
    expect(envelope.safeParse({ schemaVersion: 1, data: {} }).success).toBe(true);
  });

  it("rejects a corrupt payload instead of throwing", () => {
    window.localStorage.setItem("ego:corrupt:v1", "{not json");
    const parsed = readJson("ego:corrupt:v1", (value) => value as unknown);
    expect(parsed).toBeNull();
  });

  it("discards a persisted auth payload of a foreign version", () => {
    expect(
      persistedAuthSchema.safeParse({
        schemaVersion: 2,
        data: { session: {}, user: {}, onboardingSeen: true },
      }).success,
    ).toBe(false);
  });
});
