import { notFound } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { recordReviewCleared } from "@/lib/actions";
import CourseReviewPlayer from "./CourseReviewPlayer";

export const dynamic = "force-dynamic";

export default async function CourseReviewPage({
  params,
}: {
  params: Promise<{ courseId: string }>;
}) {
  const { courseId } = await params;

  const [course, session] = await Promise.all([
    db.course.findUnique({
      where: { id: courseId },
      include: {
        videos: {
          orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
          include: {
            quizQuestions: {
              where: { isDraft: false },
              orderBy: { position: "asc" },
            },
          },
        },
        quizQuestions: {
          where: { videoId: null, isDraft: false },
          orderBy: { position: "asc" },
        },
      },
    }),
    getServerSession(authOptions),
  ]);
  if (!course) notFound();

  // Manual-order courses: pool questions in the hand-arranged lecture order.
  if (course.manualOrder) {
    course.videos.sort((a, b) => a.position - b.position);
  }

  // Flatten the full pool: every published per-lecture question, then the course test.
  const pool = [
    ...course.videos.flatMap((v) =>
      v.quizQuestions.map((qq) => ({
        id: qq.id,
        prompt: qq.prompt,
        options: qq.options as string[],
        correctIndex: qq.correctIndex,
        explanation: qq.explanation,
        source: v.title,
      })),
    ),
    ...course.quizQuestions.map((qq) => ({
      id: qq.id,
      prompt: qq.prompt,
      options: qq.options as string[],
      correctIndex: qq.correctIndex,
      explanation: qq.explanation,
      source: "Course Test",
    })),
  ];

  const onCleared = session?.user?.id
    ? recordReviewCleared.bind(null, courseId)
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
        <h1 className="text-2xl font-bold text-parchment">Review: {course.title}</h1>
        {pool.length === 0 ? (
          <p className="text-parchment-dim">No published questions to review yet.</p>
        ) : (
          <CourseReviewPlayer questions={pool} onCleared={onCleared} />
        )}
      </div>
    </main>
  );
}
