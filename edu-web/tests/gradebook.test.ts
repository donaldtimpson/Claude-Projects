import { describe, it, expect } from "vitest";
import {
  parseGradeConfig,
  weightedGrade,
  DEFAULT_WEIGHTS,
  DEFAULT_CONFIG,
} from "@/lib/gradebook";

describe("weightedGrade — running weighted average", () => {
  it("averages present categories by weight, ignoring null (not-yet-entered) ones", () => {
    // 90 @ w10 and 80 @ w25 → (90*10 + 80*25) / (10+25) = 2900/35 ≈ 82.857
    const g = weightedGrade([
      { pct: 90, weight: 10 },
      { pct: 80, weight: 25 },
      { pct: null, weight: 25 }, // e.g. no final yet — excluded, not a zero
    ]);
    expect(g).toBeCloseTo(2900 / 35, 10);
  });

  it("a not-yet-entered category does NOT read as a zero", () => {
    const withMissing = weightedGrade([
      { pct: 100, weight: 10 },
      { pct: null, weight: 90 },
    ]);
    // Only the present category counts → 100, not 10.
    expect(withMissing).toBe(100);
  });

  it("an explicit 0% counts (distinct from a blank null)", () => {
    const g = weightedGrade([
      { pct: 0, weight: 50 },
      { pct: 100, weight: 50 },
    ]);
    expect(g).toBe(50);
  });

  it("categories with weight ≤ 0 are excluded", () => {
    const g = weightedGrade([
      { pct: 50, weight: 0 },
      { pct: 90, weight: 10 },
      { pct: 40, weight: -5 },
    ]);
    expect(g).toBe(90);
  });

  it("returns null when nothing has data (no zero-division, no false 0)", () => {
    expect(weightedGrade([])).toBeNull();
    expect(weightedGrade([{ pct: null, weight: 10 }])).toBeNull();
    expect(weightedGrade([{ pct: 95, weight: 0 }])).toBeNull();
  });

  it("full six-category realistic case matches a hand computation", () => {
    // attendance 100@10, quizzes 88@10, test 92@5, homework 85@25, midterm 78@25, final null@25
    const g = weightedGrade([
      { pct: 100, weight: 10 },
      { pct: 88, weight: 10 },
      { pct: 92, weight: 5 },
      { pct: 85, weight: 25 },
      { pct: 78, weight: 25 },
      { pct: null, weight: 25 },
    ]);
    const num = 100 * 10 + 88 * 10 + 92 * 5 + 85 * 25 + 78 * 25;
    const den = 10 + 10 + 5 + 25 + 25;
    expect(g).toBeCloseTo(num / den, 10);
  });
});

describe("parseGradeConfig", () => {
  it("returns DEFAULT_CONFIG for null / non-object input", () => {
    expect(parseGradeConfig(null)).toEqual(DEFAULT_CONFIG);
    expect(parseGradeConfig(undefined)).toEqual(DEFAULT_CONFIG);
    expect(parseGradeConfig("nope")).toEqual(DEFAULT_CONFIG);
    expect(parseGradeConfig(42)).toEqual(DEFAULT_CONFIG);
  });

  it("fills each missing weight with its default", () => {
    const cfg = parseGradeConfig({ weights: { attendance: 20 } });
    expect(cfg.weights.attendance).toBe(20);
    expect(cfg.weights.quizzes).toBe(DEFAULT_WEIGHTS.quizzes);
    expect(cfg.weights.final).toBe(DEFAULT_WEIGHTS.final);
  });

  it("accepts a 0 weight (a real, intentional value)", () => {
    const cfg = parseGradeConfig({ weights: { test: 0 } });
    expect(cfg.weights.test).toBe(0);
  });

  it("rejects negative / non-finite / non-number weights, falling back to default", () => {
    const cfg = parseGradeConfig({
      weights: { attendance: -5, quizzes: NaN, test: Infinity, homework: "25" },
    });
    expect(cfg.weights.attendance).toBe(DEFAULT_WEIGHTS.attendance);
    expect(cfg.weights.quizzes).toBe(DEFAULT_WEIGHTS.quizzes);
    expect(cfg.weights.test).toBe(DEFAULT_WEIGHTS.test);
    expect(cfg.weights.homework).toBe(DEFAULT_WEIGHTS.homework);
  });

  it("reads valid midterm/final maxes", () => {
    const cfg = parseGradeConfig({ midtermMax: 50, finalMax: 200 });
    expect(cfg.midtermMax).toBe(50);
    expect(cfg.finalMax).toBe(200);
  });

  it("coerces a 0 or invalid exam max to 100 (never divides by zero)", () => {
    const zero = parseGradeConfig({ midtermMax: 0, finalMax: 0 });
    expect(zero.midtermMax).toBe(100);
    expect(zero.finalMax).toBe(100);
    const bad = parseGradeConfig({ midtermMax: -10, finalMax: NaN });
    expect(bad.midtermMax).toBe(100);
    expect(bad.finalMax).toBe(100);
  });
});
