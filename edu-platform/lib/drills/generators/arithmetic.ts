// Mental arithmetic drill: +, −, × with operand ranges scaling by level.
// Typed numeric answer, exact match.

import type { DrillDef, Level, Problem } from "../types";
import { pid, pick, randInt } from "../rand";

type Op = "+" | "-" | "×";

const OP_TEX: Record<Op, string> = { "+": "+", "-": "-", "×": "\\times" };

// Per-level: which ops are allowed and the operand ranges.
const LEVELS: Record<Level, { ops: Op[]; a: [number, number]; b: [number, number] }> = {
  1: { ops: ["+", "-"], a: [2, 20], b: [2, 12] },
  2: { ops: ["+", "-", "×"], a: [10, 99], b: [2, 12] },
  3: { ops: ["+", "-", "×"], a: [12, 99], b: [12, 99] },
};

function generate(level: Level): Problem {
  const cfg = LEVELS[level];
  const op = pick(cfg.ops);
  let a = randInt(cfg.a[0], cfg.a[1]);
  let b = randInt(cfg.b[0], cfg.b[1]);

  // Keep subtraction non-negative (larger operand first).
  if (op === "-" && b > a) [a, b] = [b, a];

  const answer = op === "+" ? a + b : op === "-" ? a - b : a * b;

  return {
    id: pid("arithmetic"),
    prompt: { tex: `${a} ${OP_TEX[op]} ${b}` },
    input: { kind: "numeric", answer },
    explanation: { tex: `${a} ${OP_TEX[op]} ${b} = ${answer}` },
  };
}

export const arithmeticDrill: DrillDef = {
  slug: "arithmetic",
  title: "Mental Arithmetic",
  blurb: "Sharpen quick recall of addition, subtraction, and multiplication.",
  icon: "🧮",
  subject: "Mathematics",
  levels: [
    { value: 1, label: "Warm-up (+ −, small)" },
    { value: 2, label: "Standard (+ − ×)" },
    { value: 3, label: "Hard (two-digit ×)" },
  ],
  generate,
};
