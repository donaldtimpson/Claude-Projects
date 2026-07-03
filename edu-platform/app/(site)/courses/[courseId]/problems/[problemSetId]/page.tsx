import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import MarkdownNotes from "@/components/MarkdownNotes";

export const dynamic = "force-dynamic";

// Public problem-set page. Anyone can read the problems; only enrolled students
// (on the course page) get a submit box for the corresponding assignment.
export default async function ProblemSetPage({
  params,
}: {
  params: Promise<{ courseId: string; problemSetId: string }>;
}) {
  const { courseId, problemSetId } = await params;
  const ps = await db.problemSet.findUnique({
    where: { id: problemSetId },
    include: { course: { select: { id: true, title: true } } },
  });
  if (!ps || ps.courseId !== courseId) notFound();

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link
            href={`/courses/${ps.course.id}`}
            className="text-sm text-parchment-dim hover:text-parchment transition-colors"
          >
            ← {ps.course.title}
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <h1 className="text-3xl font-bold text-parchment">{ps.title}</h1>

        {ps.attachmentUrl && (
          <a
            href={ps.attachmentUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block px-5 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
          >
            Open attachment ↗
          </a>
        )}

        {ps.body.trim() ? (
          <MarkdownNotes content={ps.body} />
        ) : (
          <p className="text-parchment-dim">See the attachment above for the problems.</p>
        )}
      </div>
    </main>
  );
}
