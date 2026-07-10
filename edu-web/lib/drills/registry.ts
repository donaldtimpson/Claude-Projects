// The drill registry. Adding a new drill = write one generator file exporting a
// DrillDef, then add it to DRILLS here. Everything else (hub card, /drills/[slug]
// route, mode/level selection, grading, KaTeX, persistence) is driven by the def.

import type { DrillDef } from "./types";
import { arithmeticDrill } from "./generators/arithmetic";
import { unitCircleDrill } from "./generators/unit-circle";
import { vectorsDrill } from "./generators/vectors";

export const DRILLS: DrillDef[] = [arithmeticDrill, unitCircleDrill, vectorsDrill];

export function drillBySlug(slug: string): DrillDef | undefined {
  return DRILLS.find((d) => d.slug === slug);
}
