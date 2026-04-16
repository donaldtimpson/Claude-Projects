import Link from "next/link";
import Image from "next/image";
import { db } from "@/lib/db";

export const revalidate = 3600;

export default async function HomePage() {
  const courses = await db.course.findMany({
    orderBy: { createdAt: "asc" },
    include: { _count: { select: { videos: true } } },
  });

  return (
    <main className="flex-1">
      <header className="border-b border-slate-800 px-6 py-5">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-white">Donald Timpson</h1>
            <p className="text-sm text-slate-400">Free courses in math, physics &amp; CS</p>
          </div>
          <a
            href="https://www.youtube.com/@donaldDtimpson"
            target="_blank"
            rel="noopener noreferrer"
            className="text-sm text-red-400 hover:text-red-300 transition-colors"
          >
            YouTube ↗
          </a>
        </div>
      </header>

      <section className="max-w-6xl mx-auto px-6 py-12">
        <h2 className="text-2xl font-bold mb-8 text-white">Courses</h2>

        {courses.length === 0 ? (
          <p className="text-slate-400">
            No courses yet.{" "}
            <Link href="/admin" className="text-indigo-400 hover:underline">
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
                className="group bg-slate-900 border border-slate-800 rounded-xl overflow-hidden hover:border-indigo-500 transition-colors"
              >
                {course.thumbnailUrl ? (
                  <div className="relative aspect-video">
                    <Image
                      src={course.thumbnailUrl}
                      alt={course.title}
                      fill
                      className="object-cover"
                    />
                  </div>
                ) : (
                  <div className="aspect-video bg-slate-800 flex items-center justify-center">
                    <span className="text-slate-600 text-sm">No thumbnail</span>
                  </div>
                )}
                <div className="p-4">
                  <h3 className="font-semibold text-white group-hover:text-indigo-300 transition-colors line-clamp-2">
                    {course.title}
                  </h3>
                  <p className="text-sm text-slate-400 mt-1">
                    {course._count.videos} video{course._count.videos !== 1 ? "s" : ""}
                  </p>
                  {course.description && (
                    <p className="text-sm text-slate-500 mt-2 line-clamp-2">
                      {course.description}
                    </p>
                  )}
                </div>
              </Link>
            ))}
          </div>
        )}
      </section>
    </main>
  );
}
