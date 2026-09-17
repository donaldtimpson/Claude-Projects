import { describe, it, expect } from "vitest";
import { currentDayStreak, generateHandle } from "@/lib/gamification/engine";
import { sumBadgePoints, TIERS, BADGE_CATALOG, type Badge } from "@/lib/gamification/mock";

const DAY_MS = 86_400_000;

// A date whose UTC-day floor is exactly `n` whole days before today's UTC-day
// floor. currentDayStreak buckets by Math.floor(getTime()/DAY_MS), so we anchor
// to that same boundary and add a few hours so it never lands on a seam.
function daysAgo(n: number): Date {
  const todayFloor = Math.floor(Date.now() / DAY_MS) * DAY_MS;
  return new Date(todayFloor - n * DAY_MS + 6 * 3_600_000);
}

describe("currentDayStreak", () => {
  it("no activity → count 0, not active today", () => {
    expect(currentDayStreak([])).toEqual({ count: 0, activeToday: false });
  });

  it("activity only today → count 1, active today", () => {
    expect(currentDayStreak([daysAgo(0)])).toEqual({ count: 1, activeToday: true });
  });

  it("counts a consecutive run ending today", () => {
    const { count, activeToday } = currentDayStreak([daysAgo(0), daysAgo(1), daysAgo(2)]);
    expect(count).toBe(3);
    expect(activeToday).toBe(true);
  });

  it("grace: no activity today but active yesterday still shows the streak", () => {
    const { count, activeToday } = currentDayStreak([daysAgo(1), daysAgo(2)]);
    expect(count).toBe(2);
    expect(activeToday).toBe(false);
  });

  it("a two-day gap breaks the current streak (yesterday empty, day-before present)", () => {
    // Only day-2 present: not today, not yesterday → streak is 0.
    expect(currentDayStreak([daysAgo(2), daysAgo(3)])).toEqual({ count: 0, activeToday: false });
  });

  it("multiple stamps on the same day count once", () => {
    const { count } = currentDayStreak([daysAgo(0), daysAgo(0), daysAgo(1)]);
    expect(count).toBe(2);
  });

  it("only the trailing consecutive run counts, ignoring an earlier island", () => {
    const { count } = currentDayStreak([daysAgo(0), daysAgo(1), daysAgo(10), daysAgo(11)]);
    expect(count).toBe(2);
  });
});

describe("generateHandle", () => {
  it("is deterministic for a given user id", () => {
    expect(generateHandle("user-abc")).toBe(generateHandle("user-abc"));
  });

  it("produces a non-empty AdjectiveNoun handle (never an undefined index)", () => {
    // The comment in engine.ts warns a signed shift could produce an undefined
    // index; assert the noun half is always a real word across many ids.
    for (let i = 0; i < 500; i++) {
      const h = generateHandle(`u-${i}-${i * 7919}`);
      expect(h).toMatch(/^[A-Z][a-z]+[A-Z][a-z]+$/);
      expect(h).not.toContain("undefined");
    }
  });

  it("varies across different ids", () => {
    const handles = new Set(Array.from({ length: 50 }, (_, i) => generateHandle(`id-${i}`)));
    expect(handles.size).toBeGreaterThan(1);
  });
});

describe("sumBadgePoints", () => {
  it("sums only unlocked badges by their tier points", () => {
    const badges: Badge[] = [
      { key: "a", name: "", blurb: "", tier: "bronze", category: "milestones", unlocked: true },
      { key: "b", name: "", blurb: "", tier: "gold", category: "mastery", unlocked: true },
      { key: "c", name: "", blurb: "", tier: "platinum", category: "completion", unlocked: false },
    ];
    expect(sumBadgePoints(badges)).toBe(TIERS.bronze.points + TIERS.gold.points);
  });

  it("locked-only or empty → 0", () => {
    expect(sumBadgePoints([])).toBe(0);
    expect(
      sumBadgePoints(BADGE_CATALOG.map((b) => ({ ...b, unlocked: false }))),
    ).toBe(0);
  });
});
