import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

// Course dependency graph: nodes (courses) + edges (CourseLink). The client
// renders the map; layout helpers live in @/lib/course-graph if needed later.
export async function GET() {
  const [courses, links] = await Promise.all([
    db.course.findMany({
      select: { id: true, title: true, thumbnailUrl: true, canonicalCourseId: true },
    }),
    db.courseLink.findMany({
      select: { fromCourseId: true, toCourseId: true, kind: true },
    }),
  ]);
  return ok({ courses, links });
}
