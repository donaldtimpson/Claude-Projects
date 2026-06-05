// Real-data gamification engine. Computes each scholar's standing + achievements
// from the activity already stored (VideoProgress, QuizAttempt, course structure,
// account age) and merges in the static house scholars as pace-setters.
//
// All read-only and additive — nothing here writes. Awarding/persistence (writing
// to UserAchievement) lives in actions.ts.

import { db } from "@/lib/db";
import {
  BADGE_CATALOG,
  TIERS,
  SCORING,
  sumBadgePoints,
  badgesForScholar,
  MOCK_SCHOLARS,
  type Badge,
  type Scholar,
} from "@/lib/gamification/mock";

export type RankedScholar = Scholar & { userId?: string };

// Anyone who joined before this counts as a Founding Scholar (the Lyceum's first year).
const FOUNDING_CUTOFF = new Date("2027-06-01T00:00:00Z");
const PASS_RATIO = 0.7; // a course's playlist test must be ≥70% to count as "passed"

// ---- Deterministic fallback handle (until a student picks their own) --------

const HANDLE_ADJECTIVES = [
  "Quiet", "Curious", "Wandering", "Diligent", "Restless", "Humble",
  "Bold", "Patient", "Keen", "Eager", "Steady", "Bright",
];
const HANDLE_NOUNS = [
  "Peripatetic", "Stoic", "Geometer", "Scribe", "Aspirant", "Logician",
  "Empiricist", "Dialectician", "Naturalist", "Cartographer", "Disciple", "Pupil",
];

function hash(s: string): number {
  let h = 5381;
  for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) >>> 0;
  return h;
}

export function generateHandle(userId: string): string {
  const h = hash(userId);
  const adj = HANDLE_ADJECTIVES[h % HANDLE_ADJECTIVES.length];
  // Unsigned shift — a signed `>>` can go negative and produce an undefined index.
  const noun = HANDLE_NOUNS[(h >>> 8) % HANDLE_NOUNS.length];
  return `${adj}${noun}`;
}

// ---- Global course structure (same for every scholar; fetched once) ---------

type Structure = {
  courses: { id: string; videoIds: string[]; categoryIds: string[] }[];
  allVideoIds: string[];
  videosWithQuiz: Set<string>;
  coursesWithTest: Set<string>;
  totalCategories: number;
  categoryCourses: Map<string, string[]>;
};

async function fetchStructure(): Promise<Structure> {
  const [courses, quizQs, totalCategories] = await Promise.all([
    db.course.findMany({
      select: {
        id: true,
        videos: { select: { id: true } },
        categories: { select: { categoryId: true } },
      },
    }),
    db.quizQuestion.findMany({ where: { isDraft: false }, select: { videoId: true, courseId: true } }),
    db.category.count(),
  ]);

  const videosWithQuiz = new Set<string>();
  const coursesWithTest = new Set<string>();
  for (const q of quizQs) {
    if (q.videoId) videosWithQuiz.add(q.videoId);
    if (q.courseId) coursesWithTest.add(q.courseId);
  }

  const categoryCourses = new Map<string, string[]>();
  const courseInfo = courses.map((c) => {
    const categoryIds = c.categories.map((cc) => cc.categoryId);
    for (const cat of categoryIds) {
      categoryCourses.set(cat, [...(categoryCourses.get(cat) ?? []), c.id]);
    }
    return { id: c.id, videoIds: c.videos.map((v) => v.id), categoryIds };
  });

  return {
    courses: courseInfo,
    allVideoIds: courseInfo.flatMap((c) => c.videoIds),
    videosWithQuiz,
    coursesWithTest,
    totalCategories,
    categoryCourses,
  };
}

// ---- Per-user activity ------------------------------------------------------

type ProgressRow = { videoId: string; watchedAt: Date };
type AttemptRow = { videoId: string | null; courseId: string | null; score: number; totalQuestions: number; completedAt: Date };

function longestDayStreak(dates: Date[]): number {
  if (dates.length === 0) return 0;
  const days = [...new Set(dates.map((d) => Math.floor(d.getTime() / 86_400_000)))].sort((a, b) => a - b);
  let best = 1;
  let run = 1;
  for (let i = 1; i < days.length; i++) {
    run = days[i] === days[i - 1] + 1 ? run + 1 : 1;
    best = Math.max(best, run);
  }
  return best;
}

function longestWeekRun(dates: Date[]): number {
  if (dates.length === 0) return 0;
  const weeks = [...new Set(dates.map((d) => Math.floor(d.getTime() / (7 * 86_400_000))))].sort((a, b) => a - b);
  let best = 1;
  let run = 1;
  for (let i = 1; i < weeks.length; i++) {
    run = weeks[i] === weeks[i - 1] + 1 ? run + 1 : 1;
    best = Math.max(best, run);
  }
  return best;
}

// Evaluate one scholar from their activity. Returns the points breakdown,
// the unlocked badge keys, and the full Badge[] (catalog with unlocked flags).
function evaluate(
  progress: ProgressRow[],
  attempts: AttemptRow[],
  grantedKeys: Set<string>,
  createdAt: Date,
  structure: Structure,
): { breakdown: { lectures: number; quizPts: number; completions: number; badgePts: number }; badges: Badge[]; unlocked: Set<string> } {
  const watched = new Set(progress.map((p) => p.videoId));
  const lecturesWatched = watched.size;

  // Best-of per quiz / test (no cheat pressure), plus perfect tracking.
  const bestVideo = new Map<string, { score: number; total: number }>();
  const bestCourse = new Map<string, { score: number; total: number }>();
  const perfectVideos = new Set<string>();
  const perfectCourses = new Set<string>();
  let anyPerfect = false;
  let test90 = false;
  let perfectTest = false;

  for (const a of attempts) {
    const perfect = a.totalQuestions > 0 && a.score === a.totalQuestions;
    if (perfect) anyPerfect = true;
    if (a.videoId) {
      const prevV = bestVideo.get(a.videoId);
      if (!prevV || a.score > prevV.score) bestVideo.set(a.videoId, { score: a.score, total: a.totalQuestions });
      if (perfect) perfectVideos.add(a.videoId);
    }
    if (a.courseId) {
      const prev = bestCourse.get(a.courseId);
      if (!prev || a.score > prev.score) bestCourse.set(a.courseId, { score: a.score, total: a.totalQuestions });
      if (a.totalQuestions > 0 && a.score / a.totalQuestions >= 0.9) test90 = true;
      if (perfect) {
        perfectTest = true;
        perfectCourses.add(a.courseId);
      }
    }
  }

  // Longest run of consecutive perfect attempts (attempts arrive completedAt-asc).
  let perfectRun = 0;
  let bestPerfectRun = 0;
  for (const a of attempts) {
    if (a.totalQuestions > 0 && a.score === a.totalQuestions) {
      perfectRun += 1;
      bestPerfectRun = Math.max(bestPerfectRun, perfectRun);
    } else {
      perfectRun = 0;
    }
  }

  const videoCorrect = [...bestVideo.values()].reduce((s, v) => s + v.score, 0);
  const testCorrect = [...bestCourse.values()].reduce((s, v) => s + v.score, 0);

  // Completion + breadth.
  const completedCourses = new Set<string>();
  let halfCourse = false;
  let courseAllPerfect = false;
  const subjects = new Set<string>();

  for (const c of structure.courses) {
    if (c.videoIds.length === 0) continue;
    const watchedCount = c.videoIds.filter((v) => watched.has(v)).length;
    if (watchedCount > 0) for (const cat of c.categoryIds) subjects.add(cat);
    if (watchedCount >= Math.ceil(c.videoIds.length / 2)) halfCourse = true;

    const allWatched = watchedCount === c.videoIds.length;
    const hasTest = structure.coursesWithTest.has(c.id);
    const best = bestCourse.get(c.id);
    const testPassed = !hasTest || (!!best && best.total > 0 && best.score / best.total >= PASS_RATIO);

    // Completion requires PASSING every quiz too — not just clicking "watched".
    const quizVideos = c.videoIds.filter((v) => structure.videosWithQuiz.has(v));
    const quizzesPassed = quizVideos.every((v) => {
      const b = bestVideo.get(v);
      return !!b && b.total > 0 && b.score / b.total >= PASS_RATIO;
    });
    if (allWatched && quizzesPassed && testPassed) completedCourses.add(c.id);

    // Perfect on every quiz (and test, if any) in the course.
    if (
      quizVideos.length > 0 &&
      quizVideos.every((v) => perfectVideos.has(v)) &&
      (!hasTest || perfectCourses.has(c.id))
    ) {
      courseAllPerfect = true;
    }
  }

  const subjectComplete = [...structure.categoryCourses.values()].some(
    (courseIds) => courseIds.length > 0 && courseIds.every((id) => completedCourses.has(id)),
  );

  // Streaks + time-of-day.
  const stamps = [...progress.map((p) => p.watchedAt), ...attempts.map((a) => a.completedAt)];
  const dayStreak = longestDayStreak(stamps);
  const weekRun = longestWeekRun(stamps);
  const hours = stamps.map((d) => d.getUTCHours());
  const nightOwl = hours.some((h) => h >= 0 && h < 5);
  const earlyBird = hours.some((h) => h >= 5 && h < 7);

  const quizzesCompleted = bestVideo.size;

  // Omniscient: everything watched, every quiz + test taken and perfect.
  const omniscient =
    structure.allVideoIds.length > 0 &&
    structure.allVideoIds.every((v) => watched.has(v)) &&
    [...structure.videosWithQuiz].every((v) => perfectVideos.has(v)) &&
    [...structure.coursesWithTest].every((c) => perfectCourses.has(c));

  const rules: Record<string, boolean> = {
    "first-lecture": lecturesWatched >= 1,
    "first-quiz": quizzesCompleted >= 1,
    "lectures-25": lecturesWatched >= 25,
    "quizzes-25": quizzesCompleted >= 25,
    "lectures-100": lecturesWatched >= 100,
    "lectures-250": lecturesWatched >= 250,
    "first-perfect": anyPerfect,
    "test-90": test90,
    "perfect-streak-3": bestPerfectRun >= 3,
    "perfect-test": perfectTest,
    "course-all-perfect": courseAllPerfect,
    "half-course": halfCourse,
    "first-course": completedCourses.size >= 1,
    "three-courses": completedCourses.size >= 3,
    "subject-complete": subjectComplete,
    "streak-2": dayStreak >= 2,
    "streak-7": dayStreak >= 7,
    "weekly-month": weekRun >= 4,
    "streak-30": dayStreak >= 30,
    "streak-100": dayStreak >= 100,
    "subjects-2": subjects.size >= 2,
    "subjects-3": subjects.size >= 3,
    "subjects-5": subjects.size >= 5,
    "subjects-all": structure.totalCategories > 0 && subjects.size >= structure.totalCategories,
    "night-owl": nightOwl,
    "early-bird": earlyBird,
    // Early *participation*, not just an account: joined in the first year AND has engaged.
    "founding-scholar": createdAt < FOUNDING_CUTOFF && (lecturesWatched > 0 || attempts.length > 0),
    omniscient,
  };

  const unlocked = new Set<string>(grantedKeys);
  for (const [key, ok] of Object.entries(rules)) if (ok) unlocked.add(key);

  const badges: Badge[] = BADGE_CATALOG.map((b) => ({ ...b, unlocked: unlocked.has(b.key) }));
  const badgePts = sumBadgePoints(badges);

  return {
    breakdown: {
      lectures: lecturesWatched * SCORING.lecture,
      quizPts: videoCorrect * SCORING.quizPerCorrect + testCorrect * SCORING.testPerCorrect,
      completions: completedCourses.size * SCORING.completion,
      badgePts,
    },
    badges,
    unlocked,
  };
}

// ---- Public accessors -------------------------------------------------------

export type ScholarEntry = {
  scholar: RankedScholar;
  badges: Badge[];
  house: boolean;
  note?: string;
};

// Build every entry (real users with activity + house scholars), badges included, sorted.
async function buildAll(): Promise<ScholarEntry[]> {
  const [users, allProgress, allAttempts, allGranted, structure] = await Promise.all([
    db.user.findMany({ select: { id: true, handle: true, createdAt: true } }),
    db.videoProgress.findMany({ select: { userId: true, videoId: true, watchedAt: true } }),
    db.quizAttempt.findMany({
      select: { userId: true, videoId: true, courseId: true, score: true, totalQuestions: true, completedAt: true },
      orderBy: { completedAt: "asc" },
    }),
    db.userAchievement.findMany({ select: { userId: true, key: true } }),
    fetchStructure(),
  ]);

  const progressByUser = new Map<string, ProgressRow[]>();
  for (const p of allProgress) progressByUser.set(p.userId, [...(progressByUser.get(p.userId) ?? []), p]);
  const attemptsByUser = new Map<string, AttemptRow[]>();
  for (const a of allAttempts) attemptsByUser.set(a.userId, [...(attemptsByUser.get(a.userId) ?? []), a]);
  const grantedByUser = new Map<string, Set<string>>();
  for (const g of allGranted) grantedByUser.set(g.userId, (grantedByUser.get(g.userId) ?? new Set()).add(g.key));

  const real: ScholarEntry[] = [];
  for (const u of users) {
    const progress = progressByUser.get(u.id) ?? [];
    const attempts = attemptsByUser.get(u.id) ?? [];
    const granted = grantedByUser.get(u.id) ?? new Set<string>();
    // Show everyone — even brand-new accounts with 0 standing (they sort to the bottom).

    const { breakdown, badges } = evaluate(progress, attempts, granted, u.createdAt, structure);
    real.push({
      scholar: {
        userId: u.id,
        handle: u.handle ?? generateHandle(u.id),
        lectures: breakdown.lectures,
        quizPts: breakdown.quizPts,
        completions: breakdown.completions,
        badgePts: breakdown.badgePts,
        standing: breakdown.lectures + breakdown.quizPts + breakdown.completions + breakdown.badgePts,
        house: false,
      },
      badges,
      house: false,
    });
  }

  // House scholars (static pace-setters) keep their derived badge sets.
  const house: ScholarEntry[] = MOCK_SCHOLARS.filter((s) => s.house).map((s) => ({
    scholar: { ...s },
    badges: badgesForScholar(s),
    house: true,
    note: s.note,
  }));

  return [...real, ...house].sort((a, b) => b.scholar.standing - a.scholar.standing);
}

export async function getLeaderboard(): Promise<ScholarEntry[]> {
  return buildAll();
}

export async function getScholarByHandle(
  handle: string,
): Promise<(ScholarEntry & { rank: number; total: number }) | null> {
  const all = await buildAll();
  const target = handle.toLowerCase();
  const idx = all.findIndex((e) => e.scholar.handle.toLowerCase() === target);
  if (idx === -1) return null;
  return { ...all[idx], rank: idx + 1, total: all.length };
}

// A user's full badge set (rule-earned ∪ instructor-granted) for their own
// dashboard. Read-only — no persistence.
export async function getUserBadges(userId: string): Promise<Badge[]> {
  const [structure, progress, attempts, user, granted] = await Promise.all([
    fetchStructure(),
    db.videoProgress.findMany({ where: { userId }, select: { videoId: true, watchedAt: true } }),
    db.quizAttempt.findMany({
      where: { userId },
      select: { videoId: true, courseId: true, score: true, totalQuestions: true, completedAt: true },
      orderBy: { completedAt: "asc" },
    }),
    db.user.findUnique({ where: { id: userId }, select: { createdAt: true } }),
    db.userAchievement.findMany({ where: { userId }, select: { key: true } }),
  ]);
  if (!user) return BADGE_CATALOG.map((b) => ({ ...b, unlocked: false }));
  const grantedKeys = new Set(granted.map((g) => g.key));
  return evaluate(progress, attempts, grantedKeys, user.createdAt, structure).badges;
}

// Evaluate a user's rule-based achievements, persist any newly-earned ones to
// UserAchievement, and return just the freshly-unlocked badges (for an "unlocked!"
// toast). Called from the mark-watched / save-quiz server actions. Idempotent —
// re-running awards nothing new.
export async function syncAchievements(userId: string): Promise<Badge[]> {
  const [structure, progress, attempts, user, existing] = await Promise.all([
    fetchStructure(),
    db.videoProgress.findMany({ where: { userId }, select: { videoId: true, watchedAt: true } }),
    db.quizAttempt.findMany({
      where: { userId },
      select: { videoId: true, courseId: true, score: true, totalQuestions: true, completedAt: true },
      orderBy: { completedAt: "asc" },
    }),
    db.user.findUnique({ where: { id: userId }, select: { createdAt: true } }),
    db.userAchievement.findMany({ where: { userId }, select: { key: true } }),
  ]);
  if (!user) return [];

  // Rule-based only (no granted union) — grants are awarded separately by admins.
  const { unlocked } = evaluate(progress, attempts, new Set(), user.createdAt, structure);
  const have = new Set(existing.map((e) => e.key));
  const fresh = [...unlocked].filter((k) => !have.has(k));
  if (fresh.length === 0) return [];

  await db.userAchievement.createMany({
    data: fresh.map((key) => ({ userId, key })),
    skipDuplicates: true,
  });

  const freshSet = new Set(fresh);
  return BADGE_CATALOG.filter((b) => freshSet.has(b.key)).map((b) => ({ ...b, unlocked: true }));
}
