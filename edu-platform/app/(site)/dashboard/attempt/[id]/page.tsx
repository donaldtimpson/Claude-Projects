import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import AttemptReview from "@/components/AttemptReview";

export const dynamic = "force-dynamic";

function pct(score: number, total: number) {
  return Math.round((score / total) * 100);
}

function scoreColor(p: number) {
  if (p === 100) return "text-green-400";
  if (p >= 70) return "text-gold-400";
  return "text-red-400";
}

export default async function AttemptPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) redirect("/auth/signin");

  const { id } = await params;
  const attempt = await db.quizAttempt.findUnique({
    where: { id },
    include: {
      video: {
        select: {
          id: true,
          title: true,
          courseId: true,
          course: { select: { id: true, title: true } },
        },
      },
      course: { select: { id: true, title: true } },
    },
  });

  if (!attempt || attempt.userId !== session.user.id) notFound();

  // Load the questions for this attempt
  const questions = attempt.videoId
    ? await db.quizQuestion.findMany({
        where: { videoId: attempt.videoId },
        orderBy: { position: "asc" },
      })
    : await db.quizQuestion.findMany({
        where: { courseId: attempt.courseId ?? undefined, videoId: null },
        orderBy: { position: "asc" },
      });

  const storedAnswers = Array.isArray(attempt.answers)
    ? (attempt.answers as (number | null)[])
    : Array(questions.length).fill(null);

  const isVideoQuiz = !!attempt.videoId;
  const courseId = attempt.video?.courseId ?? attempt.video?.course?.id ?? attempt.course?.id;
  const videoId = attempt.video?.id;
  const title = isVideoQuiz ? attempt.video?.title : attempt.course?.title;
  const courseTitle = attempt.video?.course?.title ?? attempt.course?.title;

  const p = pct(attempt.score, attempt.totalQuestions);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link
            href="/dashboard"
            className="text-sm text-parchment-dim hover:text-parchment transition-colors"
          >
            ← My Progress
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-8">
        {/* Header */}
        <div className="space-y-1">
          {courseTitle && courseId && (
            <Link
              href={isVideoQuiz && videoId ? `/courses/${courseId}/${videoId}` : `/courses/${courseId}`}
              className="text-sm text-parchment-dim hover:text-gold-300 transition-colors"
            >
              {courseTitle}
            </Link>
          )}
          <h1 className="text-xl font-bold text-parchment">{title ?? "Quiz"}</h1>
          <p className="text-xs text-parchment-dim">
            {attempt.completedAt.toLocaleDateString("en-US", {
              month: "long",
              day: "numeric",
              year: "numeric",
            })}
          </p>
        </div>

        {/* Score summary */}
        <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 flex items-center gap-6">
          <p className={`text-4xl font-bold ${scoreColor(p)}`}>
            {attempt.score}/{attempt.totalQuestions}
          </p>
          <div>
            <p className={`text-lg font-semibold ${scoreColor(p)}`}>{p}%</p>
            <p className="text-sm text-parchment-dim">
              {p === 100
                ? "Perfect score!"
                : p >= 70
                ? "Good work — review the ones you missed."
                : "Keep studying and try again."}
            </p>
          </div>
        </div>

        {/* Full review */}
        <div className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Answer Review
          </h2>
          {questions.length > 0 ? (
            <AttemptReview
              questions={questions.map((q) => ({
                id: q.id,
                prompt: q.prompt,
                options: q.options as string[],
                correctIndex: q.correctIndex,
                explanation: q.explanation,
              }))}
              answers={storedAnswers}
            />
          ) : (
            <p className="text-parchment-dim text-sm">
              Questions for this quiz are no longer available.
            </p>
          )}
        </div>
      </div>
    </main>
  );
}
