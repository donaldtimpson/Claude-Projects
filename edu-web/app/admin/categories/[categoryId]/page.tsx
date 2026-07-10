import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import CategoryEditor from "./CategoryEditor";

export const dynamic = "force-dynamic";

export default async function AdminCategoryEditPage({
  params,
}: {
  params: Promise<{ categoryId: string }>;
}) {
  const { categoryId } = await params;

  const [category, allCourses] = await Promise.all([
    db.category.findUnique({
      where: { id: categoryId },
      include: { courses: { select: { courseId: true } } },
    }),
    db.course.findMany({ orderBy: { title: "asc" }, select: { id: true, title: true } }),
  ]);

  if (!category) notFound();

  const assignedIds = category.courses.map((c) => c.courseId);

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link
          href="/admin/categories"
          className="text-sm text-parchment-dim hover:text-parchment transition-colors"
        >
          ← Categories
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Edit Category</h1>
      </div>

      <CategoryEditor
        categoryId={category.id}
        initialName={category.name}
        initialSlug={category.slug}
        allCourses={allCourses}
        initialAssignedIds={assignedIds}
      />
    </main>
  );
}
