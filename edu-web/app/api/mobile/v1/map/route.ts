import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

// Course dependency graph: nodes (courses) + edges (CourseLink). The client
// renders the map; layout helpers live in @/lib/course-graph if needed later.
export async function GET() {
  const [courses, links] = await Promise.all([
    db.course.findMany({
      // shortTitle is what the map labels nodes with — a full course title
      // doesn't fit a node on a phone (or on the web map, which does the same).
      select: {
        id: true, title: true, shortTitle: true, thumbnailUrl: true,
        canonicalCourseId: true, isCurrent: true,
      },
    }),
    db.courseLink.findMany({
      select: { fromCourseId: true, toCourseId: true, kind: true },
    }),
  ]);
  return ok({ courses, links });
}
