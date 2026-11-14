// A student's view of one class, shaped for the app's class screen: the grade and
// how it's calculated, each instructor-defined category's items, homework (open
// work first, graded problem sets after), and quiz/test bests. Mirrors the web
// class hub (app/(site)/dashboard/class/[sectionId]/page.tsx) and is built from the
// same gradebook and assignment helpers, so the two can't disagree.

import { db } from "@/lib/db";
import { getSectionGradebook, studentBreakdown, type BreakdownCategory } from "@/lib/gradebook";
import { getSectionAssignmentsFor, type StudentAssignment } from "@/lib/assignments-data";
import { sortLectures } from "@/lib/lectures";

export type ClassHub = {
  sectionId: string;
  sectionName: string;
  courseId: string;
  courseTitle: string;
  currentGrade: number | null;
  breakdown: BreakdownCategory[];
  customCategories: {
    id: string;
    name: string;
    items: { id: string; name: string; maxPoints: number; score: number | null }[];
  }[];
  /** Open work first, then graded problem sets (lesson drills always count as open). */
  assignments: StudentAssignment[];
  quizzes: { videoId: string; title: string; bestPct: number | null }[];
  courseTest: { bestPct: number | null } | null;
};

export async function getClassHubFor(sectionId: string, userId: string): Promise<ClassHub | null> {
  const hw = await getSectionAssignmentsFor(sectionId, userId); // null unless an active enrollee
  if (!hw) return null;
  const gb = await getSectionGradebook(sectionId);
  const row = gb?.students.find((s) => s.userId === userId);
  if (!gb || !row) return null;

  const graded = (a: StudentAssignment) => a.kind === "problemSet" && a.submission?.score != null;
  const assignments = [...hw.assignments].sort((x, y) => Number(graded(x)) - Number(graded(y)));

  const course = await db.course.findUnique({
    where: { id: hw.courseId },
    select: {
      manualOrder: true,
      videos: {
        select: {
          id: true,
          title: true,
          position: true,
          publishedAt: true,
          _count: { select: { quizQuestions: { where: { isDraft: false } } } },
        },
      },
    },
  });
  const quizVideos = sortLectures(course?.videos ?? [], course?.manualOrder ?? false).filter(
    (v) => v._count.quizQuestions > 0,
  );
  const attempts = await db.quizAttempt.findMany({
    where: {
      userId,
      OR: [{ videoId: { in: quizVideos.map((v) => v.id) } }, { courseId: hw.courseId, videoId: null }],
    },
    select: { videoId: true, courseId: true, score: true, totalQuestions: true },
  });
  const bestByVideo = new Map<string, number>();
  let bestTest: number | null = null;
  for (const a of attempts) {
    if (a.totalQuestions <= 0) continue;
    const p = (a.score / a.totalQuestions) * 100;
    if (a.videoId) bestByVideo.set(a.videoId, Math.max(bestByVideo.get(a.videoId) ?? 0, p));
    else if (a.courseId === hw.courseId) bestTest = Math.max(bestTest ?? 0, p);
  }

  return {
    sectionId,
    sectionName: hw.sectionName,
    courseId: hw.courseId,
    courseTitle: hw.courseTitle,
    currentGrade: row.currentGrade,
    breakdown: studentBreakdown(gb, row),
    customCategories: gb.customCategories
      .filter((c) => c.weight > 0 && c.items.length > 0)
      .map((c) => ({
        id: c.id,
        name: c.name,
        items: c.items.map((it) => ({ ...it, score: row.customScores[it.id] ?? null })),
      })),
    assignments,
    quizzes: quizVideos.map((v) => ({ videoId: v.id, title: v.title, bestPct: bestByVideo.get(v.id) ?? null })),
    courseTest: gb.hasTest && gb.config.weights.test > 0 ? { bestPct: bestTest } : null,
  };
}

export type RegisterResult =
  | { ok: true; sectionId: string; sectionName: string; courseId: string }
  | { ok: false; error: string };

/** Join a section by its code. Only sections on the currently-active course accept registration. */
export async function registerWithCode(userId: string, rawCode: string): Promise<RegisterResult> {
  const code = rawCode.trim().toUpperCase();
  if (!code) return { ok: false, error: "Enter a class code." };
  const section = await db.section.findUnique({
    where: { joinCode: code },
    include: { course: { select: { id: true, isCurrent: true } } },
  });
  if (!section) return { ok: false, error: "That class code isn't valid." };
  if (!section.course.isCurrent) return { ok: false, error: "Registration for that class is closed." };
  await db.enrollment.upsert({
    where: { sectionId_userId: { sectionId: section.id, userId } },
    create: { sectionId: section.id, userId },
    update: { status: "active" },
  });
  return { ok: true, sectionId: section.id, sectionName: section.name, courseId: section.course.id };
}
