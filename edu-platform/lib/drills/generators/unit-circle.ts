// Unit-circle trig drill: evaluate sin/cos/tan at standard angles.
//
// The key design choice: exact values are identified by a CANONICAL KEY, never by
// float comparison. Each value carries a KaTeX string; options are built from the
// set of values that actually occur for the asked function, so distractors are
// always plausible. Math.sin is used ONLY to position the diagram, never to grade.

import type { DrillDef, Level, Problem, Renderable } from "../types";
import { pid, pick, sampleDistinct, shuffle } from "../rand";

// Canonical exact values. The key is the identity; `tex` is display only.
type ValueKey =
  | "0" | "1" | "-1"
  | "1/2" | "-1/2"
  | "√2/2" | "-√2/2"
  | "√3/2" | "-√3/2"
  | "√3/3" | "-√3/3"
  | "√3" | "-√3"
  | "undef";

const VALUES: Record<ValueKey, Renderable> = {
  "0": { tex: "0" },
  "1": { tex: "1" },
  "-1": { tex: "-1" },
  "1/2": { tex: "\\tfrac{1}{2}" },
  "-1/2": { tex: "-\\tfrac{1}{2}" },
  "√2/2": { tex: "\\tfrac{\\sqrt{2}}{2}" },
  "-√2/2": { tex: "-\\tfrac{\\sqrt{2}}{2}" },
  "√3/2": { tex: "\\tfrac{\\sqrt{3}}{2}" },
  "-√3/2": { tex: "-\\tfrac{\\sqrt{3}}{2}" },
  "√3/3": { tex: "\\tfrac{\\sqrt{3}}{3}" },
  "-√3/3": { tex: "-\\tfrac{\\sqrt{3}}{3}" },
  "√3": { tex: "\\sqrt{3}" },
  "-√3": { tex: "-\\sqrt{3}" },
  undef: { tex: "\\text{undefined}" },
};

type Angle = { rad: number; tex: string; sin: ValueKey; cos: ValueKey; tan: ValueKey };

// Standard angles 0..2π in π/6 and π/4 increments, with precomputed exact values.
const ANGLES: Angle[] = [
  { rad: 0, tex: "0", sin: "0", cos: "1", tan: "0" },
  { rad: Math.PI / 6, tex: "\\tfrac{\\pi}{6}", sin: "1/2", cos: "√3/2", tan: "√3/3" },
  { rad: Math.PI / 4, tex: "\\tfrac{\\pi}{4}", sin: "√2/2", cos: "√2/2", tan: "1" },
  { rad: Math.PI / 3, tex: "\\tfrac{\\pi}{3}", sin: "√3/2", cos: "1/2", tan: "√3" },
  { rad: Math.PI / 2, tex: "\\tfrac{\\pi}{2}", sin: "1", cos: "0", tan: "undef" },
  { rad: (2 * Math.PI) / 3, tex: "\\tfrac{2\\pi}{3}", sin: "√3/2", cos: "-1/2", tan: "-√3" },
  { rad: (3 * Math.PI) / 4, tex: "\\tfrac{3\\pi}{4}", sin: "√2/2", cos: "-√2/2", tan: "-1" },
  { rad: (5 * Math.PI) / 6, tex: "\\tfrac{5\\pi}{6}", sin: "1/2", cos: "-√3/2", tan: "-√3/3" },
  { rad: Math.PI, tex: "\\pi", sin: "0", cos: "-1", tan: "0" },
  { rad: (7 * Math.PI) / 6, tex: "\\tfrac{7\\pi}{6}", sin: "-1/2", cos: "-√3/2", tan: "√3/3" },
  { rad: (5 * Math.PI) / 4, tex: "\\tfrac{5\\pi}{4}", sin: "-√2/2", cos: "-√2/2", tan: "1" },
  { rad: (4 * Math.PI) / 3, tex: "\\tfrac{4\\pi}{3}", sin: "-√3/2", cos: "-1/2", tan: "√3" },
  { rad: (3 * Math.PI) / 2, tex: "\\tfrac{3\\pi}{2}", sin: "-1", cos: "0", tan: "undef" },
  { rad: (5 * Math.PI) / 3, tex: "\\tfrac{5\\pi}{3}", sin: "-√3/2", cos: "1/2", tan: "-√3" },
  { rad: (7 * Math.PI) / 4, tex: "\\tfrac{7\\pi}{4}", sin: "-√2/2", cos: "√2/2", tan: "-1" },
  { rad: (11 * Math.PI) / 6, tex: "\\tfrac{11\\pi}{6}", sin: "-1/2", cos: "√3/2", tan: "-√3/3" },
];

type Fn = "sin" | "cos" | "tan";
const FN_TEX: Record<Fn, string> = { sin: "\\sin", cos: "\\cos", tan: "\\tan" };

// The pool of values each function actually takes (for plausible distractors).
const SINCOS_POOL: ValueKey[] = ["0", "1", "-1", "1/2", "-1/2", "√2/2", "-√2/2", "√3/2", "-√3/2"];
const TAN_POOL: ValueKey[] = ["0", "1", "-1", "√3/3", "-√3/3", "√3", "-√3", "undef"];

// Per-level: which functions and how many of the 16 angles are in play.
const LEVELS: Record<Level, { fns: Fn[]; angleCount: number }> = {
  1: { fns: ["sin", "cos"], angleCount: 5 }, // first quadrant (0..π/2)
  2: { fns: ["sin", "cos", "tan"], angleCount: 9 }, // first two quadrants (0..π)
  3: { fns: ["sin", "cos", "tan"], angleCount: ANGLES.length }, // full circle
};

function generate(level: Level): Problem {
  const cfg = LEVELS[level];
  const angle = pick(ANGLES.slice(0, cfg.angleCount));
  const fn = pick(cfg.fns);
  const correctKey = angle[fn];

  const pool = fn === "tan" ? TAN_POOL : SINCOS_POOL;
  const distractors = sampleDistinct(pool, 3, new Set<ValueKey>([correctKey]));
  const optionKeys = shuffle([correctKey, ...distractors]);
  const correctIndex = optionKeys.indexOf(correctKey);

  return {
    id: pid("unit-circle"),
    prompt: { tex: `${FN_TEX[fn]}\\!\\left(${angle.tex}\\right)` },
    input: {
      kind: "choice",
      options: optionKeys.map((k) => VALUES[k]),
      correctIndex,
    },
    explanation: {
      tex: `${FN_TEX[fn]}\\!\\left(${angle.tex}\\right) = ${
        (VALUES[correctKey] as { tex: string }).tex
      }`,
    },
    diagram: { kind: "unit-circle", angleRad: angle.rad, fn },
  };
}

export const unitCircleDrill: DrillDef = {
  slug: "unit-circle",
  title: "Unit Circle",
  blurb: "Recall the exact values of sine, cosine, and tangent at standard angles.",
  icon: "🔵",
  subject: "Mathematics",
  levels: [
    { value: 1, label: "Quadrant I (sin, cos)" },
    { value: 2, label: "Half circle (+ tan)" },
    { value: 3, label: "Full circle" },
  ],
  generate,
};
