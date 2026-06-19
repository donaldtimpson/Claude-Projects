"use server";

import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { syncAchievements } from "@/lib/gamification/engine";
import { BADGE_CATALOG, type Badge } from "@/lib/gamification/mock";

export async function markVideoWatched(videoId: string): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  await db.videoProgress.upsert({
    where: { userId_videoId: { userId: session.user.id, videoId } },
    create: { userId: session.user.id, videoId },
    update: {},
  });
  return syncAchievements(session.user.id);
}

// Course Review (full-course drill) award path. Review sessions are ephemeral and
// write NO QuizAttempt — they can't feed the rule-based engine, so the two review
// badges live purely as directly-granted UserAchievement rows. The engine treats any
// such row as unlocked (grantedKeys ∪ rules) and syncAchievements never revokes, so
// this never touches existing scoring. `perfect` = no question was ever missed.
// courseId is bound by the page for future per-course review badges. Returns just the
// freshly-earned badges for the "unlocked!" toast (idempotent via skipDuplicates).
export async function recordReviewCleared(courseId: string, perfect: boolean): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  const userId = session.user.id;
  const keys = perfect ? ["course-reviewed", "course-review-perfect"] : ["course-reviewed"];
  const existing = await db.userAchievement.findMany({
    where: { userId, key: { in: keys } },
    select: { key: true },
  });
  const have = new Set(existing.map((e) => e.key));
  const fresh = keys.filter((k) => !have.has(k));
  if (fresh.length === 0) return [];
  await db.userAchievement.createMany({
    data: fresh.map((key) => ({ userId, key })),
    skipDuplicates: true,
  });
  return BADGE_CATALOG.filter((b) => fresh.includes(b.key)).map((b) => ({ ...b, unlocked: true }));
}

// videoId/courseId bound by the page via .bind(null, videoId, courseId)
export async function saveQuizAttempt(
  videoId: string | null,
  courseId: string | null,
  score: number,
  total: number,
  answers: (number | null)[],
): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  await db.quizAttempt.create({
    data: {
      userId: session.user.id,
      videoId,
      courseId,
      score,
      totalQuestions: total,
      answers,
    },
  });
  return syncAchievements(session.user.id);
}
