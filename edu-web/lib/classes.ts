"use server";

// Server actions for class registration (student) and section management (admin).
// A "section" is a live class instance tied to a public Course; students join it
// with a code, but only while that course is `isCurrent`. Mirrors the auth/write
// patterns in lib/actions.ts and app/admin/achievements/actions.ts.

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { randomInt } from "node:crypto";
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

// Human-friendly join code: 6 chars, no ambiguous 0/O/1/I/L. crypto.randomInt so
// codes aren't guessable (a valid code is the only thing gating registration).
const CODE_ALPHABET = "ABCDEFGHJKMNPQRSTUVWXYZ23456789";
function makeCode(len = 6): string {
  let out = "";
  for (let i = 0; i < len; i++) out += CODE_ALPHABET[randomInt(CODE_ALPHABET.length)];
  return out;
}
async function uniqueCode(): Promise<string> {
  for (let i = 0; i < 12; i++) {
    const code = makeCode();
    const existing = await db.section.findUnique({ where: { joinCode: code }, select: { id: true } });
    if (!existing) return code;
  }
  throw new Error("Could not generate a unique join code");
}

// ---- Student ----

export type RegisterState = { error?: string; success?: string };

// Register the signed-in student into a section via its join code. Only sections
// on the currently-active course accept registration.
export async function registerForClass(_prev: RegisterState, formData: FormData): Promise<RegisterState> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return { error: "You must be signed in to register." };

  const code = String(formData.get("joinCode") ?? "").trim().toUpperCase();
  if (!code) return { error: "Enter a class code." };

  const section = await db.section.findUnique({
    where: { joinCode: code },
    include: { course: { select: { id: true, isCurrent: true } } },
  });
  if (!section) return { error: "That class code isn't valid." };
  if (!section.course.isCurrent) return { error: "Registration for that class is closed." };

  await db.enrollment.upsert({
    where: { sectionId_userId: { sectionId: section.id, userId: session.user.id } },
    create: { sectionId: section.id, userId: session.user.id },
    update: { status: "active" },
  });

  revalidatePath(`/courses/${section.course.id}`);
  revalidatePath("/dashboard");
  return { success: `You're registered for ${section.name}.` };
}

// ---- Admin ----

export async function createSection(formData: FormData) {
  await assertAdmin();
  const courseId = String(formData.get("courseId") ?? "");
  const name = String(formData.get("name") ?? "").trim();
  if (!courseId || !name) throw new Error("Course and section name are required");
  const joinCode = await uniqueCode();
  await db.section.create({ data: { courseId, name, joinCode } });
  revalidatePath("/admin/classes");
}

export async function rotateJoinCode(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  if (!sectionId) throw new Error("Missing section");
  await db.section.update({ where: { id: sectionId }, data: { joinCode: await uniqueCode() } });
  revalidatePath("/admin/classes");
}

export async function removeEnrollment(formData: FormData) {
  await assertAdmin();
  const sectionId = String(formData.get("sectionId") ?? "");
  const userId = String(formData.get("userId") ?? "");
  if (!sectionId || !userId) throw new Error("Missing section or user");
  await db.enrollment.delete({ where: { sectionId_userId: { sectionId, userId } } });
  revalidatePath("/admin/classes");
}
