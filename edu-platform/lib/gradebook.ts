import { db } from "@/lib/db";

// Read-only gradebook aggregation for one class section. Surfaces the three
// already-recorded categories per enrolled student: attendance (lecture watches),
// quizzes (best attempt per video quiz), and the final course test (best attempt).
// Homework + manual exam columns arrive in later phases. Best-of logic mirrors
// lib/gamification/engine.ts (max score per quiz, no cheat pressure), batched
// across the whole roster.

export type StudentRow = {
  userId: string;
  name: string | null;
  email: string;
  watchedCount: number;
  quizzesTaken: number;
  quizAvgPct: number | null; // average of best % across quizzes the student attempted
  testPct: number | null; // best course-test %
  hwGradedCount: number; // # assignments graded for this student
  hwPct: number | null; // points-weighted % across graded assignments
};

export type SectionGradebook = {
  section: { id: string; name: string; course: { id: string; title: string; isCurrent: boolean } };
  totalLectures: number;
  totalQuizzes: number; // # videos with a published quiz
  hasTest: boolean;
  totalAssignments: number;
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
  const userIds = section.enrollments.map((e) => e.user.id);

  // Course videos + which of them have a published quiz.
  const videos = await db.video.findMany({
    where: { courseId },
    select: { id: true, _count: { select: { quizQuestions: { where: { isDraft: false } } } } },
  });
  const videoIds = videos.map((v) => v.id);
  const quizVideoIds = new Set(videos.filter((v) => v._count.quizQuestions > 0).map((v) => v.id));
  const hasTest = (await db.quizQuestion.count({ where: { courseId, videoId: null, isDraft: false } })) > 0;

  // Assignments belong to the section (not the course) — count them for the header
  // regardless of roster size.
  const sectionAssignments = await db.assignment.findMany({
    where: { sectionId: section.id },
    select: { id: true, points: true },
  });
  const pointsByAssignment = new Map(sectionAssignments.map((a) => [a.id, a.points]));

  const base = {
    section: { id: section.id, name: section.name, course: section.course },
    totalLectures: videos.length,
    totalQuizzes: quizVideoIds.size,
    hasTest,
    totalAssignments: sectionAssignments.length,
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

  // Homework: points-weighted % across the student's GRADED assignments.
  const hwEarned = new Map<string, number>();
  const hwPossible = new Map<string, number>();
  const hwCount = new Map<string, number>();
  for (const s of submissions) {
    const pts = pointsByAssignment.get(s.assignmentId) ?? 0;
    hwEarned.set(s.userId, (hwEarned.get(s.userId) ?? 0) + (s.score ?? 0));
    hwPossible.set(s.userId, (hwPossible.get(s.userId) ?? 0) + pts);
    hwCount.set(s.userId, (hwCount.get(s.userId) ?? 0) + 1);
  }

  // Attendance: count of watched course-lectures per user.
  const watched = new Map<string, number>();
  for (const p of progress) watched.set(p.userId, (watched.get(p.userId) ?? 0) + 1);

  // Best % per (user, video quiz) and best course-test % per user.
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

  const students: StudentRow[] = section.enrollments.map((e) => {
    const m = bestQuiz.get(e.user.id);
    const quizzesTaken = m ? m.size : 0;
    const quizAvgPct =
      m && m.size > 0 ? [...m.values()].reduce((s, v) => s + v, 0) / m.size : null;
    const possible = hwPossible.get(e.user.id) ?? 0;
    const hwPct = possible > 0 ? ((hwEarned.get(e.user.id) ?? 0) / possible) * 100 : null;
    return {
      userId: e.user.id,
      name: e.user.name,
      email: e.user.email,
      watchedCount: watched.get(e.user.id) ?? 0,
      quizzesTaken,
      quizAvgPct,
      testPct: bestTest.get(e.user.id) ?? null,
      hwGradedCount: hwCount.get(e.user.id) ?? 0,
      hwPct,
    };
  });

  return { ...base, students };
}
