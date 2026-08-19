// The drill registry. Adding a new drill = write one generator file exporting a
// DrillDef, then add it to DRILLS here. Everything else (hub card, /drills/[slug]
// route, mode/level selection, grading, KaTeX, persistence) is driven by the def.

import type { DrillDef } from "./types";
import { arithmeticDrill } from "./generators/arithmetic";
import { unitCircleDrill } from "./generators/unit-circle";
import { vectorsDrill } from "./generators/vectors";
import {
  percentagesDrill, orderOfOpsDrill, powersOfTwoDrill, squaresDrill,
  gcdDrill, primesDrill, sequencesDrill, logarithmsDrill,
} from "./generators/mental-math";
import { derivativeDrill, integralDrill } from "./generators/calculus";
import {
  determinantDrill, solveSystemDrill, matrixVectorDrill, dotProductDrill,
} from "./generators/linear-algebra";
import {
  nameCountryDrill, nameStateDrill, locateCountryDrill, locateStateDrill,
  capitalCountryDrill, capitalStateDrill,
} from "./generators/geography";
import { grammarLessonDrills, grammarPracticeDrills } from "./grammar";

export const DRILLS: DrillDef[] = [
  arithmeticDrill, percentagesDrill, orderOfOpsDrill, powersOfTwoDrill, squaresDrill,
  gcdDrill, primesDrill, sequencesDrill, logarithmsDrill, derivativeDrill, integralDrill,
  determinantDrill, solveSystemDrill, matrixVectorDrill, dotProductDrill,
  unitCircleDrill, vectorsDrill,
  nameCountryDrill, nameStateDrill, locateCountryDrill, locateStateDrill,
  capitalCountryDrill, capitalStateDrill,
  ...grammarPracticeDrills,
  ...grammarLessonDrills,
];

export function drillBySlug(slug: string): DrillDef | undefined {
  return DRILLS.find((d) => d.slug === slug);
}
