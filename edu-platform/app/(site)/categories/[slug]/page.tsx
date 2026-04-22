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
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-6xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-6xl mx-auto px-6 py-12 relative">
        {/* Category image — faded watermark behind the courses.
            bg-crimson-950 on the body acts as the base colour layer.
            backgroundSize:contain shows the full image without cropping. */}
        <div
          className="absolute inset-0 pointer-events-none select-none"
          style={{
            backgroundImage: `url('/categories/${slug}.png')`,
            backgroundSize: "contain",
            backgroundPosition: "center top",
            backgroundRepeat: "no-repeat",
            opacity: 0.18,
          }}
          aria-hidden="true"
        />

        <div className="relative z-10 space-y-10">
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
                      {course._count.videos} video{course._count.videos !== 1 ? "s" : ""}
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
    </main>
  );
}
