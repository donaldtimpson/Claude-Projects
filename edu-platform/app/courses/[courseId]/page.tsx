import Link from "next/link";
import Image from "next/image";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";

export const revalidate = 3600;

function formatDuration(secs: number) {
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export default async function CoursePage({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    include: {
      videos: { orderBy: { position: "asc" } },
      _count: { select: { quizQuestions: true } },
    },
  });

  if (!course) notFound();

  return (
    <main className="flex-1">
      <header className="border-b border-slate-800 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/" className="text-sm text-slate-400 hover:text-slate-200 transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-white mb-2">{course.title}</h1>
          <p className="text-slate-400">
            {course.videos.length} video{course.videos.length !== 1 ? "s" : ""}
          </p>
          {course.description && (
            <p className="mt-3 text-slate-300 leading-relaxed">{course.description}</p>
          )}
          {course._count.quizQuestions > 0 && (
            <Link
              href={`/courses/${course.id}/test`}
              className="inline-block mt-4 px-5 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium rounded-lg transition-colors"
            >
              Take Playlist Test ({course._count.quizQuestions} questions)
            </Link>
          )}
        </div>

        <ol className="space-y-3">
          {course.videos.map((video, idx) => (
            <li key={video.id}>
              <Link
                href={`/courses/${course.id}/${video.id}`}
                className="group flex gap-4 items-start bg-slate-900 border border-slate-800 rounded-xl p-4 hover:border-indigo-500 transition-colors"
              >
                <span className="text-slate-600 text-sm w-6 shrink-0 mt-0.5">{idx + 1}</span>
                {video.thumbnailUrl ? (
                  <div className="relative w-32 aspect-video shrink-0 rounded-md overflow-hidden">
                    <Image src={video.thumbnailUrl} alt={video.title} fill className="object-cover" />
                  </div>
                ) : (
                  <div className="w-32 aspect-video shrink-0 bg-slate-800 rounded-md" />
                )}
                <div className="flex-1 min-w-0">
                  <p className="font-medium text-white group-hover:text-indigo-300 transition-colors line-clamp-2">
                    {video.title}
                  </p>
                  {video.durationSeconds > 0 && (
                    <p className="text-xs text-slate-500 mt-1">{formatDuration(video.durationSeconds)}</p>
                  )}
                </div>
              </Link>
            </li>
          ))}
        </ol>
      </div>
    </main>
  );
}
