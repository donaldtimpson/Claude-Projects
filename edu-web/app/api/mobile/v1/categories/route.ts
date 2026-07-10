import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

export async function GET() {
  const rows = await db.category.findMany({
    orderBy: { name: "asc" },
    select: { id: true, name: true, slug: true, _count: { select: { courses: true } } },
  });
  const categories = rows.map((c) => ({
    id: c.id,
    name: c.name,
    slug: c.slug,
    courseCount: c._count.courses,
  }));
  return ok({ categories });
}
