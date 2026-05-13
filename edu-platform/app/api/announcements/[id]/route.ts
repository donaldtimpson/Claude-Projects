import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export async function PATCH(req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  const { title, body, courseId, pinned } = await req.json();

  const data: { title?: string; body?: string; courseId?: string | null; pinned?: boolean } = {};
  if (typeof title === "string" && title.trim()) data.title = title.trim();
  if (typeof body === "string") data.body = body.trim();
  if (courseId !== undefined) {
    if (courseId) {
      const course = await db.course.findUnique({ where: { id: courseId }, select: { id: true } });
      if (!course) return NextResponse.json({ error: "course not found" }, { status: 400 });
      data.courseId = courseId;
    } else {
      data.courseId = null;
    }
  }
  if (typeof pinned === "boolean") data.pinned = pinned;

  const announcement = await db.announcement.update({ where: { id }, data });
  return NextResponse.json(announcement);
}

export async function DELETE(_req: Request, { params }: { params: Promise<{ id: string }> }) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { id } = await params;
  await db.announcement.delete({ where: { id } });
  return new NextResponse(null, { status: 204 });
}
