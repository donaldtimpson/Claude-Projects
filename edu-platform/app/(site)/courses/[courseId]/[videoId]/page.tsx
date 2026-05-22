import { notFound } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { saveQuizAttempt } from "@/lib/actions";
import QuizPlayer from "./QuizPlayer";
import MarkWatchedButton from "@/components/MarkWatchedButton";
import CommentSection from "@/components/CommentSection";
import VideoDescription from "@/components/VideoDescription";

export const dynamic = "force-dynamic";

export default async function VideoPage({
  params,
}: {
  params: Promise<{ courseId: string; videoId: string }>;
}) {
  const { courseId, videoId } = await params;

  const [video, session] = await Promise.all([
    db.video.findUnique({ where: { id: videoId }, include: { course: true } }),
    getServerSession(authOptions),
  ]);

  if (!video || video.courseId !== courseId) notFound();

  const userId = session?.user?.id ?? null;

  const [questions, siblings, watched, comments] = await Promise.all([
    db.quizQuestion.findMany({ where: { videoId: video.id, isDraft: false }, orderBy: { position: "asc" } }),
    db.video.findMany({
      where: { courseId },
      orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
      select: { id: true, title: true },
    }),
    userId
      ? db.videoProgress.findUnique({ where: { userId_videoId: { userId, videoId: video.id } } })
      : null,
    db.comment.findMany({
      where: { videoId: video.id },
      include: { user: { select: { id: true, name: true } } },
      orderBy: { createdAt: "asc" },
    }),
  ]);

  const currentIdx = siblings.findIndex((v) => v.id === video.id);
  const prevVideo = currentIdx > 0 ? siblings[currentIdx - 1] : null;
  const nextVideo = currentIdx >= 0 && currentIdx < siblings.length - 1 ? siblings[currentIdx + 1] : null;

  // Bind videoId+courseId so client only passes (score, total)
  const saveAttempt = userId
    ? saveQuizAttempt.bind(null, video.id, null)
    : undefined;

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-5xl mx-auto">
          <Link
            href={`/courses/${courseId}`}
            className="text-sm text-parchment-dim hover:text-parchment transition-colors"
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

        <div className="flex items-start justify-between gap-4">
          <div className="flex-1">
            <h1 className="text-2xl font-bold text-parchment">{video.title}</h1>
            {video.description && <VideoDescription text={video.description} />}
          </div>
          {userId && (
            <div className="flex-shrink-0 pt-1">
              <MarkWatchedButton videoId={video.id} initialWatched={!!watched} />
            </div>
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
            onAttemptComplete={saveAttempt}
          />
        )}

        {/* Comments */}
        <CommentSection
          videoId={video.id}
          userId={userId}
          userName={session?.user?.name ?? null}
          initialComments={comments.map((c) => ({
            id: c.id,
            body: c.body,
            createdAt: c.createdAt.toISOString(),
            user: { id: c.user.id, name: c.user.name ?? "Student" },
          }))}
        />

        {/* Prev / Next navigation */}
        <div className="flex justify-between gap-4 pt-4 border-t border-crimson-700">
          {prevVideo ? (
            <Link
              href={`/courses/${courseId}/${prevVideo.id}`}
              className="text-sm text-parchment-dim hover:text-parchment transition-colors"
            >
              ← {prevVideo.title}
            </Link>
          ) : (
            <span />
          )}
          {nextVideo && (
            <Link
              href={`/courses/${courseId}/${nextVideo.id}`}
              className="text-sm text-parchment-dim hover:text-parchment transition-colors text-right"
            >
              {nextVideo.title} →
            </Link>
          )}
        </div>
      </div>
    </main>
  );
}
