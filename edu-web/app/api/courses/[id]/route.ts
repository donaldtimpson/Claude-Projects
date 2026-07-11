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
  const body = await req.json();

  // Reorder lectures: `videoOrder` is the full list of this course's video ids in
  // the desired order. Persist as contiguous 0-based positions so lecture
  // numbering stays clean. Only meaningful for manual-order courses.
  if (Array.isArray(body.videoOrder)) {
    const ids: string[] = body.videoOrder.filter((v: unknown): v is string => typeof v === "string");
    const courseVideos = await db.video.findMany({
      where: { courseId: id },
      select: { id: true },
    });
    const courseIdSet = new Set(courseVideos.map((v) => v.id));
    const sameSet =
      ids.length === courseVideos.length && ids.every((v) => courseIdSet.has(v));
    if (!sameSet) {
      return NextResponse.json(
        { error: "videoOrder must list exactly this course's lectures, once each." },
        { status: 400 },
      );
    }
    await db.$transaction(
      ids.map((videoId, index) =>
        db.video.update({ where: { id: videoId }, data: { position: index } }),
      ),
    );
    return NextResponse.json({ ok: true, reordered: ids.length });
  }

  const data: { isCurrent?: boolean; manualOrder?: boolean } = {};
  if (typeof body.isCurrent === "boolean") data.isCurrent = body.isCurrent;
  if (typeof body.manualOrder === "boolean") data.manualOrder = body.manualOrder;

  if (Object.keys(data).length === 0) {
    return NextResponse.json({ error: "No valid fields to update" }, { status: 400 });
  }

  const course = await db.course.update({ where: { id }, data });
  return NextResponse.json(course);
}
