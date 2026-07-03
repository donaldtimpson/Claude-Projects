"use server";

// Admin grade actions: per-section weight config + per-student manual marks
// (midterm/final points, attendance override). assertAdmin like the other admin
// actions; the weighted grade itself is computed read-side in lib/gradebook.ts.

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { db } from "@/lib/db";
import { checkAdminPassword } from "@/lib/admin-auth";

async function assertAdmin() {
  const store = await cookies();
  if (!checkAdminPassword(store.get("admin_auth")?.value ?? null)) {
    throw new Error("Unauthorized");
  }
}

// Non-negative int from a form field, or null when blank/invalid.
function intOrNull(v: FormDataEntryValue | null): number | null {
  const s = String(v ?? "").trim();
  if (s === "") return null;
  const n = parseInt(s, 10);
  return Number.isNaN(n) ? null : Math.max(0, n);
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
  revalidatePath(`/admin/classes/${sectionId}`);
  revalidatePath("/dashboard");
}

export async function setManualMarks(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  if (!sectionId || !userId) throw new Error("Missing section or student");
  await db.enrollment.update({
    where: { sectionId_userId: { sectionId, userId } },
    data: {
      midtermScore: intOrNull(formData.get("midtermScore")),
      finalScore: intOrNull(formData.get("finalScore")),
      attendanceOverride: intOrNull(formData.get("attendanceOverride")),
    },
  });
  revalidatePath(`/admin/classes/${sectionId}`);
  revalidatePath("/dashboard");
}
