"use server";

// Homework server actions: course-level problem sets + section assignments (admin)
// and link submissions (students). Mirrors the auth/write patterns in
// lib/classes.ts and app/admin/achievements/actions.ts.

import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { revalidatePath } from "next/cache";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { checkAdminPassword } from "@/lib/admin-auth";

async function assertAdmin() {
  const store = await cookies();
  if (!checkAdminPassword(store.get("admin_auth")?.value ?? null)) {
    throw new Error("Unauthorized");
  }
}

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
  revalidatePath("/admin/problem-sets");
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

// Instructor-controlled per-assignment toggle to reveal the solution to a section.
export async function toggleSolutionsReleased(formData: FormData) {
  await assertAdmin();
  const assignmentId = String(formData.get("assignmentId") ?? "");
  if (!assignmentId) throw new Error("Missing assignment");
  const a = await db.assignment.findUnique({
    where: { id: assignmentId },
    select: { sectionId: true, solutionsReleased: true },
  });
  if (!a) throw new Error("Assignment not found");
  await db.assignment.update({
    where: { id: assignmentId },
    data: { solutionsReleased: !a.solutionsReleased },
  });
  revalidatePath(`/admin/classes/${a.sectionId}`);
  revalidatePath("/dashboard");
}

export async function deleteProblemSet(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing id");
  const ps = await db.problemSet.delete({ where: { id }, select: { courseId: true } });
  revalidatePath("/admin/problem-sets");
  revalidatePath(`/courses/${ps.courseId}`);
}

// ---- Assignments (section-level) ----

export async function createAssignment(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const problemSetId = String(formData.get("problemSetId") ?? "");
  const points = Math.max(0, parseInt(String(formData.get("points") ?? "100"), 10) || 100);
  const videoId = String(formData.get("videoId") ?? "").trim() || null;
  const title = String(formData.get("title") ?? "").trim() || null;
  const dueAt = parseDueAt(formData.get("dueAt"));
  if (!sectionId || !problemSetId) throw new Error("Section and problem set are required");
  await db.assignment.create({ data: { sectionId, problemSetId, points, videoId, dueAt, title } });
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
  if (!/^https?:\/\//i.test(url)) return { error: "Paste a link starting with http(s):// to your solution." };

  const assignment = await db.assignment.findUnique({
    where: { id: assignmentId },
    select: { sectionId: true, section: { select: { courseId: true } } },
  });
  if (!assignment) return { error: "That assignment no longer exists." };

  const enrollment = await db.enrollment.findUnique({
    where: { sectionId_userId: { sectionId: assignment.sectionId, userId } },
    select: { status: true },
  });
  if (!enrollment || enrollment.status !== "active") {
    return { error: "You're not registered for this class." };
  }

  await db.submission.upsert({
    where: { assignmentId_userId: { assignmentId, userId } },
    create: { assignmentId, userId, url },
    update: { url, submittedAt: new Date() },
  });

  revalidatePath(`/courses/${assignment.section.courseId}`);
  revalidatePath("/dashboard");
  return { success: "Submitted — your instructor can now see your link." };
}
