// Early linear-algebra drills for the LA course: 2×2 determinant, solve a 2×2
// system, matrix × vector, and dot product. All multiple choice so answers can be
// ordered pairs / signed scalars. KaTeX renders matrices, systems, and vectors.

import type { DrillDef, Level, Problem } from "../types";
import { pid, randInt, pick } from "../rand";
import { fourChoices } from "./mental-math";

const LEVELS = [
  { value: 1 as Level, label: "Easy" },
  { value: 2 as Level, label: "Standard" },
  { value: 3 as Level, label: "Hard" },
];

// a x + b y = c, tidy signs; drops zero terms.
function eqTex(a: number, b: number, c: number): string {
  let s = "";
  if (a !== 0) s += a === 1 ? "x" : a === -1 ? "-x" : `${a}x`;
  if (b !== 0) {
    const mag = Math.abs(b) === 1 ? "y" : `${Math.abs(b)}y`;
    if (s === "") s += b < 0 ? `-${mag}` : mag;
    else s += b < 0 ? ` - ${mag}` : ` + ${mag}`;
  }
  return `${s} = ${c}`;
}
const pairTex = (x: number, y: number) => `(${x},\\ ${y})`;

export const determinantDrill: DrillDef = {
  slug: "determinant", title: "2×2 Determinant",
  blurb: "Compute ad − bc for a 2×2 matrix.",
  icon: "▦", subject: "Linear Algebra", levels: LEVELS,
  generate(level: Level): Problem {
    const lo = level === 1 ? 1 : level === 2 ? -6 : -12;
    const hi = level === 1 ? 6 : level === 2 ? 9 : 12;
    const e = () => randInt(lo, hi);
    const a = e(), b = e(), c = e(), d = e();
    const det = a * d - b * c;
    const { options, correctIndex } = fourChoices(`${det}`, [
      `${a * d + b * c}`, `${b * c - a * d}`, `${a * b - c * d}`, `${det + 3}`, `${det - 4}`,
    ]);
    return {
      id: pid("determinant"),
      prompt: { tex: `\\begin{vmatrix} ${a} & ${b} \\\\ ${c} & ${d} \\end{vmatrix}` },
      input: { kind: "choice", options: options.map((t) => ({ tex: t })), correctIndex },
      explanation: { tex: `ad - bc = (${a})(${d}) - (${b})(${c}) = ${det}` },
    };
  },
};

export const solveSystemDrill: DrillDef = {
  slug: "solve-system", title: "Solve the System",
  blurb: "Two equations, two unknowns — find the (x, y) that works.",
  icon: "⊞", subject: "Linear Algebra", levels: LEVELS,
  generate(level: Level): Problem {
    const lo = level === 1 ? 0 : level === 2 ? -3 : -5;
    const hi = level === 1 ? 4 : level === 2 ? 4 : 5;
    const coefR = level === 1 ? [-2, -1, 1, 2] : [-3, -2, -1, 1, 2, 3];
    const x = randInt(lo, hi), y = randInt(lo, hi);
    let a1 = 1, b1 = 1, a2 = 1, b2 = 1;
    do { a1 = pick(coefR); b1 = pick(coefR); a2 = pick(coefR); b2 = pick(coefR); } while (a1 * b2 - a2 * b1 === 0);
    const c1 = a1 * x + b1 * y, c2 = a2 * x + b2 * y;
    const { options, correctIndex } = fourChoices(pairTex(x, y), [
      pairTex(y, x), pairTex(-x, y), pairTex(x, -y), pairTex(x + 1, y - 1),
    ]);
    return {
      id: pid("solve-system"),
      prompt: { tex: `\\begin{cases} ${eqTex(a1, b1, c1)} \\\\ ${eqTex(a2, b2, c2)} \\end{cases}` },
      input: { kind: "choice", options: options.map((t) => ({ tex: t })), correctIndex },
      explanation: { tex: `x = ${x},\\ y = ${y}` },
    };
  },
};

export const matrixVectorDrill: DrillDef = {
  slug: "matrix-vector", title: "Matrix × Vector",
  blurb: "Multiply a 2×2 matrix by a vector — rows dotted with the vector.",
  icon: "⧉", subject: "Linear Algebra", levels: LEVELS,
  generate(level: Level): Problem {
    const lo = level === 1 ? -2 : level === 2 ? -3 : -5;
    const hi = level === 1 ? 3 : level === 2 ? 4 : 5;
    const e = () => randInt(lo, hi);
    const a = e(), b = e(), c = e(), d = e(), x = e(), y = e();
    const p = a * x + b * y, q = c * x + d * y;
    const { options, correctIndex } = fourChoices(pairTex(p, q), [
      pairTex(a * x, d * y),          // component-wise mistake
      pairTex(q, p),                  // rows swapped
      pairTex(a * x + b * y, c * x - d * y),
      pairTex(p + 1, q),
    ]);
    return {
      id: pid("matrix-vector"),
      prompt: { tex: `\\begin{bmatrix} ${a} & ${b} \\\\ ${c} & ${d} \\end{bmatrix}\\begin{bmatrix} ${x} \\\\ ${y} \\end{bmatrix}` },
      input: { kind: "choice", options: options.map((t) => ({ tex: t })), correctIndex },
      explanation: { tex: `\\text{Row 1}\\cdot v = ${p},\\ \\text{Row 2}\\cdot v = ${q}` },
    };
  },
};

export const dotProductDrill: DrillDef = {
  slug: "dot-product", title: "Dot Product",
  blurb: "Multiply matching components and add them up.",
  icon: "•", subject: "Linear Algebra", levels: LEVELS,
  generate(level: Level): Problem {
    const lo = level === 1 ? -3 : level === 2 ? -5 : -8;
    const hi = level === 1 ? 4 : level === 2 ? 6 : 8;
    const e = () => randInt(lo, hi);
    const a1 = e(), a2 = e(), b1 = e(), b2 = e();
    const dot = a1 * b1 + a2 * b2;
    const { options, correctIndex } = fourChoices(`${dot}`, [
      `${a1 * b1 - a2 * b2}`, `${a1 * b2 + a2 * b1}`, `${dot + 2}`, `${dot - 3}`,
    ]);
    return {
      id: pid("dot-product"),
      prompt: { tex: `(${a1},\\ ${a2}) \\cdot (${b1},\\ ${b2})` },
      input: { kind: "choice", options: options.map((t) => ({ tex: t })), correctIndex },
      explanation: { tex: `(${a1})(${b1}) + (${a2})(${b2}) = ${dot}` },
    };
  },
};
