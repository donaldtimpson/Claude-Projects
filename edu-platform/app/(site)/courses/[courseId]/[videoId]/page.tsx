import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { saveQuizAttempt } from "@/lib/actions";
import { getQuizAces } from "@/lib/gamification/engine";
import QuizPlayer from "./QuizPlayer";
import QuizAces from "./QuizAces";
import MarkWatchedButton from "@/components/MarkWatchedButton";
import CommentSection from "@/components/CommentSection";
import VideoDescription from "@/components/VideoDescription";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ courseId: string; videoId: string }>;
}): Promise<Metadata> {
  const { courseId, videoId } = await params;
  const video = await db.video.findUnique({
    where: { id: videoId },
    select: {
      courseId: true,
      title: true,
      description: true,
      thumbnailUrl: true,
      course: { select: { title: true } },
    },
  });
  if (!video || video.courseId !== courseId) return {};

  const description =
    video.description?.trim().slice(0, 200) || `A lecture from ${video.course.title} at The Timpson Lyceum.`;
  // Per-lecture share card: use the video's own thumbnail so Facebook/X/etc.
  // show that lecture. Falls back to the site default (root opengraph-image).
  const image = video.thumbnailUrl || undefined;

  return {
    title: video.title,
    description,
    openGraph: {
      type: "video.other",
      title: video.title,
      description,
      ...(image ? { images: [image] } : {}),
    },
    twitter: {
      card: "summary_large_image",
      title: video.title,
      description,
      ...(image ? { images: [image] } : {}),
    },
  };
}

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
      // Chronological order so prev/next nav follows lecture order (see course page note).
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

  const aces = questions.length > 0 ? await getQuizAces(video.id) : [];

  // On the last lecture the "Next" slot becomes a "Take Test" CTA — but only if
  // the course actually has a published playlist test.
  const hasTest =
    !nextVideo &&
    (await db.quizQuestion.count({ where: { courseId, videoId: null, isDraft: false } })) > 0;

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

        {/* Quick lecture nav — directly under the video so there's no need to scroll */}
        {(prevVideo || nextVideo) && (
          <div className="flex items-center justify-between gap-3">
            {prevVideo ? (
              <Link
                href={`/courses/${courseId}/${prevVideo.id}`}
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-4 py-2 transition-colors"
              >
                ← Previous
              </Link>
            ) : (
              <span />
            )}
            {nextVideo ? (
              <Link
                href={`/courses/${courseId}/${nextVideo.id}`}
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-4 py-2 transition-colors"
              >
                Next →
              </Link>
            ) : hasTest ? (
              <Link
                href={`/courses/${courseId}/test`}
                className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 font-semibold rounded-lg px-4 py-2 transition-colors"
              >
                Take Test →
              </Link>
            ) : (
              <span />
            )}
          </div>
        )}

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

        {/* Hall of Aces */}
        {questions.length > 0 && <QuizAces acers={aces} myUserId={userId} />}

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
