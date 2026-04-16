import { notFound } from "next/navigation";
import Link from "next/link";
import { db } from "@/lib/db";
import QuizPlayer from "../[videoId]/QuizPlayer";

export const revalidate = 3600;

export default async function PlaylistTestPage({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
  });
  if (!course) notFound();

  const questions = await db.quizQuestion.findMany({
    where: { courseId, videoId: null },
    orderBy: { position: "asc" },
  });

  if (questions.length === 0) {
    return (
      <main className="flex-1 flex items-center justify-center text-slate-400">
        No test questions for this course yet.
      </main>
    );
  }

  return (
    <main className="flex-1">
      <header className="border-b border-slate-800 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link
            href={`/courses/${courseId}`}
            className="text-sm text-slate-400 hover:text-slate-200 transition-colors"
          >
            ← {course.title}
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <h1 className="text-2xl font-bold text-white">Playlist Test: {course.title}</h1>
        <QuizPlayer
          questions={questions.map((q) => ({
            id: q.id,
            prompt: q.prompt,
            options: q.options as string[],
            correctIndex: q.correctIndex,
            explanation: q.explanation,
          }))}
        />
      </div>
    </main>
  );
}
