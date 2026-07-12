// Calculus drills: power-rule derivatives and integrals. Multiple choice, since
// the answer is an expression, not a number. KaTeX renders the options.

import type { DrillDef, Level, Problem } from "../types";
import { pid, randInt } from "../rand";
import { fourChoices } from "./mental-math";

const LEVELS = [
  { value: 1 as Level, label: "Easy" },
  { value: 2 as Level, label: "Standard" },
  { value: 3 as Level, label: "Hard" },
];

// Render c·xⁿ compactly in tex: 12x^{4}, 3x, 5 (n=0), x^{2} (c=1), -x^{3}.
function powTermTex(c: number, n: number): string {
  if (n === 0) return `${c}`;
  const base = n === 1 ? "x" : `x^{${n}}`;
  if (c === 1) return base;
  if (c === -1) return `-${base}`;
  return `${c}${base}`;
}

export const derivativeDrill: DrillDef = {
  slug: "derivative", title: "Derivatives",
  blurb: "Differentiate c·xⁿ with the power rule.",
  icon: "ƒ′", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const n = randInt(2, level === 1 ? 5 : level === 2 ? 7 : 9);
    const c = level === 1 ? randInt(1, 5) : randInt(2, 9);
    const correct = powTermTex(c * n, n - 1);
    const { options, correctIndex } = fourChoices(correct, [
      powTermTex(c, n),               // forgot to differentiate
      powTermTex(c * n, n),           // forgot to drop the power
      powTermTex(c, n - 1),           // forgot the coefficient factor
      powTermTex(c * (n - 1), n - 1),
    ]);
    return {
      id: pid("derivative"),
      prompt: { tex: `\\frac{d}{dx}\\left(${powTermTex(c, n)}\\right)` },
      input: { kind: "choice", options: options.map((t) => ({ tex: t })), correctIndex },
      explanation: { tex: `= ${correct}` },
    };
  },
};

export const integralDrill: DrillDef = {
  slug: "integral", title: "Integrals",
  blurb: "Integrate c·xⁿ with the power rule — don't forget + C.",
  icon: "∫", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const n = randInt(1, level === 1 ? 4 : level === 2 ? 6 : 8);
    const m = n + 1;
    const k = level === 1 ? randInt(1, 3) : randInt(1, 5);
    const c = k * m;
    const correct = `${powTermTex(k, m)} + C`;
    const { options, correctIndex } = fourChoices(correct, [
      `${powTermTex(c, m)} + C`,      // forgot to divide by the new power
      `${powTermTex(k, n)} + C`,      // didn't raise the power
      `${powTermTex(k, m + 1)} + C`,  // raised the power too far
      `${powTermTex(c, n)} + C`,
    ]);
    return {
      id: pid("integral"),
      prompt: { tex: `\\int ${powTermTex(c, n)}\\,dx` },
      input: { kind: "choice", options: options.map((t) => ({ tex: t })), correctIndex },
      explanation: { tex: `= ${correct}` },
    };
  },
};
