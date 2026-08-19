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
  const byUser = await getAcedLessonSlugsForUsers([userId]);
  return [...(byUser.get(userId) ?? [])];
}

/**
 * Aced lesson slugs for many users at once — userId → set of aced slugs.
 * Used by the gradebook (credit aced lesson-assignments) and the completion view.
 * Pass `slugs` to restrict to a section's assigned lessons.
 */
export async function getAcedLessonSlugsForUsers(
  userIds: string[],
  slugs: string[] = LESSON_SLUGS,
): Promise<Map<string, Set<string>>> {
  const out = new Map<string, Set<string>>();
  if (userIds.length === 0 || slugs.length === 0) return out;
  const rows = await db.drillAttempt.findMany({
    where: {
      userId: { in: userIds },
      slug: { in: slugs },
      total: { gte: HOMEWORK_LENGTH },
      correct: { gte: HOMEWORK_LENGTH },
    },
    select: { userId: true, slug: true, correct: true, total: true },
  });
  for (const r of rows) {
    if (r.correct < r.total) continue;
    let s = out.get(r.userId);
    if (!s) {
      s = new Set();
      out.set(r.userId, s);
    }
    s.add(r.slug);
  }
  return out;
}
