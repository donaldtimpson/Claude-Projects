import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ProblemSetView from "@/components/ProblemSetView";
import { pairProblemSet, canSeeSolutions } from "@/lib/problem-sets";

export const dynamic = "force-dynamic";

// Public problem-set page. Anyone can read the problems, and the worked
// solutions render inline with them (collapsed per problem) unless the set has
// been explicitly withheld. Only enrolled students (on the course page) get a
// submit box for the corresponding assignment.
export default async function ProblemSetPage({
  params,
}: {
  params: Promise<{ courseId: string; problemSetId: string }>;
}) {
  const { courseId, problemSetId } = await params;
  const ps = await db.problemSet.findUnique({
    where: { id: problemSetId },
    include: {
      course: { select: { id: true, title: true } },
      videos: {
        include: { video: { select: { id: true, title: true, position: true } } },
      },
    },
  });
  if (!ps || ps.courseId !== courseId || ps.isDraft) notFound();

  const showSolutions =
    canSeeSolutions({ solutionsPublic: ps.solutionsPublic }) &&
    ps.solution.trim().length > 0;
  const paired = pairProblemSet(ps.body, ps.solution, showSolutions);

  const lectures = ps.videos
    .map((v) => v.video)
    .sort((a, b) => a.position - b.position);

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
        <div className="space-y-3">
          <h1 className="text-3xl font-bold text-parchment">{ps.title}</h1>
          {(ps.points > 0 || ps.extraCreditPoints > 0) && (
            <p className="text-xs text-parchment-dim">
              {ps.points} points
              {ps.extraCreditPoints > 0 && ` · ${ps.extraCreditPoints} extra credit`}
            </p>
          )}
        </div>

        {/* Which lectures this set practices — a set follows a chapter, so this
            is usually a span rather than a single lecture. */}
        {lectures.length > 0 && (
          <div className="flex items-center gap-2 flex-wrap">
            <span className="font-display text-[0.65rem] tracking-[0.2em] uppercase text-gold-400">
              Covers
            </span>
            {lectures.map((v) => (
              <Link
                key={v.id}
                href={`/courses/${courseId}/${v.id}`}
                className="text-xs text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-full px-3 py-1 transition-colors"
              >
                {v.title}
              </Link>
            ))}
          </div>
        )}

        <div className="flex items-center gap-2 flex-wrap">
          {ps.attachmentUrl && (
            <a
              href={ps.attachmentUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="px-5 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
            >
              Open attachment ↗
            </a>
          )}
          {/* Homework gets done on paper — offer a clean sheet to work from and,
              separately, an answer key. */}
          <a
            href={`/courses/${courseId}/problems/${ps.id}/print`}
            target="_blank"
            rel="noopener noreferrer"
            className="font-display text-[0.65rem] tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-2 transition-colors"
          >
            Print problems
          </a>
          {showSolutions && (
            <a
              href={`/courses/${courseId}/problems/${ps.id}/print?solutions=1`}
              target="_blank"
              rel="noopener noreferrer"
              className="font-display text-[0.65rem] tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-2 transition-colors"
            >
              Print with solutions
            </a>
          )}
        </div>

        <ProblemSetView data={paired} />

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
