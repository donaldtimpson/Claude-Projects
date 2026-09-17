"use server";

// Homework server actions: course-level problem sets + section assignments (admin)
// and link submissions (students). Mirrors the auth/write patterns in
// lib/classes.ts and app/admin/achievements/actions.ts.

import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { assertAdmin } from "@/lib/admin-auth";
import { LESSON_SLUGS } from "@/lib/lessons";
import { submitAssignmentFor } from "@/lib/assignments-data";

function parseDueAt(raw: FormDataEntryValue | null): Date | null {
  const s = String(raw ?? "").trim();
  if (!s) return null;
  const d = new Date(s);
  return Number.isNaN(d.getTime()) ? null : d;
}

// ---- Problem sets (course-level, public) ----

export async function createProblemSet(formData: FormData) {
  await assertAdmin();
  const courseId = String(formData.get("courseId") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  if (!courseId || !title) throw new Error("Course and title are required");
  const ps = await db.problemSet.create({ data: { courseId, title } });
  revalidatePath(`/admin/courses/${courseId}/problem-sets`);
  // Straight into the editor (edit mode — it's empty) to author problems + solution.
  redirect(`/admin/problem-sets/${ps.id}?mode=edit`);
}

export async function updateProblemSet(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  const title = String(formData.get("title") ?? "").trim();
  const body = String(formData.get("body") ?? "");
  const solution = String(formData.get("solution") ?? "");
  const attachmentUrl = String(formData.get("attachmentUrl") ?? "").trim() || null;
  const points = Math.max(0, parseInt(String(formData.get("points") ?? "0"), 10) || 0);
  const extraCreditPoints = Math.max(0, parseInt(String(formData.get("extraCreditPoints") ?? "0"), 10) || 0);
  if (!id || !title) throw new Error("Missing id or title");
  const ps = await db.problemSet.update({
    where: { id },
    data: { title, body, solution, attachmentUrl, points, extraCreditPoints },
    select: { courseId: true },
  });
  revalidatePath("/admin/problem-sets");
  revalidatePath(`/admin/problem-sets/${id}`);
  revalidatePath(`/courses/${ps.courseId}`);
  revalidatePath(`/courses/${ps.courseId}/problems/${id}`);
}

// Publish / unpublish a problem set (draft gate, like quizzes/notes).
export async function setProblemSetDraft(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  const isDraft = String(formData.get("isDraft") ?? "") === "true";
  if (!id) throw new Error("Missing id");
  const ps = await db.problemSet.update({
    where: { id },
    data: { isDraft },
    select: { courseId: true },
  });
  revalidatePath("/admin/problem-sets");
  revalidatePath(`/admin/problem-sets/${id}`);
  revalidatePath(`/courses/${ps.courseId}`);
}

// "Public unless withheld": solutions ship with the problems by default. This
// flips a single set's answers back to hidden. ProblemSet.solutionsPublic is the
// single source of truth for solution visibility.
export async function toggleSolutionsPublic(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing id");
  const current = await db.problemSet.findUnique({
    where: { id },
    select: { solutionsPublic: true },
  });
  if (!current) throw new Error("Problem set not found");
  const ps = await db.problemSet.update({
    where: { id },
    data: { solutionsPublic: !current.solutionsPublic },
    select: { courseId: true },
  });
  revalidatePath(`/admin/problem-sets/${id}`);
  revalidatePath(`/courses/${ps.courseId}/problems/${id}`);
}

// Replace the set of lectures a problem set covers (many-to-many). Sent as a
// repeated "videoId" field; an empty list clears every tag.
export async function setProblemSetVideos(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing id");
  const videoIds = formData.getAll("videoId").map(String).filter(Boolean);

  const ps = await db.problemSet.findUnique({ where: { id }, select: { courseId: true } });
  if (!ps) throw new Error("Problem set not found");

  // Only lectures from this set's own course may be tagged.
  const valid = await db.video.findMany({
    where: { id: { in: videoIds }, courseId: ps.courseId },
    select: { id: true },
  });

  await db.$transaction([
    db.problemSetVideo.deleteMany({ where: { problemSetId: id } }),
    db.problemSetVideo.createMany({
      data: valid.map((v) => ({ problemSetId: id, videoId: v.id })),
    }),
  ]);

  revalidatePath(`/admin/problem-sets/${id}`);
  revalidatePath(`/courses/${ps.courseId}/problems/${id}`);
  for (const v of valid) revalidatePath(`/courses/${ps.courseId}/${v.id}`);
}

export async function deleteProblemSet(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing id");
  const ps = await db.problemSet.delete({ where: { id }, select: { courseId: true } });
  revalidatePath("/admin/problem-sets");
  revalidatePath(`/courses/${ps.courseId}`);
}

// Replace the set of grammar lessons a lecture covers (many-to-many via
// VideoLesson). Sent as repeated "lessonSlug" fields; empty clears every link.
// Mirrors setProblemSetVideos. Lets a lecture surface "practice this lesson" and
// the drill show "covered by lecture X" once videos exist.
export async function setVideoLessons(formData: FormData) {
  await assertAdmin();
  const videoId = String(formData.get("videoId") ?? "");
  if (!videoId) throw new Error("Missing video");
  const known = new Set(LESSON_SLUGS);
  const slugs = [...new Set(formData.getAll("lessonSlug").map(String))].filter((s) => known.has(s));
  const video = await db.video.findUnique({ where: { id: videoId }, select: { courseId: true } });
  if (!video) throw new Error("Video not found");
  await db.$transaction([
    db.videoLesson.deleteMany({ where: { videoId } }),
    db.videoLesson.createMany({ data: slugs.map((lessonSlug) => ({ videoId, lessonSlug })) }),
  ]);
  revalidatePath(`/admin/courses/${video.courseId}`);
  revalidatePath(`/courses/${video.courseId}/${videoId}`);
}

// Replace the set of problem sets that cover a lecture (many-to-many via
// ProblemSetVideo), edited from the lecture side. The inverse of
// setProblemSetVideos — same join table, so a lecture and a problem set stay in
// sync no matter which side you link from. Sent as repeated "problemSetId".
export async function setVideoProblemSets(formData: FormData) {
  await assertAdmin();
  const videoId = String(formData.get("videoId") ?? "");
  if (!videoId) throw new Error("Missing video");
  const psIds = [...new Set(formData.getAll("problemSetId").map(String))].filter(Boolean);
  const video = await db.video.findUnique({ where: { id: videoId }, select: { courseId: true } });
  if (!video) throw new Error("Video not found");

  // Only problem sets from this lecture's own course may be tagged.
  const valid = await db.problemSet.findMany({
    where: { id: { in: psIds }, courseId: video.courseId },
    select: { id: true },
  });

  await db.$transaction([
    db.problemSetVideo.deleteMany({ where: { videoId } }),
    db.problemSetVideo.createMany({ data: valid.map((p) => ({ problemSetId: p.id, videoId })) }),
  ]);

  revalidatePath(`/admin/courses/${video.courseId}`);
  revalidatePath(`/courses/${video.courseId}/${videoId}`);
  for (const p of valid) revalidatePath(`/courses/${video.courseId}/problems/${p.id}`);
}

// ---- Assignments (section-level) ----

export async function createAssignment(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  // An assignment is EITHER a problem set/paper OR a grammar lesson drill.
  const kind = String(formData.get("kind") ?? "problemSet");
  const problemSetId = String(formData.get("problemSetId") ?? "").trim() || null;
  const lessonSlug = String(formData.get("lessonSlug") ?? "").trim() || null;
  const points = Math.max(0, parseInt(String(formData.get("points") ?? "100"), 10) || 100);
  const videoId = String(formData.get("videoId") ?? "").trim() || null;
  const title = String(formData.get("title") ?? "").trim() || null;
  const dueAt = parseDueAt(formData.get("dueAt"));
  if (!sectionId) throw new Error("Section is required");
  const data =
    kind === "lesson"
      ? { sectionId, lessonSlug, points, videoId, dueAt, title }
      : { sectionId, problemSetId, points, videoId, dueAt, title };
  if (kind === "lesson" && !lessonSlug) throw new Error("Lesson is required");
  if (kind !== "lesson" && !problemSetId) throw new Error("Problem set is required");
  await db.assignment.create({ data });
  const section = await db.section.findUnique({ where: { id: sectionId }, select: { courseId: true } });
  revalidatePath(`/admin/classes/${sectionId}`);
  if (section) revalidatePath(`/courses/${section.courseId}`);
}

export async function updateAssignment(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing assignment");
  const title = String(formData.get("title") ?? "").trim() || null;
  const points = Math.max(0, parseInt(String(formData.get("points") ?? "0"), 10) || 0);
  const dueAt = parseDueAt(formData.get("dueAt")); // empty clears the due date
  const a = await db.assignment.update({
    where: { id },
    data: { title, points, dueAt },
    select: { sectionId: true, section: { select: { courseId: true } } },
  });
  revalidatePath(`/admin/classes/${a.sectionId}`);
  revalidatePath(`/courses/${a.section.courseId}`);
  revalidatePath("/dashboard");
}

export async function deleteAssignment(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing id");
  const a = await db.assignment.delete({
    where: { id },
    select: { sectionId: true, section: { select: { courseId: true } } },
  });
  revalidatePath(`/admin/classes/${a.sectionId}`);
  revalidatePath(`/courses/${a.section.courseId}`);
}

export async function gradeSubmission(formData: FormData) {
  await assertAdmin();
  const assignmentId = String(formData.get("assignmentId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  if (!assignmentId || !userId) throw new Error("Missing assignment or student");
  const rawScore = String(formData.get("score") ?? "").trim();
  const score = rawScore === "" ? null : Math.max(0, parseInt(rawScore, 10) || 0);
  const feedback = String(formData.get("feedback") ?? "").trim() || null;
  const sub = await db.submission.update({
    where: { assignmentId_userId: { assignmentId, userId } },
    data: { score, feedback, gradedAt: score === null ? null : new Date() },
    select: { assignment: { select: { sectionId: true } } },
  });
  revalidatePath(`/admin/classes/${sub.assignment.sectionId}`);
  revalidatePath(`/admin/classes/${sub.assignment.sectionId}/assignments/${assignmentId}`);
  revalidatePath("/dashboard");
}

// ---- Student submission ----

export type SubmitState = { error?: string; success?: string };

export async function submitAssignment(_prev: SubmitState, formData: FormData): Promise<SubmitState> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return { error: "You must be signed in to submit." };
  const userId = session.user.id;

  const assignmentId = String(formData.get("assignmentId") ?? "");
  const url = String(formData.get("url") ?? "").trim();
  if (!assignmentId) return { error: "Missing assignment." };

  // Validate + authorize + upsert via the shared helper (also used by the mobile
  // API), so both surfaces enforce the same rules. The web action keeps its own
  // path revalidation and its longer, form-oriented copy.
  const result = await submitAssignmentFor(assignmentId, userId, url);
  if (!result.ok) {
    const error = result.status === 400 ? `${result.error} to your solution.` : result.error;
    return { error };
  }

  const assignment = await db.assignment.findUnique({
    where: { id: assignmentId },
    select: { sectionId: true, problemSetId: true, section: { select: { courseId: true } } },
  });
  if (assignment) {
    revalidatePath(`/courses/${assignment.section.courseId}`);
    // The problem set page carries its own copy of this form.
    if (assignment.problemSetId) {
      revalidatePath(`/courses/${assignment.section.courseId}/problems/${assignment.problemSetId}`);
    }
    revalidatePath("/dashboard");
    revalidatePath(`/dashboard/class/${assignment.sectionId}`);
  }
  return { success: "Submitted — your instructor can now see your link." };
}
