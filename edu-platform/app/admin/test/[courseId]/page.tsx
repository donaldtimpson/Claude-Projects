import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import QuizEditor from "../../QuizEditor";

export default async function AdminPlaylistTest({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({ where: { id: courseId } });
  if (!course) notFound();

  const questions = await db.quizQuestion.findMany({
    where: { courseId, videoId: null },
    orderBy: { position: "asc" },
  });

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">{course.title} — Playlist Test</h1>
        <p className="text-sm text-parchment-dim mt-1">
          These questions appear on the end-of-playlist test, not on individual videos.
        </p>
      </div>

      <QuizEditor
        courseId={course.id}
        initialQuestions={questions.map((q) => ({
          id: q.id,
          prompt: q.prompt,
          options: q.options as string[],
          correctIndex: q.correctIndex,
          explanation: q.explanation,
          position: q.position,
        }))}
      />
    </main>
  );
}
