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
  if (!ps || ps.courseId !== courseId || ps.isDraft) notFound();

  // Sibling problem sets (published only) for prev/next nav — same order as the
  // course page lists them (oldest first).
  const siblings = await db.problemSet.findMany({
    where: { courseId, isDraft: false },
    orderBy: { createdAt: "asc" },
    select: { id: true, title: true },
  });
  const currentIdx = siblings.findIndex((s) => s.id === ps.id);
  const prevSet = currentIdx > 0 ? siblings[currentIdx - 1] : null;
  const nextSet =
    currentIdx >= 0 && currentIdx < siblings.length - 1 ? siblings[currentIdx + 1] : null;

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

        {/* Prev / Next navigation — matches the lecture page's quick nav buttons */}
        {(prevSet || nextSet) && (
          <div className="flex items-center justify-between gap-3 pt-4 border-t border-crimson-700">
            {prevSet ? (
              <Link
                href={`/courses/${courseId}/problems/${prevSet.id}`}
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-4 py-2 transition-colors"
              >
                ← Previous
              </Link>
            ) : (
              <span />
            )}
            {nextSet ? (
              <Link
                href={`/courses/${courseId}/problems/${nextSet.id}`}
                className="font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-4 py-2 transition-colors"
              >
                Next →
              </Link>
            ) : (
              <span />
            )}
          </div>
        )}
      </div>
    </main>
  );
}
