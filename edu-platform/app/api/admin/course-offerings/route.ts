import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { db } from "@/lib/db";

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

// Group course offerings of the same subject under one canonical (representative)
// course. POST { courseId, canonicalCourseId } attaches `courseId` as a sibling
// offering of the representative; canonicalCourseId null/omitted detaches it back
// to its own standalone subject.
export async function POST(req: Request) {
  if (!(await isAdmin())) return NextResponse.json({ error: "Unauthorized" }, { status: 401 });

  const { courseId, canonicalCourseId } = await req.json();
  if (!courseId) return NextResponse.json({ error: "Missing courseId" }, { status: 400 });

  const course = await db.course.findUnique({ where: { id: courseId }, select: { id: true } });
  if (!course) return NextResponse.json({ error: "Course not found" }, { status: 404 });

  // Detach → standalone subject.
  if (!canonicalCourseId) {
    await db.course.update({ where: { id: courseId }, data: { canonicalCourseId: null } });
    return NextResponse.json({ ok: true });
  }

  const target = await db.course.findUnique({
    where: { id: canonicalCourseId },
    select: { id: true, canonicalCourseId: true },
  });
  if (!target) return NextResponse.json({ error: "Target course not found" }, { status: 404 });

  // Attaching to a sibling resolves to that sibling's representative (no chains).
  const repId = target.canonicalCourseId ?? target.id;
  if (repId === courseId) {
    return NextResponse.json({ error: "A course can't be an offering of itself." }, { status: 400 });
  }

  // A course that is itself a representative (has its own offerings) can't become
  // a sibling without orphaning them — detach those first.
  const childCount = await db.course.count({ where: { canonicalCourseId: courseId } });
  if (childCount > 0) {
    return NextResponse.json(
      { error: "This course already has its own offerings. Detach them before making it an offering of another subject." },
      { status: 409 },
    );
  }

  // Connections live on the representative. Rather than silently migrate this
  // course's own links, require they be cleared first (keeps the model honest).
  const linkCount = await db.courseLink.count({
    where: { OR: [{ fromCourseId: courseId }, { toCourseId: courseId }] },
  });
  if (linkCount > 0) {
    return NextResponse.json(
      { error: "Remove this course's connections before making it an offering of another subject — connections are managed on the canonical offering." },
      { status: 409 },
    );
  }

  await db.course.update({ where: { id: courseId }, data: { canonicalCourseId: repId } });
  return NextResponse.json({ ok: true });
}
