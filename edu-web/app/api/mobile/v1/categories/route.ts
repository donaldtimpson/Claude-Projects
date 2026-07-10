import { db } from "@/lib/db";
import { ok } from "@/lib/mobile/respond";

export async function GET() {
  const categories = await db.category.findMany({
    orderBy: { name: "asc" },
    select: { id: true, name: true, slug: true },
  });
  return ok({ categories });
}
