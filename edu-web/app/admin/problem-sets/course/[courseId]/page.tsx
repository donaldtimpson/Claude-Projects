import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { createProblemSet } from "@/lib/assignments";

export const dynamic = "force-dynamic";

// Admin: all problem sets for one course, in creation order (matches the public
// course-page ordering). Create form is pre-scoped to this course.
export default async function CourseProblemSetsPage({
  params,
}: {
  params: Promise<{ courseId: string }>;
}) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: { id: true, title: true, isCurrent: true },
  });
  if (!course) notFound();

  const problemSets = await db.problemSet.findMany({
    where: { courseId },
    orderBy: { createdAt: "asc" },
    select: {
      id: true,
      title: true,
      isDraft: true,
      _count: { select: { assignments: true } },
    },
  });

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin/problem-sets" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Problem Sets
        </Link>
        <div className="flex items-center gap-2 flex-wrap mt-2">
          <h1 className="text-2xl font-bold text-parchment">{course.title}</h1>
          {course.isCurrent && (
            <span className="text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border bg-gold-900/30 border-gold-700 text-gold-300">
              Current
            </span>
          )}
        </div>
        <p className="text-sm text-parchment-dim mt-1">
          {problemSets.length} problem set{problemSets.length === 1 ? "" : "s"}. Problems are{" "}
          <strong>public once published</strong>; solutions are revealed to students per class when you
          release them.
        </p>
      </div>

      <form action={createProblemSet} className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-3">
        <p className="font-medium text-parchment">New problem set</p>
        <input type="hidden" name="courseId" value={course.id} />
        <div className="flex flex-col sm:flex-row gap-2">
          <input
            name="title"
            required
            placeholder="Title (e.g. 1.1 Exercises)"
            autoComplete="off"
            className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
          />
          <button
            type="submit"
            className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
          >
            Create &amp; edit
          </button>
        </div>
      </form>

      {problemSets.length === 0 ? (
        <p className="text-parchment-dim text-sm">No problem sets for this course yet.</p>
      ) : (
        <ul className="space-y-3">
          {problemSets.map((ps) => (
            <li
              key={ps.id}
              className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-start justify-between gap-4"
            >
              <Link href={`/admin/problem-sets/${ps.id}`} className="min-w-0 group">
                <div className="flex items-center gap-2 flex-wrap">
                  <span className="font-medium text-parchment group-hover:text-gold-300 transition-colors">
                    {ps.title}
                  </span>
                  <span
                    className={`text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border ${
                      ps.isDraft ? "bg-amber-900/40 border-amber-700 text-amber-300" : "bg-green-900/30 border-green-700 text-green-300"
                    }`}
                  >
                    {ps.isDraft ? "Draft" : "Published"}
                  </span>
                </div>
                <p className="text-xs text-parchment-dim mt-0.5">
                  assigned to {ps._count.assignments} class
                  {ps._count.assignments === 1 ? "" : "es"}
                </p>
              </Link>
              <div className="flex items-center gap-3 shrink-0 text-sm">
                {!ps.isDraft && (
                  <Link
                    href={`/courses/${course.id}/problems/${ps.id}`}
                    target="_blank"
                    className="text-parchment-dim hover:text-gold-300 transition-colors"
                  >
                    view ↗
                  </Link>
                )}
                <Link
                  href={`/admin/problem-sets/${ps.id}?mode=edit`}
                  className="text-gold-400 hover:text-gold-300 transition-colors"
                >
                  edit
                </Link>
              </div>
            </li>
          ))}
        </ul>
      )}
    </main>
  );
}
