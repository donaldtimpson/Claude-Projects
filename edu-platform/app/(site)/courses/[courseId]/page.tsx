import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { RESOURCE_KIND_LABELS } from "@/lib/resource-kinds";

export const dynamic = "force-dynamic";

function formatDuration(secs: number) {
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export default async function CoursePage({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;

  const [course, session] = await Promise.all([
    db.course.findUnique({
      where: { id: courseId },
      include: {
        videos: { orderBy: { position: "asc" } },
        _count: { select: { quizQuestions: true } },
        resources: {
          include: { resource: true },
          orderBy: [{ position: "asc" }, { resource: { kind: "asc" } }],
        },
      },
    }),
    getServerSession(authOptions),
  ]);

  if (!course) notFound();

  const userId = session?.user?.id ?? null;
  const watchedSet = new Set<string>();
  if (userId) {
    const progress = await db.videoProgress.findMany({
      where: { userId, videoId: { in: course.videos.map((v) => v.id) } },
      select: { videoId: true },
    });
    progress.forEach((p) => watchedSet.add(p.videoId));
  }

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-parchment mb-2">{course.title}</h1>
          <p className="text-parchment-dim">
            {course.videos.length} video{course.videos.length !== 1 ? "s" : ""}
            {userId && watchedSet.size > 0 && (
              <span className="ml-2 text-green-400">
                · {watchedSet.size} watched
              </span>
            )}
          </p>
          {course.description && (
            <p className="mt-3 text-parchment-dim leading-relaxed">{course.description}</p>
          )}
          {course._count.quizQuestions > 0 && (
            <Link
              href={`/courses/${course.id}/test`}
              className="inline-block mt-4 px-5 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
            >
              Take Playlist Test ({course._count.quizQuestions} questions)
            </Link>
          )}
        </div>

        {course.resources.length > 0 && (
          <section className="mb-8">
            <h2 className="text-sm uppercase tracking-wider text-parchment-dim mb-3">Resources</h2>
            <ul className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {course.resources.map(({ resource }) => (
                <li key={resource.id}>
                  <a
                    href={resource.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-xl p-4 transition-colors group h-full"
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <p className="font-medium text-parchment group-hover:text-gold-300 transition-colors truncate">
                          {resource.title}
                        </p>
                        <p className="text-xs text-parchment-dim mt-0.5">
                          {resource.description || RESOURCE_KIND_LABELS[resource.kind]}
                        </p>
                      </div>
                      <span className="text-parchment-dim group-hover:text-gold-300 transition-colors shrink-0">↗</span>
                    </div>
                  </a>
                </li>
              ))}
            </ul>
          </section>
        )}

        <ol className="space-y-3">
          {course.videos.map((video, idx) => {
            const isWatched = watchedSet.has(video.id);
            return (
              <li key={video.id}>
                <Link
                  href={`/courses/${course.id}/${video.id}`}
                  className="group flex gap-4 items-start bg-crimson-900 border border-crimson-700 rounded-xl p-4 hover:border-gold-500 transition-colors"
                >
                  <span className="text-parchment-dim text-sm w-6 shrink-0 mt-0.5">{idx + 1}</span>
                  {video.thumbnailUrl ? (
                    <div className="relative w-32 aspect-video shrink-0 rounded-md overflow-hidden">
                      <Image src={video.thumbnailUrl} alt={video.title} fill className="object-cover" />
                    </div>
                  ) : (
                    <div className="w-32 aspect-video shrink-0 bg-crimson-800 rounded-md" />
                  )}
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-parchment group-hover:text-gold-300 transition-colors line-clamp-2">
                      {video.title}
                    </p>
                    {video.durationSeconds > 0 && (
                      <p className="text-xs text-parchment-dim mt-1">{formatDuration(video.durationSeconds)}</p>
                    )}
                  </div>
                  {isWatched && (
                    <span className="shrink-0 text-green-400 text-sm self-center" title="Watched">✓</span>
                  )}
                </Link>
              </li>
            );
          })}
        </ol>
      </div>
    </main>
  );
}
