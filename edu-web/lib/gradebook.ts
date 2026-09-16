import { db } from "@/lib/db";
import { getAcedLessonSlugsForUsers } from "@/lib/lessons";

// Gradebook aggregation for one class section. Combines instructor-marked
// attendance (per lecture), auto-tracked quizzes + final test (best attempt),
// homework scores (submission scores + lesson aces, hand-editable), and the
// instructor's midterm/final marks into a weighted running grade per student.
//
// Grading rule: a category counts only over items that have an entered value.
// For homework a blank cell is uncounted; an explicit 0 counts. No due dates —
// what counts is driven purely by the instructor entering values. Weights + exam
// maxes live in Section.gradeConfig.

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

export type AttendanceStatus = "present" | "absent" | "late" | "excused";
// Present/late earn full attendance credit; absent is a zero; excused (and
// unmarked) are excluded from the running attendance %.
const ATTENDANCE_CREDIT: Record<AttendanceStatus, number | null> = {
  present: 100,
  late: 100,
  absent: 0,
  excused: null,
};

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
// so a not-yet-entered category doesn't read as a zero.
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

export type HwCell = { score: number | null; hasUrl: boolean; submitted: boolean };

export type StudentRow = {
  userId: string;
  name: string | null;
  email: string;
  watchedCount: number; // lectures the student has watched (VideoProgress) — informational, not attendance
  attendanceByVideo: Record<string, AttendanceStatus>;
  attendancePct: number | null; // over marked lectures (present/late full, absent 0, excused/unmarked excluded)
  attendanceOverride: number | null; // legacy passthrough, no longer used in the calc
  quizByVideo: Record<string, number>; // best pct per taken quiz video
  quizzesTaken: number;
  quizAvgPct: number | null;
  testPct: number | null;
  hwByAssignment: Record<string, HwCell>; // effective score + submission state per assignment
  hwGradedCount: number;
  hwPct: number | null;
  midtermScore: number | null;
  finalScore: number | null;
  midtermPct: number | null;
  finalPct: number | null;
  customScores: Record<string, number | null>; // score per custom-category item id
  currentGrade: number | null;
};

export type GbLecture = { id: string; title: string };
export type GbQuiz = { videoId: string; title: string };
export type GbAssignment = {
  id: string;
  title: string;
  points: number;
  kind: "problemSet" | "lesson" | "paper";
  problemSetId: string | null;
  lessonSlug: string | null;
  solutionsPublic: boolean | null;
};

export type GbItem = { id: string; name: string; maxPoints: number };
export type GbCustomCategory = { id: string; name: string; weight: number; items: GbItem[] };

export type SectionGradebook = {
  section: { id: string; name: string; course: { id: string; title: string; isCurrent: boolean } };
  totalLectures: number;
  totalQuizzes: number;
  hasTest: boolean;
  totalAssignments: number;
  config: GradeConfig;
  lectures: GbLecture[];
  quizzes: GbQuiz[];
  assignments: GbAssignment[];
  customCategories: GbCustomCategory[];
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
    orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
    select: { id: true, title: true, _count: { select: { quizQuestions: { where: { isDraft: false } } } } },
  });
  const videoIds = videos.map((v) => v.id);
  const quizVideos = videos.filter((v) => v._count.quizQuestions > 0);
  const quizVideoIds = new Set(quizVideos.map((v) => v.id));
  const hasTest = (await db.quizQuestion.count({ where: { courseId, videoId: null, isDraft: false } })) > 0;

  const sectionAssignments = await db.assignment.findMany({
    where: { sectionId: section.id },
    orderBy: { createdAt: "asc" },
    include: { problemSet: { select: { title: true, solutionsPublic: true } } },
  });

  // Resolve display titles for lesson-drill assignments.
  const { grammarLessonDrills } = await import("@/lib/drills/grammar");
  const lessonTitle = new Map(grammarLessonDrills.map((d) => [d.slug, d.title]));

  const assignments: GbAssignment[] = sectionAssignments.map((a) => ({
    id: a.id,
    title:
      a.title ?? a.problemSet?.title ?? (a.lessonSlug ? lessonTitle.get(a.lessonSlug) ?? a.lessonSlug : "Assignment"),
    points: a.points,
    kind: a.lessonSlug ? "lesson" : a.problemSetId ? "problemSet" : "paper",
    problemSetId: a.problemSetId,
    lessonSlug: a.lessonSlug,
    solutionsPublic: a.problemSet?.solutionsPublic ?? null,
  }));
  // Order homework columns by title, numeric-aware (1.6 < 1.7 < 2.1 < 2.7 < 4.4).
  assignments.sort((a, b) => a.title.localeCompare(b.title, undefined, { numeric: true, sensitivity: "base" }));
  const pointsByAssignment = new Map(assignments.map((a) => [a.id, a.points]));

  // Instructor-defined custom categories (e.g. in-class Tests) with their items.
  const categories = await db.gradeCategory.findMany({
    where: { sectionId: section.id },
    orderBy: { position: "asc" },
    include: { items: { orderBy: { position: "asc" }, select: { id: true, name: true, maxPoints: true } } },
  });
  const customCategories: GbCustomCategory[] = categories.map((c) => ({
    id: c.id,
    name: c.name,
    weight: c.weight,
    items: c.items,
  }));

  const base = {
    section: { id: section.id, name: section.name, course: section.course },
    totalLectures: videos.length,
    totalQuizzes: quizVideoIds.size,
    hasTest,
    totalAssignments: sectionAssignments.length,
    config,
    lectures: videos.map((v) => ({ id: v.id, title: v.title })),
    quizzes: quizVideos.map((v) => ({ videoId: v.id, title: v.title })),
    assignments,
    customCategories,
  };

  if (userIds.length === 0) return { ...base, students: [] };

  const itemIds = categories.flatMap((c) => c.items.map((i) => i.id));

  const [progress, attempts, submissions, attendance, gradeScores] = await Promise.all([
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
          where: { userId: { in: userIds }, assignmentId: { in: sectionAssignments.map((a) => a.id) } },
          select: { userId: true, assignmentId: true, score: true, url: true },
        })
      : Promise.resolve([] as { userId: string; assignmentId: string; score: number | null; url: string | null }[]),
    db.attendance.findMany({
      where: { sectionId: section.id },
      select: { userId: true, videoId: true, status: true },
    }),
    itemIds.length > 0
      ? db.gradeScore.findMany({
          where: { itemId: { in: itemIds }, userId: { in: userIds } },
          select: { itemId: true, userId: true, score: true },
        })
      : Promise.resolve([] as { itemId: string; userId: string; score: number }[]),
  ]);

  // Custom-category scores keyed by user → item.
  const scoreByUser = new Map<string, Record<string, number>>();
  for (const gs of gradeScores) {
    let m = scoreByUser.get(gs.userId);
    if (!m) scoreByUser.set(gs.userId, (m = {}));
    m[gs.itemId] = gs.score;
  }

  // Submissions keyed by user → assignment.
  const subByUser = new Map<string, Map<string, { score: number | null; url: string | null }>>();
  for (const s of submissions) {
    let m = subByUser.get(s.userId);
    if (!m) subByUser.set(s.userId, (m = new Map()));
    m.set(s.assignmentId, { score: s.score, url: s.url });
  }

  // Lesson aces (auto full credit unless a manual score overrides).
  const lessonAssignments = sectionAssignments.filter((a) => a.lessonSlug);
  const acedByUser =
    lessonAssignments.length > 0
      ? await getAcedLessonSlugsForUsers(userIds, lessonAssignments.map((a) => a.lessonSlug!))
      : new Map<string, Set<string>>();

  // Attendance keyed by user → video.
  const attByUser = new Map<string, Record<string, AttendanceStatus>>();
  for (const a of attendance) {
    let m = attByUser.get(a.userId);
    if (!m) attByUser.set(a.userId, (m = {}));
    m[a.videoId] = a.status as AttendanceStatus;
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
      if (!m) bestQuiz.set(a.userId, (m = new Map()));
      m.set(a.videoId, Math.max(m.get(a.videoId) ?? 0, pct));
    } else if (!a.videoId && a.courseId === courseId) {
      bestTest.set(a.userId, Math.max(bestTest.get(a.userId) ?? 0, pct));
    }
  }

  const { weights, midtermMax, finalMax } = config;

  const students: StudentRow[] = section.enrollments.map((e) => {
    const uid = e.user.id;

    // Attendance over marked lectures.
    const attMap = attByUser.get(uid) ?? {};
    let attCredit = 0;
    let attCounted = 0;
    for (const status of Object.values(attMap)) {
      const credit = ATTENDANCE_CREDIT[status];
      if (credit === null) continue;
      attCredit += credit;
      attCounted += 1;
    }
    const attendancePct = attCounted > 0 ? attCredit / attCounted : null;

    // Quizzes.
    const qm = bestQuiz.get(uid);
    const quizByVideo: Record<string, number> = {};
    if (qm) for (const [vid, pct] of qm) quizByVideo[vid] = pct;
    const quizzesTaken = qm ? qm.size : 0;
    const quizAvgPct = qm && qm.size > 0 ? [...qm.values()].reduce((s, v) => s + v, 0) / qm.size : null;

    // Homework: effective score per assignment = manual submission score, else
    // lesson ace (full points), else blank (uncounted). 0 counts.
    const subs = subByUser.get(uid);
    const aced = acedByUser.get(uid);
    const hwByAssignment: Record<string, HwCell> = {};
    let hwEarned = 0;
    let hwPossible = 0;
    let hwGradedCount = 0;
    for (const a of assignments) {
      const sub = subs?.get(a.id);
      const acedHere = a.lessonSlug ? aced?.has(a.lessonSlug) ?? false : false;
      const effective = sub && sub.score !== null ? sub.score : acedHere ? a.points : null;
      hwByAssignment[a.id] = { score: effective, hasUrl: Boolean(sub?.url), submitted: Boolean(sub) };
      if (effective !== null) {
        hwEarned += effective;
        hwPossible += a.points;
        hwGradedCount += 1;
      }
    }
    const hwPct = hwPossible > 0 ? (hwEarned / hwPossible) * 100 : null;

    const midtermPct = e.midtermScore !== null ? (e.midtermScore / midtermMax) * 100 : null;
    const finalPct = e.finalScore !== null ? (e.finalScore / finalMax) * 100 : null;
    const testPct = bestTest.get(uid) ?? null;

    // Custom categories: each is earned/possible over its entered items, weighted.
    const userScores = scoreByUser.get(uid) ?? {};
    const customScores: Record<string, number | null> = {};
    const customCats: { pct: number | null; weight: number }[] = [];
    for (const c of categories) {
      let cEarned = 0;
      let cPossible = 0;
      for (const it of c.items) {
        const sc = userScores[it.id];
        customScores[it.id] = sc ?? null;
        if (sc !== undefined) {
          cEarned += sc;
          cPossible += it.maxPoints;
        }
      }
      customCats.push({ pct: cPossible > 0 ? (cEarned / cPossible) * 100 : null, weight: c.weight });
    }

    const currentGrade = weightedGrade([
      { pct: attendancePct, weight: weights.attendance },
      { pct: quizAvgPct, weight: weights.quizzes },
      { pct: testPct, weight: weights.test },
      { pct: hwPct, weight: weights.homework },
      { pct: midtermPct, weight: weights.midterm },
      { pct: finalPct, weight: weights.final },
      ...customCats,
    ]);

    return {
      userId: uid,
      name: e.user.name,
      email: e.user.email,
      watchedCount: watched.get(uid) ?? 0,
      attendanceByVideo: attMap,
      attendancePct,
      attendanceOverride: e.attendanceOverride,
      quizByVideo,
      quizzesTaken,
      quizAvgPct,
      testPct,
      hwByAssignment,
      hwGradedCount,
      hwPct,
      midtermScore: e.midtermScore,
      finalScore: e.finalScore,
      midtermPct,
      finalPct,
      customScores,
      currentGrade,
    };
  });

  return { ...base, students };
}
