import { notFound } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { saveQuizAttempt } from "@/lib/actions";
import QuizPlayer from "../[videoId]/QuizPlayer";

export const dynamic = "force-dynamic";

export default async function PlaylistTestPage({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;

  const [course, session] = await Promise.all([
    db.course.findUnique({ where: { id: courseId } }),
    getServerSession(authOptions),
  ]);
  if (!course) notFound();

  const questions = await db.quizQuestion.findMany({
    where: { courseId, videoId: null, isDraft: false },
    orderBy: { position: "asc" },
  });

  if (questions.length === 0) {
    return (
      <main className="flex-1 flex items-center justify-center text-parchment-dim">
        No test questions for this course yet.
      </main>
    );
  }

  const userId = session?.user?.id ?? null;
  const saveAttempt = userId
    ? saveQuizAttempt.bind(null, null, courseId)
    : undefined;

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link
            href={`/courses/${courseId}`}
            className="text-sm text-parchment-dim hover:text-parchment transition-colors"
          >
            ← {course.title}
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <h1 className="text-2xl font-bold text-parchment">Playlist Test: {course.title}</h1>
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
    </main>
  );
}
