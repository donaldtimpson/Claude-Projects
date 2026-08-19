import { db } from "@/lib/db";
import { getAcedLessonSlugsForUsers } from "@/lib/lessons";

// Gradebook aggregation for one class section. Combines already-recorded data
// (attendance from lecture watches; quizzes + final test as best-attempt) with
// homework submission scores and the instructor's manual midterm/final marks,
// then computes a weighted current grade per student. Best-of logic mirrors
// lib/gamification/engine.ts. Weights + exam maxes live in Section.gradeConfig.

export type GradeWeights = {
  attendance: number;
  quizzes: number;
  test: number;
  homework: number;
  midterm: number;
  final: number;
};

export const DEFAULT_WEIGHTS: GradeWeights = {
  attendance: 10,
  quizzes: 10,
  test: 5,
  homework: 25,
  midterm: 25,
  final: 25,
};

export type GradeConfig = { weights: GradeWeights; midtermMax: number; finalMax: number };
export const DEFAULT_CONFIG: GradeConfig = { weights: DEFAULT_WEIGHTS, midtermMax: 100, finalMax: 100 };

const num = (v: unknown, d: number) => (typeof v === "number" && isFinite(v) && v >= 0 ? v : d);

export function parseGradeConfig(raw: unknown): GradeConfig {
  if (raw && typeof raw === "object") {
    const r = raw as Record<string, unknown>;
    const w = (r.weights ?? {}) as Record<string, unknown>;
    return {
      weights: {
        attendance: num(w.attendance, DEFAULT_WEIGHTS.attendance),
        quizzes: num(w.quizzes, DEFAULT_WEIGHTS.quizzes),
        test: num(w.test, DEFAULT_WEIGHTS.test),
        homework: num(w.homework, DEFAULT_WEIGHTS.homework),
        midterm: num(w.midterm, DEFAULT_WEIGHTS.midterm),
        final: num(w.final, DEFAULT_WEIGHTS.final),
      },
      midtermMax: num(r.midtermMax, 100) || 100,
      finalMax: num(r.finalMax, 100) || 100,
    };
  }
  return DEFAULT_CONFIG;
}

// Weighted average over the categories that actually have data — a running grade,
// so a not-yet-taken final doesn't read as a zero.
function weightedGrade(cats: { pct: number | null; weight: number }[]): number | null {
  let sum = 0;
  let wsum = 0;
  for (const c of cats) {
    if (c.pct === null || c.weight <= 0) continue;
    sum += c.pct * c.weight;
    wsum += c.weight;
  }
  return wsum > 0 ? sum / wsum : null;
}

export type StudentRow = {
  userId: string;
  name: string | null;
  email: string;
  watchedCount: number;
  attendancePct: number | null; // effective (override if set, else watched/total)
  attendanceOverride: number | null; // raw override for the input default
  quizzesTaken: number;
  quizAvgPct: number | null;
  testPct: number | null;
  hwGradedCount: number;
  hwPct: number | null;
  midtermScore: number | null; // raw points
  finalScore: number | null; // raw points
  midtermPct: number | null;
  finalPct: number | null;
  currentGrade: number | null; // weighted over categories with data
};

export type SectionGradebook = {
  section: { id: string; name: string; course: { id: string; title: string; isCurrent: boolean } };
  totalLectures: number;
  totalQuizzes: number;
  hasTest: boolean;
  totalAssignments: number;
  config: GradeConfig;
  students: StudentRow[];
};

export async function getSectionGradebook(sectionId: string): Promise<SectionGradebook | null> {
  const section = await db.section.findUnique({
    where: { id: sectionId },
    include: {
      course: { select: { id: true, title: true, isCurrent: true } },
      enrollments: {
        where: { status: "active" },
        orderBy: { enrolledAt: "asc" },
        include: { user: { select: { id: true, name: true, email: true } } },
      },
    },
  });
  if (!section) return null;

  const courseId = section.course.id;
  const config = parseGradeConfig(section.gradeConfig);
  const userIds = section.enrollments.map((e) => e.user.id);

  const videos = await db.video.findMany({
    where: { courseId },
    select: { id: true, _count: { select: { quizQuestions: { where: { isDraft: false } } } } },
  });
  const videoIds = videos.map((v) => v.id);
  const quizVideoIds = new Set(videos.filter((v) => v._count.quizQuestions > 0).map((v) => v.id));
  const hasTest = (await db.quizQuestion.count({ where: { courseId, videoId: null, isDraft: false } })) > 0;

  const sectionAssignments = await db.assignment.findMany({
    where: { sectionId: section.id },
    select: { id: true, points: true, lessonSlug: true },
  });
  const pointsByAssignment = new Map(sectionAssignments.map((a) => [a.id, a.points]));

  const base = {
    section: { id: section.id, name: section.name, course: section.course },
    totalLectures: videos.length,
    totalQuizzes: quizVideoIds.size,
    hasTest,
    totalAssignments: sectionAssignments.length,
    config,
  };

  if (userIds.length === 0) return { ...base, students: [] };

  const [progress, attempts, submissions] = await Promise.all([
    db.videoProgress.findMany({
      where: { userId: { in: userIds }, videoId: { in: videoIds } },
      select: { userId: true },
    }),
    db.quizAttempt.findMany({
      where: {
        userId: { in: userIds },
        OR: [{ videoId: { in: [...quizVideoIds] } }, { courseId, videoId: null }],
      },
      select: { userId: true, videoId: true, courseId: true, score: true, totalQuestions: true },
    }),
    sectionAssignments.length > 0
      ? db.submission.findMany({
          where: {
            userId: { in: userIds },
            assignmentId: { in: sectionAssignments.map((a) => a.id) },
            score: { not: null },
          },
          select: { userId: true, assignmentId: true, score: true },
        })
      : Promise.resolve([] as { userId: string; assignmentId: string; score: number | null }[]),
  ]);

  const hwEarned = new Map<string, number>();
  const hwPossible = new Map<string, number>();
  const hwCount = new Map<string, number>();
  for (const s of submissions) {
    const pts = pointsByAssignment.get(s.assignmentId) ?? 0;
    hwEarned.set(s.userId, (hwEarned.get(s.userId) ?? 0) + (s.score ?? 0));
    hwPossible.set(s.userId, (hwPossible.get(s.userId) ?? 0) + pts);
    hwCount.set(s.userId, (hwCount.get(s.userId) ?? 0) + 1);
  }

  // Lesson-drill assignments are auto-graded and BINARY: acing the lesson (a
  // flawless 30-run, derived from DrillAttempt) earns full points; a not-yet-aced
  // lesson is simply uncounted — matching the "graded so far" running average used
  // for problem-set submissions above (no zeros for unfinished work, no due gate).
  const lessonAssignments = sectionAssignments.filter((a) => a.lessonSlug);
  if (lessonAssignments.length > 0) {
    const acedByUser = await getAcedLessonSlugsForUsers(
      userIds,
      lessonAssignments.map((a) => a.lessonSlug!),
    );
    for (const uid of userIds) {
      const aced = acedByUser.get(uid);
      if (!aced) continue;
      for (const a of lessonAssignments) {
        if (a.lessonSlug && aced.has(a.lessonSlug)) {
          hwEarned.set(uid, (hwEarned.get(uid) ?? 0) + a.points);
          hwPossible.set(uid, (hwPossible.get(uid) ?? 0) + a.points);
          hwCount.set(uid, (hwCount.get(uid) ?? 0) + 1);
        }
      }
    }
  }

  const watched = new Map<string, number>();
  for (const p of progress) watched.set(p.userId, (watched.get(p.userId) ?? 0) + 1);

  const bestQuiz = new Map<string, Map<string, number>>();
  const bestTest = new Map<string, number>();
  for (const a of attempts) {
    if (a.totalQuestions <= 0) continue;
    const pct = (a.score / a.totalQuestions) * 100;
    if (a.videoId && quizVideoIds.has(a.videoId)) {
      let m = bestQuiz.get(a.userId);
      if (!m) {
        m = new Map();
        bestQuiz.set(a.userId, m);
      }
      m.set(a.videoId, Math.max(m.get(a.videoId) ?? 0, pct));
    } else if (!a.videoId && a.courseId === courseId) {
      bestTest.set(a.userId, Math.max(bestTest.get(a.userId) ?? 0, pct));
    }
  }

  const { weights, midtermMax, finalMax } = config;

  const students: StudentRow[] = section.enrollments.map((e) => {
    const uid = e.user.id;
    const m = bestQuiz.get(uid);
    const quizzesTaken = m ? m.size : 0;
    const quizAvgPct = m && m.size > 0 ? [...m.values()].reduce((s, v) => s + v, 0) / m.size : null;

    const possible = hwPossible.get(uid) ?? 0;
    const hwPct = possible > 0 ? ((hwEarned.get(uid) ?? 0) / possible) * 100 : null;

    const watchedCount = watched.get(uid) ?? 0;
    const autoAttendance = base.totalLectures > 0 ? (watchedCount / base.totalLectures) * 100 : null;
    const attendancePct = e.attendanceOverride ?? autoAttendance;

    const midtermPct = e.midtermScore !== null ? (e.midtermScore / midtermMax) * 100 : null;
    const finalPct = e.finalScore !== null ? (e.finalScore / finalMax) * 100 : null;
    const testPct = bestTest.get(uid) ?? null;

    const currentGrade = weightedGrade([
      { pct: attendancePct, weight: weights.attendance },
      { pct: quizAvgPct, weight: weights.quizzes },
      { pct: testPct, weight: weights.test },
      { pct: hwPct, weight: weights.homework },
      { pct: midtermPct, weight: weights.midterm },
      { pct: finalPct, weight: weights.final },
    ]);

    return {
      userId: uid,
      name: e.user.name,
      email: e.user.email,
      watchedCount,
      attendancePct,
      attendanceOverride: e.attendanceOverride,
      quizzesTaken,
      quizAvgPct,
      testPct,
      hwGradedCount: hwCount.get(uid) ?? 0,
      hwPct,
      midtermScore: e.midtermScore,
      finalScore: e.finalScore,
      midtermPct,
      finalPct,
      currentGrade,
    };
  });

  return { ...base, students };
}
