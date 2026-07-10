import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

// Public catalog grid. No auth — students can browse before signing in.
export async function GET() {
  const courses = await db.course.findMany({
    orderBy: [{ isCurrent: "desc" }, { title: "asc" }],
    select: {
      id: true,
      title: true,
      description: true,
      thumbnailUrl: true,
      videoCount: true,
      isCurrent: true,
      updatedAt: true,
    },
  });
  return ok({ courses });
}
