import { describe, expect, it } from "vitest";

import { shouldSimulatedSearchFail } from "@/lib/mock/simulation";

describe("simulated search failure", () => {
  it("never fails with a rate of zero", () => {
    for (const rideId of ["ride-1", "ride-2", "ride-3", "ride-4"]) {
      expect(shouldSimulatedSearchFail(rideId, 0)).toBe(false);
    }
  });

  it("always fails with a rate of one", () => {
    for (const rideId of ["ride-1", "ride-2", "ride-3", "ride-4"]) {
      expect(shouldSimulatedSearchFail(rideId, 1)).toBe(true);
    }
  });

  it("is deterministic for the same ride id and seed", () => {
    const expected = shouldSimulatedSearchFail("ride-7", 0.5, "seed-a");
    expect(typeof expected).toBe("boolean");
    expect(shouldSimulatedSearchFail("ride-7", 0.5, "seed-a")).toBe(expected);
    expect(shouldSimulatedSearchFail("ride-7", 0.5, "seed-a")).toBe(expected);
  });

  it("clamps the rate into 0 - 1", () => {
    expect(shouldSimulatedSearchFail("ride-7", -1)).toBe(false);
    expect(shouldSimulatedSearchFail("ride-7", 5)).toBe(true);
  });
});
