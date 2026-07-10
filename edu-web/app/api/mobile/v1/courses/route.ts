import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

// Public catalog grid. No auth — students can browse before signing in.
export async function GET() {
  const courses = await db.course.findMany({
    // Only representative (canonical) offerings — one per subject. Other
    // offerings are reachable from a course's detail page.
    where: { canonicalCourseId: null },
    orderBy: [{ isCurrent: "desc" }, { title: "asc" }],
    select: {
      id: true,
      title: true,
      shortTitle: true,
      description: true,
      thumbnailUrl: true,
      videoCount: true,
      isCurrent: true,
      updatedAt: true,
    },
  });
  return ok({ courses });
}
