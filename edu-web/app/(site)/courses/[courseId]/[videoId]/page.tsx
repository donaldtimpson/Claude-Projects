import type { Metadata } from "next";
import { notFound } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { grammarLessonDrills } from "@/lib/drills/grammar";
import { getAcedLessonSlugs } from "@/lib/lessons";
import { nestComments } from "@/lib/comments";
import { saveQuizAttempt } from "@/lib/actions";
import { getQuizAces } from "@/lib/gamification/engine";
import QuizPlayer from "./QuizPlayer";
import QuizAces from "./QuizAces";
import MarkWatchedButton from "@/components/MarkWatchedButton";
import CommentSection from "@/components/CommentSection";
import VideoDescription from "@/components/VideoDescription";
import LectureNotes from "@/components/LectureNotes";

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
  searchParams,
}: {
  params: Promise<{ courseId: string; videoId: string }>;
  searchParams: Promise<{ t?: string }>;
}) {
  const { courseId, videoId } = await params;
  // ?t=<seconds> deep-links into the video (used by search transcript hits).
  const t = Number((await searchParams).t);
  const startParam = Number.isFinite(t) && t > 0 ? `?start=${Math.floor(t)}` : "";

  const [video, session] = await Promise.all([
    db.video.findUnique({ where: { id: videoId }, include: { course: true } }),
    getServerSession(authOptions),
  ]);

  if (!video || video.courseId !== courseId) notFound();

  const userId = session?.user?.id ?? null;

  const [questions, siblings, watched, comments, note] = await Promise.all([
    db.quizQuestion.findMany({ where: { videoId: video.id, isDraft: false }, orderBy: { position: "asc" } }),
    db.video.findMany({
      where: { courseId },
      // Chronological order so prev/next nav follows lecture order (see course page note).
      // Manual-order courses are re-sorted by position below.
      orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
      select: { id: true, title: true, position: true },
    }),
    userId
      ? db.videoProgress.findUnique({ where: { userId_videoId: { userId, videoId: video.id } } })
      : null,
    db.comment.findMany({
      where: { videoId: video.id },
      include: { user: { select: { id: true, name: true } } },
      orderBy: { createdAt: "asc" },
    }),
    db.lectureNote.findUnique({ where: { videoId: video.id } }),
  ]);

  // Problem sets tagged as covering this lecture. Many-to-many, so a lecture can
  // show more than one set and a set can appear on several lectures.
  const problemSets = (
    await db.problemSetVideo.findMany({
      where: { videoId: video.id, problemSet: { isDraft: false } },
      include: { problemSet: { select: { id: true, title: true, points: true } } },
    })
  ).map((link) => link.problemSet);

  // Lesson drills tagged as covering this lecture (VideoLesson). Same many-to-many
  // shape as problem sets, and they render in the same Practice section — from a
  // student's side "practice this lecture" is one idea, whether the practice is a
  // problem set or a drill. Aced state (✦) is server-derived, so it matches the
  // drills hub and the iOS app rather than being recomputed here.
  const lessonMeta = new Map(grammarLessonDrills.map((d) => [d.slug, d]));
  const lessonDrills = (
    await db.videoLesson.findMany({ where: { videoId: video.id }, select: { lessonSlug: true } })
  )
    .map((l) => lessonMeta.get(l.lessonSlug))
    .filter((d): d is NonNullable<typeof d> => Boolean(d));
  const acedLessons = new Set(
    userId && lessonDrills.length > 0 ? await getAcedLessonSlugs(userId) : [],
  );
  const hasPractice = problemSets.length > 0 || lessonDrills.length > 0;

  // Manual-order courses: prev/next nav follows the hand-arranged position.
  if (video.course.manualOrder) {
    siblings.sort((a, b) => a.position - b.position);
  }

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

  const hasNotes = !!note && !note.isDraft;
  const hasQuiz = questions.length > 0;

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
            src={`https://www.youtube.com/embed/${video.youtubeVideoId}${startParam}`}
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

        {/* In-page jump nav — skip straight to notes / quiz / discussion */}
        {(hasNotes || hasQuiz) && (
          <nav className="flex flex-wrap gap-2">
            {hasNotes && (
              <a
                href="#notes"
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors"
              >
                Notes
              </a>
            )}
            {hasQuiz && (
              <a
                href="#quiz"
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors"
              >
                Quiz
              </a>
            )}
            {hasPractice && (
              <a
                href="#practice"
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors"
              >
                Practice
              </a>
            )}
            <a
              href="#discussion"
              className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors"
            >
              Discussion
            </a>
          </nav>
        )}

        {/* Problem sets and lesson drills covering this lecture. */}
        {hasPractice && (
          <section id="practice" className="scroll-mt-24 space-y-4">
            <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
              Practice
            </h2>
            <ul className="space-y-2">
              {problemSets.map((ps) => (
                <li key={ps.id}>
                  <Link
                    href={`/courses/${courseId}/problems/${ps.id}`}
                    className="flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-xl px-5 py-3 transition-colors group"
                  >
                    <span className="min-w-0">
                      <span className="block font-medium text-parchment group-hover:text-gold-300 transition-colors">
                        {ps.title}
                      </span>
                      <span className="block text-xs text-parchment-dim mt-0.5">
                        Problems with worked solutions
                        {ps.points > 0 && ` · ${ps.points} pts`}
                      </span>
                    </span>
                    <span className="text-parchment-dim group-hover:text-gold-300 transition-colors shrink-0">
                      →
                    </span>
                  </Link>
                </li>
              ))}
              {lessonDrills.map((d) => {
                const aced = acedLessons.has(d.slug);
                return (
                  <li key={d.slug}>
                    <Link
                      href={`/drills/${d.slug}`}
                      className="flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-xl px-5 py-3 transition-colors group"
                    >
                      <span className="min-w-0">
                        <span className="block font-medium text-parchment group-hover:text-gold-300 transition-colors">
                          {d.title}
                        </span>
                        <span className="block text-xs text-parchment-dim mt-0.5">
                          {d.blurb}
                        </span>
                      </span>
                      <span className="flex items-center gap-3 shrink-0">
                        {aced && (
                          <span className="font-display text-[0.65rem] tracking-[0.15em] uppercase text-gold-300">
                            ✦ Aced
                          </span>
                        )}
                        <span className="text-parchment-dim group-hover:text-gold-300 transition-colors">
                          →
                        </span>
                      </span>
                    </Link>
                  </li>
                );
              })}
            </ul>
          </section>
        )}

        {/* Lecture notes (only when published) */}
        {note && !note.isDraft && (
          <div id="notes" className="scroll-mt-24">
            <LectureNotes content={note.content} printHref={`/courses/${courseId}/${video.id}/notes`} />
          </div>
        )}

        {/* Quiz */}
        {questions.length > 0 && (
          <div id="quiz" className="scroll-mt-24">
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
          </div>
        )}

        {/* Hall of Aces */}
        {questions.length > 0 && <QuizAces acers={aces} myUserId={userId} />}

        {/* Comments */}
        <div id="discussion" className="scroll-mt-24">
          <CommentSection
            videoId={video.id}
            userId={userId}
            userName={session?.user?.name ?? null}
            initialComments={nestComments(comments)}
          />
        </div>

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
