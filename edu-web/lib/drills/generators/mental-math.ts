// Mental-math drills ported to parity with the native app: percentages, order of
// operations, powers of two, squares & roots, GCD, prime-or-composite, sequences,
// and logarithms. Numeric (typed) or choice, rendered with KaTeX.

import type { DrillDef, Level, Problem } from "../types";
import { pid, pick, randInt, shuffle } from "../rand";

function gcd(a: number, b: number): number { return b === 0 ? a : gcd(b, a % b); }
function isPrime(n: number): boolean {
  if (n < 2) return false;
  if (n < 4) return true;
  if (n % 2 === 0) return false;
  for (let i = 3; i * i <= n; i += 2) if (n % i === 0) return false;
  return true;
}
const LEVELS = [
  { value: 1 as Level, label: "Easy" },
  { value: 2 as Level, label: "Standard" },
  { value: 3 as Level, label: "Hard" },
];

// Shuffle "bag": draw a whole range in random order before repeating.
const bags: Record<string, number[]> = {};
function draw(key: string, domain: () => number[]): number {
  if (!bags[key] || bags[key].length === 0) bags[key] = shuffle(domain());
  return bags[key].pop()!;
}

// Build 4 shuffled options (correct + 3 distinct distractors from a pool).
function fourChoices(correct: string, pool: string[]): { options: string[]; correctIndex: number } {
  const seen = new Set([correct]);
  const d: string[] = [];
  for (const x of shuffle(pool)) { if (!seen.has(x)) { seen.add(x); d.push(x); if (d.length === 3) break; } }
  let pad = 2;
  while (d.length < 3) { const f = `${pad}`; if (!seen.has(f)) { seen.add(f); d.push(f); } pad++; }
  const options = shuffle([correct, ...d]);
  return { options, correctIndex: options.indexOf(correct) };
}

export const percentagesDrill: DrillDef = {
  slug: "percentages", title: "Percentages",
  blurb: "Mental percents of a number — tips, discounts, and more.",
  icon: "％", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const ps = level === 1 ? [5, 10, 20, 25, 50] : level === 2 ? [5, 10, 15, 20, 25, 50] : [5, 15, 20, 25, 40, 60, 75];
    const p = pick(ps);
    const step = 100 / gcd(p, 100);
    const k = randInt(2, level === 1 ? 10 : level === 2 ? 16 : 25);
    const n = step * k, answer = (p * n) / 100;
    return { id: pid("percentages"), prompt: { tex: `${p}\\%\\ \\text{of}\\ ${n}` }, input: { kind: "numeric", answer }, explanation: { tex: `${p}\\%\\ \\text{of}\\ ${n} = ${answer}` } };
  },
};

export const orderOfOpsDrill: DrillDef = {
  slug: "order-of-operations", title: "Order of Operations",
  blurb: "Evaluate expressions with the right precedence (PEMDAS).",
  icon: "🔢", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const hi = level === 1 ? 9 : level === 2 ? 12 : 20;
    const a = randInt(2, hi), b = randInt(2, 9), c = randInt(2, hi);
    if (randInt(0, 1) === 0) {
      return { id: pid("ooo"), prompt: { tex: `${a} + ${b} \\times ${c}` }, input: { kind: "numeric", answer: a + b * c }, explanation: { tex: `${b}\\times${c}=${b * c},\\ +${a} = ${a + b * c}` } };
    }
    return { id: pid("ooo"), prompt: { tex: `${b} \\times ${c} + ${a}` }, input: { kind: "numeric", answer: b * c + a }, explanation: { tex: `${b}\\times${c}=${b * c},\\ +${a} = ${b * c + a}` } };
  },
};

export const powersOfTwoDrill: DrillDef = {
  slug: "powers-of-two", title: "Powers of Two",
  blurb: "Recall 2ⁿ — the numbers behind bytes, bits, and binary.",
  icon: "⚡️", subject: "Computer Science", levels: LEVELS,
  generate(level: Level): Problem {
    const maxK = level === 1 ? 8 : level === 2 ? 12 : 16;
    const k = draw(`pow2_${level}`, () => Array.from({ length: maxK - 1 }, (_, i) => i + 2));
    const answer = 2 ** k;
    return { id: pid("pow2"), prompt: { tex: `2^{${k}}` }, input: { kind: "numeric", answer }, explanation: { tex: `2^{${k}} = ${answer}` } };
  },
};

export const squaresDrill: DrillDef = {
  slug: "squares", title: "Squares & Roots",
  blurb: "Perfect squares and their roots, on sight.",
  icon: "▧", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const hi = level === 1 ? 12 : level === 2 ? 20 : 30;
    const n = draw(`sq_${level}`, () => Array.from({ length: hi - 1 }, (_, i) => i + 2));
    if (randInt(0, 1) === 0) {
      return { id: pid("sq"), prompt: { tex: `${n}^2` }, input: { kind: "numeric", answer: n * n }, explanation: { tex: `${n}^2 = ${n * n}` } };
    }
    return { id: pid("sq"), prompt: { tex: `\\sqrt{${n * n}}` }, input: { kind: "numeric", answer: n }, explanation: { tex: `\\sqrt{${n * n}} = ${n}` } };
  },
};

export const gcdDrill: DrillDef = {
  slug: "gcd", title: "Greatest Common Divisor",
  blurb: "Find the largest number that divides both.",
  icon: "∩", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const hi = level === 1 ? 20 : level === 2 ? 60 : 120;
    const a = randInt(2, hi), b = randInt(2, hi);
    return { id: pid("gcd"), prompt: { tex: `\\gcd(${a},\\ ${b})` }, input: { kind: "numeric", answer: gcd(a, b) }, explanation: { tex: `\\gcd(${a},\\ ${b}) = ${gcd(a, b)}` } };
  },
};

export const primesDrill: DrillDef = {
  slug: "primes", title: "Prime or Composite",
  blurb: "Snap-judge whether a number is prime.",
  icon: "🧩", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const hi = level === 1 ? 40 : level === 2 ? 80 : 150;
    const n = randInt(2, hi);
    const prime = isPrime(n);
    let why = "";
    if (!prime) { for (let f = 2; f * f <= n; f++) if (n % f === 0) { why = ` (${f}\\times${n / f})`; break; } }
    return {
      id: pid("primes"), prompt: { tex: `${n}` },
      input: { kind: "choice", options: ["Prime", "Composite"], correctIndex: prime ? 0 : 1 },
      explanation: { tex: `${n}\\ \\text{is ${prime ? "prime" : "composite"}}${why}` },
    };
  },
};

export const sequencesDrill: DrillDef = {
  slug: "sequences", title: "Next in Sequence",
  blurb: "Spot the pattern and give the next term.",
  icon: "🔗", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    if (randInt(0, 1) === 0) {
      const a = randInt(1, 9), d = randInt(2, level === 1 ? 5 : 9);
      const terms = [0, 1, 2, 3].map((i) => a + i * d);
      return { id: pid("seq"), prompt: { tex: `${terms.join(",\\ ")},\\ ?` }, input: { kind: "numeric", answer: a + 4 * d }, explanation: { tex: `\\text{arithmetic, }+${d}\\ \\to\\ ${a + 4 * d}` } };
    }
    const a = randInt(1, 4), r = randInt(2, level === 1 ? 3 : 4);
    const terms = [0, 1, 2, 3].map((i) => a * r ** i);
    return { id: pid("seq"), prompt: { tex: `${terms.join(",\\ ")},\\ ?` }, input: { kind: "numeric", answer: a * r ** 4 }, explanation: { tex: `\\text{geometric, }\\times${r}\\ \\to\\ ${a * r ** 4}` } };
  },
};

export const logarithmsDrill: DrillDef = {
  slug: "logarithms", title: "Logarithms",
  blurb: "Evaluate a logarithm — the exponent that gets you there.",
  icon: "㏒", subject: "Mathematics", levels: LEVELS,
  generate(level: Level): Problem {
    const bases = level === 1 ? [2] : level === 2 ? [2, 3] : [2, 3, 5, 10];
    const b = pick(bases);
    const maxK = b === 2 ? (level === 1 ? 8 : 12) : b === 3 ? 5 : 4;
    const k = draw(`log_${b}_${level}`, () => Array.from({ length: maxK }, (_, i) => i + 1));
    const value = b ** k;
    return { id: pid("log"), prompt: { tex: `\\log_{${b}}(${value})` }, input: { kind: "numeric", answer: k }, explanation: { tex: `${b}^{${k}} = ${value}` } };
  },
};

export { fourChoices };
