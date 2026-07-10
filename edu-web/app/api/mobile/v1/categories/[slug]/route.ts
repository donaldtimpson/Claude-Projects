import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";

export async function GET(
  _req: Request,
  { params }: { params: Promise<{ slug: string }> },
) {
  const { slug } = await params;
  const category = await db.category.findUnique({
    where: { slug },
    select: {
      id: true,
      name: true,
      slug: true,
      courses: {
        // Only representative (canonical) offerings, alphabetical by title.
        where: { course: { canonicalCourseId: null } },
        orderBy: { course: { title: "asc" } },
        select: {
          course: {
            select: {
              id: true,
              title: true,
              description: true,
              thumbnailUrl: true,
              videoCount: true,
              isCurrent: true,
              updatedAt: true,
            },
          },
        },
      },
    },
  });
  if (!category) return fail(404, "Category not found.");
  return ok({
    category: { id: category.id, name: category.name, slug: category.slug },
    courses: category.courses.map((c) => c.course),
  });
}
