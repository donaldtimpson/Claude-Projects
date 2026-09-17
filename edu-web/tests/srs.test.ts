import { describe, it, expect } from "vitest";
import { nextSchedule, INTERVALS_DAYS, MAX_BOX } from "@/lib/srs";

const DAY_MS = 86_400_000;

// A fixed "now" mid-day, to prove scheduling snaps to the UTC day boundary
// regardless of the time of day the card was answered.
const NOW = new Date("2026-03-10T15:37:00.000Z");
const startOfNowUtcDay = Math.floor(NOW.getTime() / DAY_MS) * DAY_MS;

function expectedDue(box: number): number {
  return startOfNowUtcDay + INTERVALS_DAYS[box] * DAY_MS;
}

describe("nextSchedule — Leitner promotion / reset", () => {
  it("a brand-new card (prevBox null) answered correctly lands in box 2", () => {
    const { box, dueAt } = nextSchedule(null, true, NOW);
    expect(box).toBe(2);
    expect(dueAt.getTime()).toBe(expectedDue(2));
  });

  it("a brand-new card answered wrong sits in box 1", () => {
    const { box, dueAt } = nextSchedule(null, false, NOW);
    expect(box).toBe(1);
    expect(dueAt.getTime()).toBe(expectedDue(1));
  });

  it("a correct answer promotes an existing card one box", () => {
    for (let prev = 1; prev < MAX_BOX; prev++) {
      const { box } = nextSchedule(prev, true, NOW);
      expect(box).toBe(prev + 1);
    }
  });

  it("promotion is capped at MAX_BOX", () => {
    const atTop = nextSchedule(MAX_BOX, true, NOW);
    expect(atTop.box).toBe(MAX_BOX);
    expect(atTop.dueAt.getTime()).toBe(expectedDue(MAX_BOX));
  });

  it("a wrong answer resets any box back to box 1", () => {
    for (let prev = 1; prev <= MAX_BOX; prev++) {
      const { box, dueAt } = nextSchedule(prev, false, NOW);
      expect(box).toBe(1);
      expect(dueAt.getTime()).toBe(expectedDue(1));
    }
  });

  it("each box's interval matches the declared INTERVALS_DAYS table", () => {
    // Correct answer from box (b-1) lands in box b, due INTERVALS_DAYS[b] days out.
    for (let b = 2; b <= MAX_BOX; b++) {
      const { dueAt } = nextSchedule(b - 1, true, NOW);
      const daysOut = (dueAt.getTime() - startOfNowUtcDay) / DAY_MS;
      expect(daysOut).toBe(INTERVALS_DAYS[b]);
    }
  });

  it("due date snaps to the UTC day boundary regardless of time of day", () => {
    const early = nextSchedule(1, true, new Date("2026-03-10T00:00:01.000Z"));
    const late = nextSchedule(1, true, new Date("2026-03-10T23:59:59.000Z"));
    expect(early.dueAt.getTime()).toBe(late.dueAt.getTime());
    // Box 2 interval is 3 days → a card answered today is never due the same day.
    expect(early.dueAt.getTime()).toBeGreaterThan(startOfNowUtcDay);
  });

  it("box-1 card (interval 1) answered today is due the next UTC day, not today", () => {
    const { dueAt } = nextSchedule(null, false, NOW);
    expect(dueAt.getTime()).toBe(startOfNowUtcDay + 1 * DAY_MS);
    expect(dueAt.getTime()).toBeGreaterThan(NOW.getTime());
  });
});
