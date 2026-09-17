import { describe, it, expect } from "vitest";
import { normalizeReason, REPORT_REASONS } from "@/lib/moderation";

describe("normalizeReason", () => {
  it("passes through every valid reason", () => {
    for (const r of REPORT_REASONS) {
      expect(normalizeReason(r)).toBe(r);
    }
  });

  it("falls back to OTHER for unknown or malformed input", () => {
    expect(normalizeReason("nonsense")).toBe("OTHER");
    expect(normalizeReason("")).toBe("OTHER");
    expect(normalizeReason(undefined)).toBe("OTHER");
    expect(normalizeReason(null)).toBe("OTHER");
    expect(normalizeReason(42)).toBe("OTHER");
    expect(normalizeReason("spam")).toBe("OTHER"); // case-sensitive: lowercase is not a valid enum
  });
});
