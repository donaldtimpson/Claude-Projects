import { notFound } from "next/navigation";
import Link from "next/link";
import { db } from "@/lib/db";
import QuizPlayer from "./QuizPlayer";

export const revalidate = 3600;

export default async function VideoPage({
  params,
}: {
  params: Promise<{ courseId: string; videoId: string }>;
}) {
  const { courseId, videoId } = await params;
  const video = await db.video.findUnique({
    where: { id: videoId },
    include: { course: true },
  });

  if (!video || video.courseId !== courseId) notFound();

  const questions = await db.quizQuestion.findMany({
    where: { videoId: video.id },
    orderBy: { position: "asc" },
  });

  const [prevVideo, nextVideo] = await Promise.all([
    db.video.findFirst({
      where: { courseId, position: { lt: video.position } },
      orderBy: { position: "desc" },
      select: { id: true, title: true },
    }),
    db.video.findFirst({
      where: { courseId, position: { gt: video.position } },
      orderBy: { position: "asc" },
      select: { id: true, title: true },
    }),
  ]);

  return (
    <main className="flex-1">
      <header className="border-b border-slate-800 px-6 py-4">
        <div className="max-w-5xl mx-auto">
          <Link
            href={`/courses/${courseId}`}
            className="text-sm text-slate-400 hover:text-slate-200 transition-colors"
          >
            ← {video.course.title}
          </Link>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-6 py-8 space-y-8">
        {/* Video embed */}
        <div className="aspect-video w-full rounded-xl overflow-hidden bg-black">
          <iframe
            src={`https://www.youtube.com/embed/${video.youtubeVideoId}`}
            title={video.title}
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowFullScreen
            className="w-full h-full"
          />
        </div>

        <div>
          <h1 className="text-2xl font-bold text-white">{video.title}</h1>
          {video.description && (
            <p className="mt-3 text-slate-400 leading-relaxed whitespace-pre-line">
              {video.description}
            </p>
          )}
        </div>

        {/* Quiz */}
        {questions.length > 0 && (
          <QuizPlayer
            questions={questions.map((q) => ({
              id: q.id,
              prompt: q.prompt,
              options: q.options as string[],
              correctIndex: q.correctIndex,
              explanation: q.explanation,
            }))}
          />
        )}

        {/* Prev / Next navigation */}
        <div className="flex justify-between gap-4 pt-4 border-t border-slate-800">
          {prevVideo ? (
            <Link
              href={`/courses/${courseId}/${prevVideo.id}`}
              className="text-sm text-slate-400 hover:text-white transition-colors"
            >
              ← {prevVideo.title}
            </Link>
          ) : (
            <span />
          )}
          {nextVideo && (
            <Link
              href={`/courses/${courseId}/${nextVideo.id}`}
              className="text-sm text-slate-400 hover:text-white transition-colors text-right"
            >
              {nextVideo.title} →
            </Link>
          )}
        </div>
      </div>
    </main>
  );
}
