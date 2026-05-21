import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import QuizEditor from "../../QuizEditor";

export default async function AdminCourseQuizzes({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    include: { videos: { orderBy: [{ publishedAt: "asc" }, { position: "asc" }] } },
  });
  if (!course) notFound();

  const allQuestions = await db.quizQuestion.findMany({
    where: { videoId: { in: course.videos.map((v) => v.id) } },
    orderBy: { position: "asc" },
  });

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-10">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">{course.title} — Video Quizzes</h1>
      </div>

      {course.videos.map((video, idx) => {
        const questions = allQuestions.filter((q) => q.videoId === video.id);
        return (
          <section key={video.id} className="space-y-4">
            <div className="flex items-center justify-between">
              <h2 className="font-semibold text-parchment">
                <span className="text-parchment-dim mr-2">{idx + 1}.</span>
                {video.title}
              </h2>
              <span className="text-xs text-parchment-dim">{questions.length} question{questions.length !== 1 ? "s" : ""}</span>
            </div>
            <QuizEditor
              videoId={video.id}
              initialQuestions={questions.map((q) => ({
                id: q.id,
                prompt: q.prompt,
                options: q.options as string[],
                correctIndex: q.correctIndex,
                explanation: q.explanation,
                position: q.position,
              }))}
            />
          </section>
        );
      })}
    </main>
  );
}
