// Vector-decomposition drill: given magnitude r and angle θ (from +x axis), find
// the components vₓ = r·cosθ and v_y = r·sinθ. Two typed fields + an SVG diagram.

import type { DrillDef, Level, Problem } from "../types";
import { pid, pick, randInt } from "../rand";

// "Nice" angles keep the diagram readable. Levels widen the range of quadrants.
const ANGLES_DEG = [0, 30, 45, 60, 90, 120, 135, 150, 180, 210, 225, 240, 270, 300, 315, 330];

const LEVELS: Record<Level, { mag: [number, number]; angleCount: number }> = {
  1: { mag: [3, 10], angleCount: 5 }, // first quadrant (0..90°)
  2: { mag: [3, 15], angleCount: 9 }, // first two quadrants (0..180°)
  3: { mag: [5, 25], angleCount: ANGLES_DEG.length }, // full circle
};

const round2 = (n: number) => Math.round(n * 100) / 100;

function generate(level: Level): Problem {
  const cfg = LEVELS[level];
  const r = randInt(cfg.mag[0], cfg.mag[1]);
  const deg = pick(ANGLES_DEG.slice(0, cfg.angleCount));
  const rad = (deg * Math.PI) / 180;
  const vx = round2(r * Math.cos(rad));
  const vy = round2(r * Math.sin(rad));

  return {
    id: pid("vectors"),
    prompt: {
      tex: `\\vec{v} \\text{ has } |\\vec{v}| = ${r} \\text{ at } \\theta = ${deg}^\\circ. \\text{ Find its components (2 dp).}`,
    },
    input: {
      kind: "fields",
      fields: [
        { label: { tex: "v_x" }, answer: vx, tolerance: 0.01 },
        { label: { tex: "v_y" }, answer: vy, tolerance: 0.01 },
      ],
    },
    explanation: {
      tex: `v_x = ${r}\\cos ${deg}^\\circ = ${vx},\\quad v_y = ${r}\\sin ${deg}^\\circ = ${vy}`,
    },
    diagram: { kind: "vector", magnitude: r, angleDeg: deg },
  };
}

export const vectorsDrill: DrillDef = {
  slug: "vectors",
  title: "Vector Components",
  blurb: "Decompose a vector given its magnitude and direction into x and y parts.",
  icon: "➹",
  subject: "Physics",
  levels: [
    { value: 1, label: "Quadrant I (0–90°)" },
    { value: 2, label: "Half plane (0–180°)" },
    { value: 3, label: "Full circle" },
  ],
  generate,
};
