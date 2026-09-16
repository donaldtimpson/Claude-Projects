import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import QuizEditor from "../../../QuizEditor";

// Test tab: the end-of-playlist test questions (courseId set, videoId null).
export default async function AdminCourseTest({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({ where: { id: courseId }, select: { id: true } });
  if (!course) notFound();

  const questions = await db.quizQuestion.findMany({
    where: { courseId, videoId: null },
    orderBy: { position: "asc" },
  });

  return (
    <div className="space-y-4">
      <p className="text-sm text-parchment-dim">
        These questions appear on the end-of-playlist test, not on individual videos.
      </p>
      <QuizEditor
        courseId={course.id}
        initialQuestions={questions.map((q) => ({
          id: q.id,
          prompt: q.prompt,
          options: q.options as string[],
          correctIndex: q.correctIndex,
          explanation: q.explanation,
          position: q.position,
          isDraft: q.isDraft,
        }))}
      />
    </div>
  );
}
