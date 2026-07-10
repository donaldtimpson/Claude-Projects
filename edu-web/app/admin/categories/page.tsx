import Link from "next/link";
import { db } from "@/lib/db";
import CategoryCreateForm from "./CategoryCreateForm";

export const dynamic = "force-dynamic";

export default async function AdminCategoriesPage() {
  const categories = await db.category.findMany({
    orderBy: { name: "asc" },
    include: { _count: { select: { courses: true } } },
  });

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Categories</h1>
      </div>

      {categories.length === 0 ? (
        <p className="text-parchment-dim text-sm">No categories yet.</p>
      ) : (
        <div className="space-y-3">
          {categories.map((cat) => (
            <div
              key={cat.id}
              className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center justify-between gap-4"
            >
              <div>
                <p className="font-semibold text-parchment">{cat.name}</p>
                <p className="text-xs text-parchment-dim mt-0.5">
                  slug: <span className="font-mono">{cat.slug}</span>
                  {" · "}
                  {cat._count.courses} course{cat._count.courses !== 1 ? "s" : ""}
                </p>
              </div>
              <Link
                href={`/admin/categories/${cat.id}`}
                className="text-sm text-gold-400 hover:text-gold-300 transition-colors shrink-0"
              >
                Edit
              </Link>
            </div>
          ))}
        </div>
      )}

      <section className="space-y-3">
        <h2 className="font-semibold text-parchment">New Category</h2>
        <CategoryCreateForm />
      </section>
    </main>
  );
}
