// Mental arithmetic drill: +, −, ×, ÷ with operand ranges scaling by level.
// Typed numeric answer, exact match.
//
// Design: subtraction and division are the *inverses* of addition and
// multiplication, so they reuse the exact same operand generation. We pick two
// operands (a, b) from a family's range, then either present the forward
// problem (a + b, a × b) or the inverse: form the result (sum a+b, product a×b),
// subtract/divide one operand back out, and ask the player for the other. This
// guarantees inverse problems are always clean (non-negative differences,
// integer quotients) and keeps their magnitudes tied to the forward ranges —
// e.g. addition on 1–13 yields differences no larger than 26 − 13.

import type { DrillDef, Level, Problem } from "../types";
import { pid, pick, randInt } from "../rand";

type Op = "+" | "-" | "×" | "÷";

const OP_TEX: Record<Op, string> = { "+": "+", "-": "-", "×": "\\times", "÷": "\\div" };

// Per-level config:
//   ops  — which operators are offered.
//   add  — additive family: both + and − operands are drawn from this range.
//   mulA / mulB — multiplicative family: × and ÷ operands are drawn from these
//          (two ranges so hard can pair a 1–13 factor with an 11–20 factor).
const LEVELS: Record<Level, { ops: Op[]; add: [number, number]; mulA: [number, number]; mulB: [number, number] }> = {
  // Easy: +, −, ×. Sums up to 13+13; differences up to 26−13; products up to 6×6.
  1: { ops: ["+", "-", "×"], add: [1, 13], mulA: [1, 6], mulB: [1, 6] },
  // Standard: all four. Sums up to 50+50 (diff 100−50); products up to 13×13 (quotient 169÷13).
  2: { ops: ["+", "-", "×", "÷"], add: [1, 50], mulA: [1, 13], mulB: [1, 13] },
  // Hard: all four. Sums up to 500+500 (diff 1000−500); products up to 13×20 (quotient 260÷13 or 260÷20).
  3: { ops: ["+", "-", "×", "÷"], add: [1, 500], mulA: [1, 13], mulB: [11, 20] },
};

function numericProblem(a: number, opTex: string, b: number, answer: number): Problem {
  return {
    id: pid("arithmetic"),
    prompt: { tex: `${a} ${opTex} ${b}` },
    input: { kind: "numeric", answer },
    explanation: { tex: `${a} ${opTex} ${b} = ${answer}` },
  };
}

function generate(level: Level): Problem {
  const cfg = LEVELS[level];
  const op = pick(cfg.ops);

  if (op === "+" || op === "-") {
    const a = randInt(cfg.add[0], cfg.add[1]);
    const b = randInt(cfg.add[0], cfg.add[1]);
    if (op === "+") return numericProblem(a, OP_TEX["+"], b, a + b);
    // Subtraction = inverse of a+b: minuend is the sum; subtract one operand,
    // solve for the other. Randomize which operand is the subtrahend.
    const sum = a + b;
    const subtrahend = randInt(0, 1) === 0 ? a : b;
    return numericProblem(sum, OP_TEX["-"], subtrahend, sum - subtrahend);
  }

  // Multiplicative family (× and ÷).
  const a = randInt(cfg.mulA[0], cfg.mulA[1]);
  const b = randInt(cfg.mulB[0], cfg.mulB[1]);
  if (op === "×") return numericProblem(a, OP_TEX["×"], b, a * b);
  // Division = inverse of a×b: dividend is the product; divide by one operand,
  // solve for the other. Randomize which operand is the divisor.
  const product = a * b;
  const divisor = randInt(0, 1) === 0 ? a : b;
  return numericProblem(product, OP_TEX["÷"], divisor, product / divisor);
}

export const arithmeticDrill: DrillDef = {
  slug: "arithmetic",
  title: "Mental Arithmetic",
  blurb: "Sharpen quick recall of addition, subtraction, multiplication, and division.",
  icon: "🧮",
  subject: "Mathematics",
  levels: [
    { value: 1, label: "Easy (+ − ×, small)" },
    { value: 2, label: "Standard (+ − × ÷)" },
    { value: 3, label: "Hard (+ − × ÷, large)" },
  ],
  generate,
};
