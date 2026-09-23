import { describe, it, expect } from "vitest";
import { splitAuthored, pairProblemSet, canSeeSolutions, estimateWorkLines } from "@/lib/problem-sets";

describe("splitAuthored", () => {
  it("keeps everything before the first numbered item as preamble", () => {
    const md = ["# Chapter 3 Problems", "*Core: 10 points*", "", "**1.** First problem", "**2.** Second problem"].join("\n");
    const { preamble, chunks } = splitAuthored(md);
    expect(preamble).toContain("# Chapter 3 Problems");
    expect(preamble).toContain("Core: 10 points");
    expect(chunks).toHaveLength(2);
    expect(chunks[0]).toMatchObject({ kind: "item", key: "item:1", n: 1 });
    expect(chunks[1]).toMatchObject({ kind: "item", key: "item:2", n: 2 });
  });

  it("treats a heading BEFORE the first item as preamble, not a section", () => {
    const md = ["## Answer Key", "### Intro heading", "**1.** A problem"].join("\n");
    const { preamble, chunks } = splitAuthored(md);
    expect(preamble).toContain("### Intro heading");
    expect(chunks).toHaveLength(1);
    expect(chunks[0].kind).toBe("item");
  });

  it("opens a named section for a heading AFTER the first item", () => {
    const md = ["**1.** A problem", "### Extra Credit (3 pts •••)", "The bonus problem"].join("\n");
    const { chunks } = splitAuthored(md);
    expect(chunks).toHaveLength(2);
    expect(chunks[1]).toMatchObject({ kind: "section", key: "section:extra credit" });
    expect(chunks[1].content).toContain("The bonus problem");
  });

  it("normalizes a heading key: strips #, points tag, emphasis, and casing", () => {
    const md = ["**1.** p", "### **Extra Credit** (3 pts •••)"].join("\n");
    const { chunks } = splitAuthored(md);
    expect(chunks[1].key).toBe("section:extra credit");
  });

  it("collects multi-line item bodies until the next chunk", () => {
    const md = ["**1.** line one", "line two", "line three", "**2.** next"].join("\n");
    const { chunks } = splitAuthored(md);
    expect(chunks[0].content).toBe("**1.** line one\nline two\nline three");
  });

  it("parses a bold item with an inline points tag", () => {
    const md = "**1. (2 pts ••)** Solve it";
    const { chunks } = splitAuthored(md);
    expect(chunks[0]).toMatchObject({ kind: "item", n: 1 });
  });
});

describe("pairProblemSet", () => {
  const body = ["**1.** Problem one", "**2.** Problem two", "### Extra Credit (3 pts •••)", "Bonus problem"].join("\n");
  const solution = ["**1.** Answer one", "**2.** Answer two", "### Extra Credit", "Bonus answer"].join("\n");

  it("pairs numbered items and named sections by key", () => {
    const paired = pairProblemSet(body, solution, true);
    expect(paired.mode).toBe("paired");
    if (paired.mode !== "paired") throw new Error("unreachable");
    expect(paired.parts).toHaveLength(3);
    expect(paired.parts[0]).toMatchObject({ label: "1", solution: expect.stringContaining("Answer one") });
    expect(paired.parts[1]).toMatchObject({ label: "2", solution: expect.stringContaining("Answer two") });
    // Section label is title-cased from the normalized key.
    expect(paired.parts[2]).toMatchObject({ label: "Extra Credit", solution: expect.stringContaining("Bonus answer") });
  });

  it("withholds solutions but keeps the same shape when includeSolutions=false", () => {
    const paired = pairProblemSet(body, solution, false);
    expect(paired.mode).toBe("paired");
    if (paired.mode !== "paired") throw new Error("unreachable");
    expect(paired.parts).toHaveLength(3);
    expect(paired.parts.every((p) => p.solution === null)).toBe(true);
  });

  it("a problem with no matching solution simply gets a null solution (not blocks)", () => {
    const paired = pairProblemSet(body, "**1.** Only answer one", true);
    expect(paired.mode).toBe("paired");
    if (paired.mode !== "paired") throw new Error("unreachable");
    expect(paired.parts[0].solution).toContain("Only answer one");
    expect(paired.parts[1].solution).toBeNull();
    expect(paired.parts[2].solution).toBeNull();
  });

  it("an ORPHANED solution (no matching problem) forces blocks mode so nothing is dropped", () => {
    const orphan = ["**1.** Answer one", "**99.** Answer to a nonexistent problem"].join("\n");
    const paired = pairProblemSet(body, orphan, true);
    expect(paired.mode).toBe("blocks");
    if (paired.mode !== "blocks") throw new Error("unreachable");
    expect(paired.solution).toBe(orphan);
    expect(paired.body).toBe(body);
  });

  it("duplicate solution keys force blocks mode (ambiguous pairing)", () => {
    const dup = ["**1.** Answer one", "**1.** Answer one again"].join("\n");
    const paired = pairProblemSet(body, dup, true);
    expect(paired.mode).toBe("blocks");
  });

  it("no numbered items or sections at all → blocks mode with the whole body", () => {
    const paired = pairProblemSet("Just a paragraph of prose.", "Some answer.", true);
    expect(paired.mode).toBe("blocks");
    if (paired.mode !== "blocks") throw new Error("unreachable");
    expect(paired.solution).toBe("Some answer.");
  });

  it("empty solution yields paired mode with null solutions", () => {
    const paired = pairProblemSet(body, "   ", true);
    expect(paired.mode).toBe("paired");
    if (paired.mode !== "paired") throw new Error("unreachable");
    expect(paired.parts.every((p) => p.solution === null)).toBe(true);
  });
});

describe("canSeeSolutions", () => {
  it("mirrors the solutionsPublic flag", () => {
    expect(canSeeSolutions({ solutionsPublic: true })).toBe(true);
    expect(canSeeSolutions({ solutionsPublic: false })).toBe(false);
  });
});

describe("estimateWorkLines", () => {
  it("gives a sane default when there's no solution to gauge", () => {
    expect(estimateWorkLines(null)).toBe(5);
    expect(estimateWorkLines("")).toBe(5);
    expect(estimateWorkLines("   ")).toBe(5);
  });

  it("never cramps and never overruns a page", () => {
    expect(estimateWorkLines("x")).toBeGreaterThanOrEqual(4);
    const huge = "word ".repeat(1000) + "$$\\begin{bmatrix}1\\end{bmatrix}$$".repeat(20);
    expect(estimateWorkLines(huge)).toBeLessThanOrEqual(24);
  });

  it("leaves more room for a longer, matrix-heavy solution than a short one", () => {
    const short = "**1.** The answer is $x = 2$.";
    const long =
      "**1.** Row reduce: $$\\begin{bmatrix}1&2\\\\3&4\\end{bmatrix} \\to \\begin{bmatrix}1&0\\\\0&1\\end{bmatrix}$$ " +
      "so the pivots are in both columns and the system has a unique solution after back-substitution.";
    expect(estimateWorkLines(long)).toBeGreaterThan(estimateWorkLines(short));
  });
});
