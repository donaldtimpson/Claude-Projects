import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

export async function GET() {
  const rows = await db.category.findMany({
    orderBy: { name: "asc" },
    select: {
      id: true,
      name: true,
      slug: true,
      // Count only canonical (representative) offerings so it matches the list
      // shown when drilling into the category.
      _count: { select: { courses: { where: { course: { canonicalCourseId: null } } } } },
    },
  });
  const categories = rows.map((c) => ({
    id: c.id,
    name: c.name,
    slug: c.slug,
    courseCount: c._count.courses,
  }));
  return ok({ categories });
}
