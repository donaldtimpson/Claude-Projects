// Vector-decomposition drill: given magnitude r at a common angle θ, choose ONE
// component (vₓ or v_y). Multiple choice with EXACT values (radicals, never
// decimals) so it can be done without a calculator.
//
// Components are r·cosθ / r·sinθ where cos/sin are unit-circle values:
// {0, ±1/2, ±√2/2, ±√3/2, ±1}. Keeping the magnitude EVEN (r = 2k) makes every
// component a clean integer or integer·√2 / integer·√3 — e.g. 6 at 30° → vₓ = 3√3.

import type { DrillDef, Level, Problem, Renderable } from "../types";
import { pid, pick, sampleDistinct, shuffle } from "../rand";

// A unit-circle value token; scaled by the magnitude it yields a component.
type Trig = "0" | "1" | "-1" | "1/2" | "-1/2" | "√2/2" | "-√2/2" | "√3/2" | "-√3/2";

// An exact component value: coeff · √root  (root 1 ⇒ rational, no radical).
type Comp = { coeff: number; root: 1 | 2 | 3 };

// Scale a trig token by k (= r/2, an integer) into an exact component.
function scale(t: Trig, k: number): Comp {
  switch (t) {
    case "0": return { coeff: 0, root: 1 };
    case "1": return { coeff: 2 * k, root: 1 };
    case "-1": return { coeff: -2 * k, root: 1 };
    case "1/2": return { coeff: k, root: 1 };
    case "-1/2": return { coeff: -k, root: 1 };
    case "√2/2": return { coeff: k, root: 2 };
    case "-√2/2": return { coeff: -k, root: 2 };
    case "√3/2": return { coeff: k, root: 3 };
    case "-√3/2": return { coeff: -k, root: 3 };
  }
}

const compKey = (c: Comp) => (c.coeff === 0 ? "0" : `${c.coeff}_${c.root}`);

function compTex(c: Comp): string {
  if (c.coeff === 0) return "0";
  if (c.root === 1) return `${c.coeff}`;
  const r = c.root === 2 ? "\\sqrt{2}" : "\\sqrt{3}";
  if (c.coeff === 1) return r;
  if (c.coeff === -1) return `-${r}`;
  return `${c.coeff}${r}`;
}

type AngleRow = { deg: number; cos: Trig; sin: Trig };

// The 16 common angles (multiples of 30° and 45°) with exact cos/sin tokens.
const ANGLES: AngleRow[] = [
  { deg: 0, cos: "1", sin: "0" },
  { deg: 30, cos: "√3/2", sin: "1/2" },
  { deg: 45, cos: "√2/2", sin: "√2/2" },
  { deg: 60, cos: "1/2", sin: "√3/2" },
  { deg: 90, cos: "0", sin: "1" },
  { deg: 120, cos: "-1/2", sin: "√3/2" },
  { deg: 135, cos: "-√2/2", sin: "√2/2" },
  { deg: 150, cos: "-√3/2", sin: "1/2" },
  { deg: 180, cos: "-1", sin: "0" },
  { deg: 210, cos: "-√3/2", sin: "-1/2" },
  { deg: 225, cos: "-√2/2", sin: "-√2/2" },
  { deg: 240, cos: "-1/2", sin: "-√3/2" },
  { deg: 270, cos: "0", sin: "-1" },
  { deg: 300, cos: "1/2", sin: "-√3/2" },
  { deg: 315, cos: "√2/2", sin: "-√2/2" },
  { deg: 330, cos: "√3/2", sin: "-1/2" },
];

// Per level: even-magnitude range (via k = r/2) and how many angles are in play.
const LEVELS: Record<Level, { k: [number, number]; angleCount: number }> = {
  1: { k: [1, 5], angleCount: 5 }, // Quadrant I (0..90°), r ∈ 2..10
  2: { k: [1, 6], angleCount: 9 }, // first two quadrants (0..180°)
  3: { k: [2, 8], angleCount: ANGLES.length }, // full circle
};

const randInt = (lo: number, hi: number) => Math.floor(Math.random() * (hi - lo + 1)) + lo;

function generate(level: Level): Problem {
  const cfg = LEVELS[level];
  const k = randInt(cfg.k[0], cfg.k[1]);
  const r = 2 * k;
  const angle = pick(ANGLES.slice(0, cfg.angleCount));
  const axis = pick(["x", "y"] as const);
  const trig = axis === "x" ? angle.cos : angle.sin;
  const correct = scale(trig, k);

  // Plausible exact distractors: the values that components of THIS magnitude take.
  const pool: Comp[] = [
    { coeff: 0, root: 1 },
    { coeff: k, root: 1 }, { coeff: -k, root: 1 },
    { coeff: 2 * k, root: 1 }, { coeff: -2 * k, root: 1 },
    { coeff: k, root: 2 }, { coeff: -k, root: 2 },
    { coeff: k, root: 3 }, { coeff: -k, root: 3 },
  ];
  // Dedupe by key, then drop the correct value.
  const byKey = new Map<string, Comp>();
  for (const c of pool) byKey.set(compKey(c), c);
  byKey.delete(compKey(correct));
  const distractors = sampleDistinct([...byKey.values()], 3);

  const optionComps = shuffle([correct, ...distractors]);
  const options: Renderable[] = optionComps.map((c) => ({ tex: compTex(c) }));
  const correctIndex = optionComps.findIndex((c) => compKey(c) === compKey(correct));

  const compLabel = axis === "x" ? "v_x" : "v_y";
  const fnTex = axis === "x" ? "\\cos" : "\\sin";

  return {
    id: pid("vectors"),
    prompt: { tex: `|\\vec{v}| = ${r},\\ \\theta = ${angle.deg}^\\circ.\\quad ${compLabel} = ?` },
    input: { kind: "choice", options, correctIndex },
    explanation: {
      tex: `${compLabel} = ${r}\\,${fnTex}\\,${angle.deg}^\\circ = ${compTex(correct)}`,
    },
    diagram: { kind: "vector", magnitude: r, angleDeg: angle.deg, component: axis },
  };
}

export const vectorsDrill: DrillDef = {
  slug: "vectors",
  title: "Vector Components",
  blurb: "Find a vector's x or y component at common angles — exact values, no calculator.",
  icon: "➹",
  subject: "Physics",
  levels: [
    { value: 1, label: "Quadrant I (0–90°)" },
    { value: 2, label: "Half plane (0–180°)" },
    { value: 3, label: "Full circle" },
  ],
  generate,
};
