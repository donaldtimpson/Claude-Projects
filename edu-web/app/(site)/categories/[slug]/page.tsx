import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";

export const dynamic = "force-dynamic";

export default async function CategoryPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;

  const category = await db.category.findUnique({
    where: { slug },
    include: {
      courses: {
        include: {
          course: {
            include: { _count: { select: { videos: true } } },
          },
        },
      },
    },
  });

  if (!category) notFound();

  const courses = category.courses
    .map((cc) => cc.course)
    .sort((a, b) => {
      const aDate = a.publishedAt ?? a.createdAt;
      const bDate = b.publishedAt ?? b.createdAt;
      return bDate.getTime() - aDate.getTime();
    });

  return (
    /*
     * Layout strategy for the static background effect:
     * - <main> is a fixed-height flex column (flex-1 + overflow-hidden)
     * - breadcrumb header is shrink-0 (doesn't participate in scroll)
     * - the inner wrapper is flex-1 + min-h-0 with a RELATIVE background layer
     *   and a separate overflow-y-auto scroll layer on top
     * - because the scroll layer is absolutely inset, the background div
     *   never moves — only the content layer scrolls
     */
    <main className="flex-1 overflow-hidden flex flex-col">
      {/* Breadcrumb — outside the scroll area, never moves */}
      <header className="shrink-0 border-b border-crimson-700 px-6 py-4">
        <div className="max-w-6xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      {/* Static background + scrollable content stacked in the same box */}
      <div className="flex-1 min-h-0 relative max-w-6xl mx-auto w-full">
        {/* Background layer — never scrolls */}
        <div className="absolute inset-0 bg-crimson-950" aria-hidden="true">
          <div
            className="absolute inset-0 opacity-[0.22]"
            style={{
              backgroundImage: `url('/categories/${slug}.png')`,
              backgroundSize: "contain",
              backgroundPosition: "center",
              backgroundRepeat: "no-repeat",
            }}
          />
        </div>

        {/* Scroll layer — sits on top, scrolls independently */}
        <div className="absolute inset-0 overflow-y-auto">
          <div className="px-6 pt-12 pb-[36rem] space-y-10">
            <h1 className="font-display text-4xl text-parchment">{category.name}</h1>

            {courses.length === 0 ? (
              <p className="text-parchment-dim text-sm">No courses in this category yet.</p>
            ) : (
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
                {courses.map((course) => (
                  <Link
                    key={course.id}
                    href={`/courses/${course.id}`}
                    className="group bg-crimson-900 border border-crimson-700 rounded-lg overflow-hidden hover:border-gold-500 transition-colors"
                  >
                    {course.thumbnailUrl ? (
                      <div className="relative aspect-video">
                        <Image
                          src={course.thumbnailUrl}
                          alt={course.title}
                          fill
                          className="object-cover opacity-90 group-hover:opacity-100 transition-opacity"
                        />
                      </div>
                    ) : (
                      <div className="aspect-video bg-crimson-800 flex items-center justify-center">
                        <span className="text-parchment-dim text-sm">No thumbnail</span>
                      </div>
                    )}
                    <div className="p-4">
                      <h3 className="font-display text-xs tracking-wider uppercase text-parchment group-hover:text-gold-300 transition-colors line-clamp-2">
                        {course.title}
                      </h3>
                      <p className="text-xs text-gold-500 mt-1 font-display tracking-wider">
                        {course._count.videos === 0
                          ? "Coming soon"
                          : `${course._count.videos} video${course._count.videos !== 1 ? "s" : ""}`}
                      </p>
                      {course.description && (
                        <p className="text-sm text-parchment-dim mt-2 line-clamp-2">
                          {course.description}
                        </p>
                      )}
                    </div>
                  </Link>
                ))}
              </div>
            )}
          </div>
        </div>
      </div>
    </main>
  );
}
