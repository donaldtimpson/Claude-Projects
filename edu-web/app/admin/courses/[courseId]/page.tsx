import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import CurrentToggle from "../../CurrentToggle";
import LectureRow from "./LectureRow";
import LectureOrderEditor from "./LectureOrderEditor";

export default async function AdminCourseHub({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    include: {
      videos: { orderBy: { position: "asc" } },
      _count: { select: { quizQuestions: true, linksFrom: true, linksTo: true } },
    },
  });
  if (!course) notFound();

  const videoIds = course.videos.map((v) => v.id);
  const [allQuestions, allNotes] = await Promise.all([
    db.quizQuestion.findMany({ where: { videoId: { in: videoIds } }, orderBy: { position: "asc" } }),
    db.lectureNote.findMany({ where: { videoId: { in: videoIds } } }),
  ]);

  const testCount = course._count.quizQuestions;
  const connectionCount = course._count.linksFrom + course._count.linksTo;

  const actionBtn =
    "text-sm text-gold-400 hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors";

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <div className="flex items-start justify-between gap-4 mt-3">
          <h1 className="text-2xl font-bold text-parchment">{course.title}</h1>
        </div>

        {/* Top-level course actions */}
        <div className="flex flex-wrap items-center gap-3 mt-4">
          <CurrentToggle courseId={course.id} initial={course.isCurrent} />
          <Link href={`/admin/links/${course.id}`} className={actionBtn}>
            Connections{connectionCount > 0 ? ` (${connectionCount})` : ""} →
          </Link>
          <Link href={`/admin/test/${course.id}`} className={actionBtn}>
            Edit Test{testCount > 0 ? ` (${testCount})` : ""} →
          </Link>
        </div>
      </div>

      {course.videos.length > 1 && (
        <LectureOrderEditor
          courseId={course.id}
          initialManualOrder={course.manualOrder}
          lectures={course.videos.map((v) => ({ id: v.id, title: v.title }))}
        />
      )}

      <section className="space-y-3">
        <h2 className="font-display text-sm tracking-[0.15em] uppercase text-parchment-dim">Lectures</h2>
        {course.videos.map((video, idx) => {
          const questions = allQuestions
            .filter((q) => q.videoId === video.id)
            .map((q) => ({
              id: q.id,
              prompt: q.prompt,
              options: q.options as string[],
              correctIndex: q.correctIndex,
              explanation: q.explanation,
              position: q.position,
              isDraft: q.isDraft,
            }));
          const noteRow = allNotes.find((n) => n.videoId === video.id);
          return (
            <LectureRow
              key={video.id}
              index={idx + 1}
              title={video.title}
              videoId={video.id}
              printHref={`/courses/${courseId}/${video.id}/notes`}
              initialNote={noteRow ? { id: noteRow.id, content: noteRow.content, isDraft: noteRow.isDraft } : null}
              initialQuestions={questions}
            />
          );
        })}
      </section>
    </main>
  );
}
