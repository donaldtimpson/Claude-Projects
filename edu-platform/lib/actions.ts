"use server";

import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { syncAchievements } from "@/lib/gamification/engine";
import { BADGE_CATALOG, type Badge } from "@/lib/gamification/mock";
import {
  recordQuizAnswersForSrs,
  applyReviewGrade,
  getDueCount,
  masteredCardCount,
} from "@/lib/srs";
import type { DrillSummary } from "@/lib/drills/types";

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
  // Auto-enroll each answered question into the student's spaced-repetition deck.
  await recordQuizAnswersForSrs(session.user.id, { videoId, courseId }, answers);
  return syncAchievements(session.user.id);
}

// Records a completed practice-drill session (/drills). Drills are procedurally
// generated and write no QuizAttempt, so — like the review badges — their badges
// are directly-granted UserAchievement rows (idempotent; engine treats any such row
// as unlocked, never revokes, so existing scoring is untouched). The stored
// DrillAttempt.completedAt also feeds the streak via getStreak. Returns the
// freshly-earned badges for the "unlocked!" toast. No-ops for signed-out users.
export async function recordDrillSession(s: DrillSummary): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  const userId = session.user.id;

  await db.drillAttempt.create({
    data: {
      userId,
      slug: s.slug,
      level: s.level,
      total: s.total,
      correct: s.correct,
      bestStreak: s.bestStreak,
      mode: s.mode,
      durationSec: s.durationSec,
    },
  });

  const keys = ["drill-first"];
  if (s.bestStreak >= 10) keys.push("drill-streak-10");
  // A flawless sprint: timed mode, every answer correct, with enough volume to mean it.
  if (s.mode === "timed" && s.total >= 10 && s.correct === s.total) keys.push("drill-flawless-timed");
  // Volume badge — count includes the row just inserted above.
  const sessionCount = await db.drillAttempt.count({ where: { userId } });
  if (sessionCount >= 25) keys.push("drill-sessions-25");

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

// Grade a single card in the cross-course daily review (/review). Persists the
// card's new Leitner box + due date immediately, so leaving mid-session keeps
// the progress already made.
export async function gradeReview(questionId: string, correct: boolean): Promise<void> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return;
  await applyReviewGrade(session.user.id, questionId, correct);
}

// Called when a daily-review session ends. Direct-grants the SRS badges (same
// idempotent pattern as recordReviewCleared — no engine rules, scoring untouched):
// Clean Slate when no cards remain due today, Spaced Master at 30 mastered cards.
export async function finishDailyReview(): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  const userId = session.user.id;

  const [dueRemaining, mastered] = await Promise.all([
    getDueCount(userId),
    masteredCardCount(userId),
  ]);
  const keys: string[] = [];
  if (dueRemaining === 0) keys.push("review-clean-slate");
  if (mastered >= 30) keys.push("review-mastery-30");
  if (keys.length === 0) return [];

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
