// Shared homework read/write logic used by BOTH the web class hub / submit action
// (lib/assignments.ts) and the Bearer-token mobile API (app/api/mobile/v1/*).
//
// Kept out of lib/assignments.ts because that module is "use server" (every export
// must be an async server action); this one holds plain helpers, types, and consts.

import { db } from "@/lib/db";
import { grammarLessonDrills } from "@/lib/drills/grammar";

// Wording the URL check rejects with — kept in one place so the web action and the
// mobile API stay in lockstep (the mobile contract uses this exact string; the web
// action appends "to your solution." to it).
export const BAD_URL_MESSAGE = "Paste a link starting with http(s)://";

const lessonTitleBySlug = new Map(grammarLessonDrills.map((d) => [d.slug, d.title]));

export type StudentSubmission = {
  url: string | null;
  submittedAt: string; // ISO
  score: number | null;
  feedback: string | null;
  gradedAt: string | null; // ISO
};

export type StudentAssignment = {
  id: string;
  kind: "problemSet" | "lesson";
  title: string;
  points: number;
  dueAt: string | null; // ISO
  courseId: string;
  problemSetId: string | null;
  solutionsAvailable: boolean; // problem-set only: solutionsPublic && solution non-empty
  lessonSlug: string | null; // set for kind === "lesson"
  submission: StudentSubmission | null;
};

export type SectionAssignments = {
  sectionName: string;
  courseId: string;
  courseTitle: string;
  assignments: StudentAssignment[];
};

/**
 * A section's homework with this student's own submission, shaped for the app.
 * Mirrors the query + title/solution rules in the web class hub
 * (app/(site)/dashboard/class/[sectionId]/page.tsx). Returns null when the caller
 * isn't an active enrollee of the section (so the route can 403/404).
 */
export async function getSectionAssignmentsFor(
  sectionId: string,
  userId: string,
): Promise<SectionAssignments | null> {
  const section = await db.section.findUnique({
    where: { id: sectionId },
    select: { name: true, course: { select: { id: true, title: true } } },
  });
  if (!section) return null;

  const enrollment = await db.enrollment.findUnique({
    where: { sectionId_userId: { sectionId, userId } },
    select: { status: true },
  });
  if (!enrollment || enrollment.status !== "active") return null;

  const rows = await db.assignment.findMany({
    where: { sectionId },
    orderBy: [{ dueAt: "asc" }, { createdAt: "asc" }],
    include: {
      problemSet: { select: { id: true, title: true, solution: true, solutionsPublic: true } },
      submissions: {
        where: { userId },
        select: { url: true, submittedAt: true, score: true, feedback: true, gradedAt: true },
      },
    },
  });

  const courseId = section.course.id;
  const assignments: StudentAssignment[] = rows.map((a) => {
    const sub = a.submissions[0] ?? null;
    const isLesson = !!a.lessonSlug;
    const ps = a.problemSet;
    // title falls back Assignment.title ?? problemSet.title ?? lesson title.
    const title =
      a.title ??
      (isLesson ? lessonTitleBySlug.get(a.lessonSlug!) ?? a.lessonSlug! : ps?.title ?? "Assignment");
    const solutionsAvailable =
      !isLesson && !!ps && ps.solutionsPublic && ps.solution.trim().length > 0;
    return {
      id: a.id,
      kind: isLesson ? "lesson" : "problemSet",
      title,
      points: a.points,
      dueAt: a.dueAt ? a.dueAt.toISOString() : null,
      courseId,
      problemSetId: isLesson ? null : a.problemSetId,
      solutionsAvailable,
      lessonSlug: isLesson ? a.lessonSlug : null,
      submission: sub
        ? {
            url: sub.url,
            submittedAt: sub.submittedAt.toISOString(),
            score: sub.score,
            feedback: sub.feedback,
            gradedAt: sub.gradedAt ? sub.gradedAt.toISOString() : null,
          }
        : null,
    };
  });

  return {
    sectionName: section.name,
    courseId,
    courseTitle: section.course.title,
    assignments,
  };
}

export type SubmitResult =
  | { ok: true; submission: StudentSubmission }
  | { ok: false; status: number; error: string };

/**
 * Core of a student link submission, shared by the web action and the mobile API:
 * validate the URL, authorize the caller as an active enrollee of the assignment's
 * section, then upsert their Submission (url + submittedAt only — score / feedback /
 * gradedAt are the instructor's and are never touched here). Path revalidation stays
 * in the web action; this helper is the pure data mutation.
 */
export async function submitAssignmentFor(
  assignmentId: string,
  userId: string,
  rawUrl: string,
): Promise<SubmitResult> {
  const url = rawUrl.trim();
  if (!/^https?:\/\//i.test(url)) {
    return { ok: false, status: 400, error: BAD_URL_MESSAGE };
  }

  const assignment = await db.assignment.findUnique({
    where: { id: assignmentId },
    select: { sectionId: true },
  });
  if (!assignment) return { ok: false, status: 404, error: "That assignment no longer exists." };

  const enrollment = await db.enrollment.findUnique({
    where: { sectionId_userId: { sectionId: assignment.sectionId, userId } },
    select: { status: true },
  });
  if (!enrollment || enrollment.status !== "active") {
    return { ok: false, status: 403, error: "You're not registered for this class." };
  }

  const sub = await db.submission.upsert({
    where: { assignmentId_userId: { assignmentId, userId } },
    create: { assignmentId, userId, url },
    update: { url, submittedAt: new Date() },
    select: { url: true, submittedAt: true, score: true, feedback: true, gradedAt: true },
  });

  return {
    ok: true,
    submission: {
      url: sub.url,
      submittedAt: sub.submittedAt.toISOString(),
      score: sub.score,
      feedback: sub.feedback,
      gradedAt: sub.gradedAt ? sub.gradedAt.toISOString() : null,
    },
  };
}
