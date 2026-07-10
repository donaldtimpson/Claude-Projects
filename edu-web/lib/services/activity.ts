// Activity services: the userId-parameterized business logic behind the student
// engagement writes (watch progress, quiz attempts, course review, drills, daily
// review). Extracted from lib/actions.ts so BOTH transports share one
// implementation:
//   - web  -> the "use server" wrappers in lib/actions.ts (getServerSession)
//   - mobile -> app/api/mobile/v1/* handlers (requireMobileUser Bearer token)
// Keep these pure of any session/cookie access — the caller supplies userId.

import { db } from "@/lib/db";
import { syncAchievements } from "@/lib/gamification/engine";
import { BADGE_CATALOG, type Badge } from "@/lib/gamification/mock";
import { recordQuizAnswersForSrs, getDueCount, masteredCardCount } from "@/lib/srs";
import type { DrillSummary } from "@/lib/drills";

// Grant the given badge keys the student doesn't already hold, idempotently, and
// return the freshly-earned ones (as unlocked Badges) for the "unlocked!" toast.
// Shared shape used by the direct-grant award paths (review, drills).
async function grantFreshBadges(userId: string, keys: string[]): Promise<Badge[]> {
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

export async function markVideoWatchedFor(userId: string, videoId: string): Promise<Badge[]> {
  await db.videoProgress.upsert({
    where: { userId_videoId: { userId, videoId } },
    create: { userId, videoId },
    update: {},
  });
  return syncAchievements(userId);
}

// Course Review (full-course drill) award path. Review sessions are ephemeral and
// write NO QuizAttempt — the two review badges live purely as directly-granted
// UserAchievement rows (engine treats any such row as unlocked, never revokes, so
// existing scoring is untouched). `perfect` = no question was ever missed.
export async function recordReviewClearedFor(
  userId: string,
  courseId: string,
  perfect: boolean,
): Promise<Badge[]> {
  void courseId; // bound for future per-course review badges
  const keys = perfect ? ["course-reviewed", "course-review-perfect"] : ["course-reviewed"];
  return grantFreshBadges(userId, keys);
}

export async function recordQuizAttemptFor(
  userId: string,
  input: {
    videoId: string | null;
    courseId: string | null;
    score: number;
    total: number;
    answers: (number | null)[];
  },
): Promise<Badge[]> {
  const { videoId, courseId, score, total, answers } = input;
  await db.quizAttempt.create({
    data: { userId, videoId, courseId, score, totalQuestions: total, answers },
  });
  // Auto-enroll each answered question into the student's spaced-repetition deck.
  await recordQuizAnswersForSrs(userId, { videoId, courseId }, answers);
  return syncAchievements(userId);
}

// Records a completed practice-drill session (/drills). Drills are procedurally
// generated and write no QuizAttempt, so — like the review badges — their badges
// are directly-granted UserAchievement rows. The stored DrillAttempt.completedAt
// also feeds the streak via getStreak.
export async function recordDrillSessionFor(userId: string, s: DrillSummary): Promise<Badge[]> {
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

  return grantFreshBadges(userId, keys);
}

// Called when a daily-review session ends. Direct-grants the SRS badges: Clean
// Slate when no cards remain due today, Spaced Master at 30 mastered cards.
export async function finishDailyReviewFor(userId: string): Promise<Badge[]> {
  const [dueRemaining, mastered] = await Promise.all([
    getDueCount(userId),
    masteredCardCount(userId),
  ]);
  const keys: string[] = [];
  if (dueRemaining === 0) keys.push("review-clean-slate");
  if (mastered >= 30) keys.push("review-mastery-30");
  return grantFreshBadges(userId, keys);
}
