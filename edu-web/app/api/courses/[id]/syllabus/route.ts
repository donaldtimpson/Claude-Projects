import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { db } from "@/lib/db";
import { checkAdminPassword } from "@/lib/admin-auth";

async function isAdmin() {
  const store = await cookies();
  return checkAdminPassword(store.get("admin_auth")?.value ?? null);
}

// Update a course's Markdown syllabus. Admin-only (same cookie gate as the
// notes/quiz editors). Empty string clears it (the public page hides an empty
// syllabus, like Course.description).
export async function PUT(
  req: Request,
  { params }: { params: Promise<{ id: string }> },
) {
  if (!(await isAdmin())) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
  const { id } = await params;
  const body = await req.json().catch(() => null);
  const syllabus = body?.syllabus;
  if (typeof syllabus !== "string") {
    return NextResponse.json({ error: "Missing syllabus" }, { status: 400 });
  }

  const course = await db.course.update({
    where: { id },
    data: { syllabus },
    select: { id: true, syllabus: true },
  });

  revalidatePath(`/admin/courses/${id}`);
  revalidatePath(`/courses/${id}`);
  revalidatePath(`/courses/${id}/syllabus`);
  return NextResponse.json(course);
}
