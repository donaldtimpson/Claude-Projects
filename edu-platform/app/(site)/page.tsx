import Link from "next/link";
import Image from "next/image";
import { db } from "@/lib/db";
import ContinueWatching from "./ContinueWatching";

export const dynamic = "force-dynamic";

export default async function HomePage() {
  const [courses, categories, currentCourses] = await Promise.all([
    db.course.findMany({
      orderBy: [{ publishedAt: "desc" }, { createdAt: "desc" }],
      include: { _count: { select: { videos: true } } },
    }),
    db.category.findMany({
      orderBy: { name: "asc" },
      include: { _count: { select: { courses: true } } },
    }),
    db.course.findMany({
      where: { isCurrent: true },
      orderBy: { publishedAt: "desc" },
      include: {
        videos: {
          orderBy: [{ publishedAt: "desc" }, { position: "desc" }],
          take: 1,
        },
      },
    }),
  ]);

  return (
    <main className="flex-1">
      {/* Hero */}
      <div className="w-full">
        <Image src="/banner.png" alt="The Timpson Lyceum" width={1983} height={523} className="w-full h-auto" priority />
      </div>

      <div className="max-w-6xl mx-auto px-6 py-12 space-y-16">
        {/* Continue Watching (signed-in users with in-progress courses) */}
        <ContinueWatching />

        {/* Currently Teaching */}
        {currentCourses.length > 0 && (
          <section>
            <h2 className="font-display text-lg tracking-[0.25em] uppercase text-gold-400 mb-8 pb-3 border-b border-crimson-700">
              Currently Teaching
            </h2>
            <div
              className={`grid gap-6 ${
                currentCourses.length === 1
                  ? "grid-cols-1 max-w-2xl"
                  : currentCourses.length === 2
                  ? "grid-cols-1 sm:grid-cols-2"
                  : "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
              }`}
            >
              {currentCourses.map((course) => {
                const latest = course.videos[0];
                const href = latest
                  ? `/courses/${course.id}/${latest.id}`
                  : `/courses/${course.id}`;
                return (
                  <Link
                    key={course.id}
                    href={href}
                    className="group bg-crimson-900 border-2 border-gold-500 rounded-lg overflow-hidden hover:border-gold-300 transition-colors shadow-lg shadow-gold-500/10"
                  >
                    {(latest?.thumbnailUrl || course.thumbnailUrl) ? (
                      <div className="relative aspect-video">
                        <Image
                          src={latest?.thumbnailUrl || course.thumbnailUrl}
                          alt={course.title}
                          fill
                          className="object-cover opacity-95 group-hover:opacity-100 transition-opacity"
                        />
                        <span className="absolute top-2 left-2 bg-gold-500 text-crimson-950 text-[10px] font-display tracking-widest uppercase px-2 py-0.5 rounded">
                          Live
                        </span>
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
                      {latest ? (
                        <p className="text-sm text-parchment-dim mt-2 line-clamp-2">
                          Latest: {latest.title}
                        </p>
                      ) : (
                        <p className="text-sm text-parchment-dim mt-2">No lectures yet</p>
                      )}
                      {latest?.publishedAt && (
                        <p className="text-xs text-gold-500 mt-1 font-display tracking-wider">
                          {new Date(latest.publishedAt).toLocaleDateString()}
                        </p>
                      )}
                    </div>
                  </Link>
                );
              })}
            </div>
          </section>
        )}

        {/* Categories */}
        {categories.length > 0 && (
          <section>
            <h2 className="font-display text-lg tracking-[0.25em] uppercase text-gold-400 mb-8 pb-3 border-b border-crimson-700">
              Browse by Category
            </h2>
            <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4">
              {categories.map((cat) => (
                <Link
                  key={cat.id}
                  href={`/categories/${cat.slug}`}
                  className="group bg-crimson-900 border border-crimson-700 rounded-xl overflow-hidden hover:border-gold-500 transition-colors"
                >
                  {/* Image slot — drop /public/categories/{slug}.png to fill */}
                  <CategoryImageSlot slug={cat.slug} name={cat.name} />
                  <div className="px-4 py-3">
                    <p className="font-display text-sm tracking-wide text-parchment group-hover:text-gold-300 transition-colors">
                      {cat.name}
                    </p>
                    <p className="text-xs text-parchment-dim mt-0.5">
                      {cat._count.courses} course{cat._count.courses !== 1 ? "s" : ""}
                    </p>
                  </div>
                </Link>
              ))}
            </div>
          </section>
        )}

        {/* All Courses */}
        <section>
          <h2 className="font-display text-lg tracking-[0.25em] uppercase text-gold-400 mb-8 pb-3 border-b border-crimson-700">
            All Courses
          </h2>
          {courses.length === 0 ? (
            <p className="text-parchment-dim">
              No courses yet.{" "}
              <Link href="/admin" className="text-gold-400 hover:text-gold-300 underline">
                Sync from YouTube
              </Link>{" "}
              to get started.
            </p>
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
        </section>
      </div>
    </main>
  );
}

function CategoryImageSlot({ slug, name }: { slug: string; name: string }) {
  return (
    <div className="relative aspect-video bg-crimson-800 overflow-hidden">
      <Image
        src={`/categories/${slug}.png`}
        alt={name}
        fill
        className="object-cover opacity-90 group-hover:opacity-100 transition-opacity"
      />
    </div>
  );
}
