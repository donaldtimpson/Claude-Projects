import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { Prisma } from "@prisma/client";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const courseId = searchParams.get("courseId");
  const scope = searchParams.get("scope");

  let where: Prisma.AnnouncementWhereInput = {};
  if (scope === "site") {
    where = { courseId: null };
  } else if (courseId) {
    where = { OR: [{ courseId }, { courseId: null }] };
  }

  const announcements = await db.announcement.findMany({
    where,
    orderBy: [{ pinned: "desc" }, { createdAt: "desc" }],
    include: { course: { select: { id: true, title: true } } },
  });
  return NextResponse.json(announcements);
}

export async function POST(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { title, body, courseId, pinned } = await req.json();

  if (!title?.trim()) {
    return NextResponse.json({ error: "title is required" }, { status: 400 });
  }

  if (courseId) {
    const course = await db.course.findUnique({ where: { id: courseId }, select: { id: true } });
    if (!course) return NextResponse.json({ error: "course not found" }, { status: 400 });
  }

  const announcement = await db.announcement.create({
    data: {
      title: title.trim(),
      body: (body ?? "").trim(),
      courseId: courseId || null,
      pinned: Boolean(pinned),
    },
  });
  return NextResponse.json(announcement, { status: 201 });
}
