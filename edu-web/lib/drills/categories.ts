// Drill categories — the hub's top level, mirroring the iOS DrillsView categories
// (same titles, same icons, same order). The hub lists these seven rows; each pushes
// to /drills/c/<slug> for that category's drills, so the growing catalog (60+ drills)
// never renders as one wall.
//
// The two grammar categories derive their members from the bundled banks, so adding a
// lesson or practice drill to content/grammar/ shows up here with no edit.

import { grammarLessonDrills, grammarPracticeDrills } from "./grammar";

export type DrillCategory = {
  slug: string; // URL segment under /drills/c/
  title: string;
  icon: string;
  drillSlugs: string[];
};

export const CATEGORIES: DrillCategory[] = [
  {
    slug: "grammar-lessons",
    title: "Grammar Lessons",
    icon: "🎓",
    drillSlugs: grammarLessonDrills.map((d) => d.slug),
  },
  {
    slug: "mental-math",
    title: "Mental Math",
    icon: "🧮",
    drillSlugs: [
      "arithmetic", "percentages", "order-of-operations", "powers-of-two",
      "squares", "gcd", "primes", "sequences", "logarithms",
    ],
  },
  { slug: "trigonometry", title: "Trigonometry", icon: "📐", drillSlugs: ["unit-circle", "vectors"] },
  { slug: "calculus", title: "Calculus", icon: "∫", drillSlugs: ["derivative", "integral"] },
  {
    slug: "linear-algebra",
    title: "Linear Algebra",
    icon: "▦",
    drillSlugs: ["determinant", "solve-system", "matrix-vector", "dot-product"],
  },
  {
    slug: "geography",
    title: "Geography",
    icon: "🌍",
    drillSlugs: [
      "name-country", "name-state", "locate-country", "locate-state",
      "capital-country", "capital-state",
    ],
  },
  {
    slug: "grammar",
    title: "Grammar",
    icon: "✒️",
    drillSlugs: grammarPracticeDrills.map((d) => d.slug),
  },
];

/** The lesson-homework category's slugs — the ✦-aced track (used for the "N/19 aced" line). */
export const LESSON_CATEGORY_SLUG = "grammar-lessons";

export function categoryBySlug(slug: string): DrillCategory | undefined {
  return CATEGORIES.find((c) => c.slug === slug);
}

/** The category a drill belongs to, for search result context. */
export function categoryOfDrill(drillSlug: string): DrillCategory | undefined {
  return CATEGORIES.find((c) => c.drillSlugs.includes(drillSlug));
}
