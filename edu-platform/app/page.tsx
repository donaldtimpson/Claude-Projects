import Link from "next/link";
import Image from "next/image";
import { db } from "@/lib/db";
import UserMenu from "@/components/UserMenu";

export const revalidate = 3600;

export default async function HomePage() {
  const courses = await db.course.findMany({
    orderBy: { createdAt: "asc" },
    include: { _count: { select: { videos: true } } },
  });

  return (
    <main className="flex-1">
      <header className="bg-crimson-900 border-b border-crimson-700 px-6 py-0">
        <div className="max-w-6xl mx-auto flex items-center justify-between">
          <Link href="/" className="flex items-center gap-3">
            <Image src="/logo.png" alt="The Timpson Lyceum seal" width={80} height={80} />
            <span className="font-display text-sm tracking-[0.2em] uppercase text-gold-300">
              The Timpson Lyceum
            </span>
          </Link>
          <nav className="flex items-center gap-6 font-display text-xs tracking-[0.15em] uppercase text-parchment-dim">
            <Link href="/" className="hover:text-gold-300 transition-colors">
              Courses
            </Link>
            <a
              href="https://www.youtube.com/@donaldDtimpson"
              target="_blank"
              rel="noopener noreferrer"
              className="hover:text-gold-300 transition-colors"
            >
              YouTube ↗
            </a>
            <UserMenu />
          </nav>
        </div>
      </header>

      <div className="bg-crimson-950 border-b border-crimson-800 px-6 py-16">
        <div className="flex items-center">
          <div className="w-[360px] flex-shrink-0">
            <Image
              src="/logo.png"
              alt="The Timpson Lyceum seal"
              width={360}
              height={360}
            />
          </div>
          <h1 className="flex-1 text-center font-display text-4xl md:text-5xl text-parchment leading-tight">
            A Classical Education in
            <br />
            Mathematics, Logic, and Philosophy.
          </h1>
          <div className="w-[360px] flex-shrink-0" />
        </div>
      </div>

      <section className="max-w-6xl mx-auto px-6 py-12">
        <h2 className="font-display text-lg tracking-[0.25em] uppercase text-gold-400 mb-8 pb-3 border-b border-crimson-700">
          Courses
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
    </main>
  );
}
