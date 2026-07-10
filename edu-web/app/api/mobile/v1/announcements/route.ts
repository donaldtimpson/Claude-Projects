import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

// Announcements. With ?courseId=, returns that course's announcements plus any
// site-wide ones (courseId null); without it, just the site-wide feed.
export async function GET(req: Request) {
  const courseId = new URL(req.url).searchParams.get("courseId");
  const where = courseId ? { OR: [{ courseId }, { courseId: null }] } : { courseId: null };
  const announcements = await db.announcement.findMany({
    where,
    orderBy: [{ pinned: "desc" }, { createdAt: "desc" }],
    select: {
      id: true,
      title: true,
      body: true,
      pinned: true,
      courseId: true,
      createdAt: true,
      updatedAt: true,
    },
  });
  return ok({ announcements });
}
