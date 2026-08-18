// Server-derived "aced" state for the grammar lesson homework drills.
//
// A lesson is aced when the student has a flawless homework-length run of it. We
// DERIVE this from existing DrillAttempt rows (no dedicated pass table): finishing
// a lesson drill already records slug + correct + total, so an ace is simply
// `correct === total` for a run of at least the homework length. This unifies the
// ✦ across iOS and web off one server source of truth.

import { db } from "@/lib/db";
import { grammarLessonDrills } from "@/lib/drills/grammar";

export const LESSON_SLUGS = grammarLessonDrills.map((d) => d.slug);
export const HOMEWORK_LENGTH = 30;

/** Slugs of lessons the user has aced (flawless run of >= HOMEWORK_LENGTH). */
export async function getAcedLessonSlugs(userId: string): Promise<string[]> {
  const rows = await db.drillAttempt.findMany({
    where: {
      userId,
      slug: { in: LESSON_SLUGS },
      total: { gte: HOMEWORK_LENGTH },
      correct: { gte: HOMEWORK_LENGTH },
    },
    select: { slug: true, correct: true, total: true },
  });
  const aced = new Set<string>();
  for (const r of rows) if (r.correct >= r.total) aced.add(r.slug);
  return [...aced];
}
