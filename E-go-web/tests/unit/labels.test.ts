import { describe, expect, it } from "vitest";

import {
  bookingStatusCopy,
  bookingStatusLabels,
  cancellationReasonOptions,
  errorCopy,
  faqItems,
  ratingTagLimit,
  ratingTags,
} from "@/lib/domain/labels";
import { BOOKING_STATUSES, type AppErrorCode } from "@/lib/domain/types";

const TONES = ["neutral", "info", "success", "warning", "danger"];
const ICONS = [
  "ready",
  "pin",
  "flag",
  "car",
  "receipt",
  "check",
  "search",
  "driver",
  "arriving",
  "arrived",
  "trip",
  "done",
  "star",
  "rated",
  "cancelled",
  "failed",
];

const ERROR_CODES: AppErrorCode[] = [
  "invalid_phone",
  "invalid_otp",
  "otp_expired",
  "otp_cooldown",
  "invalid_credentials",
  "account_exists",
  "not_found",
  "invalid_transition",
  "storage_corrupt",
  "demo_disabled",
  "unknown",
];

describe("booking status copy", () => {
  it("has a label and a body for every status", () => {
    for (const status of BOOKING_STATUSES) {
      const label = bookingStatusLabels[status];
      const copy = bookingStatusCopy[status];

      expect(label.trim().length, status).toBeGreaterThan(0);
      expect(copy.label, status).toBe(label);
      expect(copy.body.trim().length, status).toBeGreaterThan(0);
      expect(TONES, status).toContain(copy.tone);
      expect(ICONS, status).toContain(copy.icon);
    }
  });
});

describe("error copy", () => {
  it("covers every error code", () => {
    for (const code of ERROR_CODES) {
      expect(errorCopy[code], code).toBeTruthy();
      expect(errorCopy[code].trim().length, code).toBeGreaterThan(0);
    }
  });
});

describe("faq", () => {
  it("ships at least five answered questions", () => {
    expect(faqItems.length).toBeGreaterThanOrEqual(5);
    for (const item of faqItems) {
      expect(item.question.trim().length, item.id).toBeGreaterThan(0);
      expect(item.answer.trim().length, item.id).toBeGreaterThan(0);
    }
  });
});

describe("cancellation reasons", () => {
  it("offers every reason exactly once", () => {
    const values = cancellationReasonOptions.map((option) => option.value);
    expect(values).toHaveLength(4);
    expect(values).toEqual(
      expect.arrayContaining(["driver_too_far", "waiting_too_long", "changed_plan", "other"]),
    );
    for (const option of cancellationReasonOptions) {
      expect(option.label.trim().length, option.value).toBeGreaterThan(0);
    }
  });
});

describe("rating tags", () => {
  it("offers six tags but stores at most five", () => {
    expect(ratingTags).toHaveLength(6);
    expect(ratingTagLimit).toBe(5);
    for (const tag of ratingTags) {
      expect(tag.trim().length).toBeGreaterThan(0);
    }
  });
});
