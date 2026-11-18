import { describe, expect, it } from "vitest";

import { formatPhoneDisplay, isValidPhone, normalizePhone, normalizePhoneDigits } from "@/lib/utils/phone";

describe("normalizePhone", () => {
  it("normalizes a spaced and hyphenated number", () => {
    expect(normalizePhone("+91 90000-00001")).toBe("+919000000001");
  });

  it("normalizes a number with the country code", () => {
    expect(normalizePhone("919000000001")).toBe("+919000000001");
  });

  it("normalizes a number with the trunk prefix", () => {
    expect(normalizePhone("09000000001")).toBe("+919000000001");
  });

  it("normalizes a plain 10 digit number", () => {
    expect(normalizePhone("9000000001")).toBe("+919000000001");
  });

  it("ignores every other character", () => {
    expect(normalizePhone("+91 (900) 000-0001")).toBe("+919000000001");
  });

  it("rejects numbers that are not Indian mobile numbers", () => {
    const invalid = [
      "",
      "   ",
      "12345",
      "1234567890",
      "5000000000",
      "900000000",
      "90000000011",
      "+1 9000000001",
      "abcdefghij",
    ];

    for (const value of invalid) {
      expect(normalizePhone(value), value).toBeNull();
      expect(isValidPhone(value), value).toBe(false);
    }
  });
});

describe("normalizePhoneDigits", () => {
  it("returns the 10 digit national number", () => {
    expect(normalizePhoneDigits("+91 90000-00001")).toBe("9000000001");
    expect(normalizePhoneDigits("09000000001")).toBe("9000000001");
    expect(normalizePhoneDigits("919000000001")).toBe("9000000001");
  });

  it("returns null for an invalid number", () => {
    expect(normalizePhoneDigits("1234567890")).toBeNull();
  });
});

describe("formatPhoneDisplay", () => {
  it("groups the national number", () => {
    expect(formatPhoneDisplay("+919000000001")).toBe("+91 90000 00001");
    expect(formatPhoneDisplay("09000000001")).toBe("+91 90000 00001");
  });

  it("returns invalid input unchanged", () => {
    expect(formatPhoneDisplay(" 12345 ")).toBe("12345");
  });
});
