import { describe, it, expect } from "vitest";
import { isTestTitle, lectureLabels, lectureSpan, sortLectures } from "@/lib/lectures";

const d = (s: string) => new Date(s);

describe("sortLectures", () => {
  const vids = [
    { id: "c", position: 0, publishedAt: d("2026-10-03") },
    { id: "a", position: 2, publishedAt: d("2026-10-01") },
    { id: "b", position: 1, publishedAt: d("2026-10-02") },
  ];
  it("orders chronologically, not by a newest-first playlist position", () => {
    expect(sortLectures(vids, false).map((v) => v.id)).toEqual(["a", "b", "c"]);
  });
  it("honours position on a hand-ordered course", () => {
    expect(sortLectures(vids, true).map((v) => v.id)).toEqual(["c", "b", "a"]);
  });
});

describe("lectureLabels / lectureSpan", () => {
  const ordered = [
    { id: "v1", title: "Lecture 0 — Intro" },
    { id: "v2", title: "Systems of equations" },
    { id: "v3", title: "Lesson 9: The Noun" },
  ];
  const labels = lectureLabels(ordered);
  it("reads the number from the title, else uses list place", () => {
    expect(labels.get("v1")).toEqual({ word: "Lecture", n: "0" });
    expect(labels.get("v2")).toEqual({ word: "Lecture", n: "2" });
    expect(labels.get("v3")).toEqual({ word: "Lesson", n: "9" });
  });
  it("spans covered lectures in course order", () => {
    expect(lectureSpan(["v2", "v1"], ordered, labels)).toBe("Lectures 0–2");
    expect(lectureSpan(["v3"], ordered, labels)).toBe("Lesson 9");
    expect(lectureSpan([], ordered, labels)).toBeNull();
  });
});

it("isTestTitle", () => {
  expect(isTestTitle("Test 1 — Chapter 1")).toBe(true);
  expect(isTestTitle("Practice Midterm")).toBe(true);
  expect(isTestTitle("2.3 Exercises")).toBe(false);
  expect(isTestTitle("Testing hypotheses")).toBe(false);
});
