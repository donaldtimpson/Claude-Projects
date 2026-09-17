"use server";

// Admin gradebook actions: per-section weight config plus per-cell auto-saving
// marks — attendance (per lecture), homework scores (hand-entered, no URL
// needed), and midterm/final. Each cell calls one of these on edit; there is no
// row-level Save. The weighted grade itself is computed read-side in
// lib/gradebook.ts.

import { revalidatePath } from "next/cache";
import { db } from "@/lib/db";
import { assertAdmin } from "@/lib/admin-auth";

// Non-negative int from a form field, or null when blank/invalid.
function intOrNull(v: FormDataEntryValue | null): number | null {
  const s = String(v ?? "").trim();
  if (s === "") return null;
  const n = parseInt(s, 10);
  return Number.isNaN(n) ? null : Math.max(0, n);
}

// Revalidate every surface that shows a section's grades (admin gradebook +
// student dashboard, which share getSectionGradebook).
function revalidateSection(sectionId: string) {
  revalidatePath(`/admin/classes/${sectionId}`);
  revalidatePath("/dashboard");
  revalidatePath(`/dashboard/class/${sectionId}`);
}

export async function setGradeWeights(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  if (!sectionId) throw new Error("Missing section");
  const w = (k: string, d: number) => intOrNull(formData.get(k)) ?? d;
  const gradeConfig = {
    weights: {
      attendance: w("attendance", 10),
      quizzes: w("quizzes", 10),
      test: w("test", 5),
      homework: w("homework", 25),
      midterm: w("midterm", 25),
      final: w("final", 25),
    },
    midtermMax: (intOrNull(formData.get("midtermMax")) ?? 100) || 100,
    finalMax: (intOrNull(formData.get("finalMax")) ?? 100) || 100,
  };
  await db.section.update({ where: { id: sectionId }, data: { gradeConfig } });
  revalidateSection(sectionId);
}

const ATTENDANCE_STATUSES = new Set(["present", "absent", "late", "excused"]);

// Mark (or clear, when status is "") one student's attendance for one lecture.
export async function setAttendance(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const videoId = String(formData.get("videoId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  const status = String(formData.get("status") ?? "").trim();
  if (!sectionId || !videoId || !userId) throw new Error("Missing section, lecture, or student");

  if (status === "") {
    await db.attendance.deleteMany({ where: { sectionId, videoId, userId } });
  } else {
    if (!ATTENDANCE_STATUSES.has(status)) throw new Error("Unknown attendance status");
    await db.attendance.upsert({
      where: { sectionId_videoId_userId: { sectionId, videoId, userId } },
      create: { sectionId, videoId, userId, status },
      update: { status, markedAt: new Date() },
    });
  }
  revalidateSection(sectionId);
}

// Enter (or clear, when blank) one student's homework score for one assignment.
// Stored as a Submission with no URL required; a real 0 counts, blank does not.
export async function setHomeworkScore(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const assignmentId = String(formData.get("assignmentId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  if (!sectionId || !assignmentId || !userId) throw new Error("Missing assignment or student");
  const score = intOrNull(formData.get("score"));

  const assignment = await db.assignment.findUnique({
    where: { id: assignmentId },
    select: { sectionId: true, section: { select: { courseId: true } } },
  });
  if (!assignment || assignment.sectionId !== sectionId) throw new Error("Assignment not in this section");

  const existing = await db.submission.findUnique({
    where: { assignmentId_userId: { assignmentId, userId } },
    select: { url: true },
  });

  if (score === null) {
    // Clearing: keep a real student submission (drop only the score), else remove.
    if (existing?.url) {
      await db.submission.update({
        where: { assignmentId_userId: { assignmentId, userId } },
        data: { score: null, gradedAt: null },
      });
    } else if (existing) {
      await db.submission.delete({ where: { assignmentId_userId: { assignmentId, userId } } });
    }
  } else {
    await db.submission.upsert({
      where: { assignmentId_userId: { assignmentId, userId } },
      create: { assignmentId, userId, url: null, score, gradedAt: new Date() },
      update: { score, gradedAt: new Date() },
    });
  }

  revalidateSection(sectionId);
  revalidatePath(`/admin/classes/${sectionId}/assignments/${assignmentId}`);
}

// ---- Custom grade categories (e.g. in-class Tests): category → items → scores ----

export async function addGradeCategory(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const name = String(formData.get("name") ?? "").trim() || "Category";
  if (!sectionId) throw new Error("Missing section");
  const position = await db.gradeCategory.count({ where: { sectionId } });
  await db.gradeCategory.create({ data: { sectionId, name, position } });
  revalidateSection(sectionId);
}

export async function updateGradeCategory(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing category");
  const data: { name?: string; weight?: number } = {};
  const name = formData.get("name");
  if (name !== null) data.name = String(name).trim() || "Category";
  const weight = intOrNull(formData.get("weight"));
  if (formData.get("weight") !== null) data.weight = weight ?? 0;
  const cat = await db.gradeCategory.update({ where: { id }, data, select: { sectionId: true } });
  revalidateSection(cat.sectionId);
}

export async function deleteGradeCategory(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing category");
  const cat = await db.gradeCategory.delete({ where: { id }, select: { sectionId: true } });
  revalidateSection(cat.sectionId);
}

export async function addGradeItem(formData: FormData) {
  await assertAdmin();
  const categoryId = String(formData.get("categoryId") ?? "");
  if (!categoryId) throw new Error("Missing category");
  const cat = await db.gradeCategory.findUnique({ where: { id: categoryId }, select: { sectionId: true, name: true } });
  if (!cat) throw new Error("Category not found");
  const position = await db.gradeItem.count({ where: { categoryId } });
  // Auto-name sequentially off the category (Tests → "Test 1", "Test 2", …),
  // derived from the DB count so rapid clicks never collide. Rename inline after.
  const name = `${cat.name.replace(/s$/i, "")} ${position + 1}`;
  await db.gradeItem.create({ data: { categoryId, name, maxPoints: 100, position } });
  revalidateSection(cat.sectionId);
}

export async function updateGradeItem(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing item");
  const data: { name?: string; maxPoints?: number } = {};
  const name = formData.get("name");
  if (name !== null) data.name = String(name).trim() || "Item";
  if (formData.get("maxPoints") !== null) data.maxPoints = (intOrNull(formData.get("maxPoints")) ?? 100) || 100;
  const item = await db.gradeItem.update({
    where: { id },
    data,
    select: { category: { select: { sectionId: true } } },
  });
  revalidateSection(item.category.sectionId);
}

export async function deleteGradeItem(formData: FormData) {
  await assertAdmin();
  const id = String(formData.get("id") ?? "");
  if (!id) throw new Error("Missing item");
  const item = await db.gradeItem.delete({
    where: { id },
    select: { category: { select: { sectionId: true } } },
  });
  revalidateSection(item.category.sectionId);
}

// Enter (or clear, when blank) one student's score on one custom-category item.
export async function setGradeScore(formData: FormData) {
  await assertAdmin();
  const itemId = String(formData.get("itemId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  if (!itemId || !userId) throw new Error("Missing item or student");
  const score = intOrNull(formData.get("score"));
  const item = await db.gradeItem.findUnique({
    where: { id: itemId },
    select: { category: { select: { sectionId: true } } },
  });
  if (!item) throw new Error("Item not found");

  if (score === null) {
    await db.gradeScore.deleteMany({ where: { itemId, userId } });
  } else {
    await db.gradeScore.upsert({
      where: { itemId_userId: { itemId, userId } },
      create: { itemId, userId, score },
      update: { score },
    });
  }
  revalidateSection(item.category.sectionId);
}

const EXAM_FIELDS = new Set(["midtermScore", "finalScore"]);

// Enter (or clear, when blank) one student's midterm or final points.
export async function setExamMark(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  const field = String(formData.get("field") ?? "");
  if (!sectionId || !userId) throw new Error("Missing section or student");
  if (!EXAM_FIELDS.has(field)) throw new Error("Unknown exam field");
  await db.enrollment.update({
    where: { sectionId_userId: { sectionId, userId } },
    data: { [field]: intOrNull(formData.get("value")) },
  });
  revalidateSection(sectionId);
}
