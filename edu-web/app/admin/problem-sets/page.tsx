import Link from "next/link";
import { db } from "@/lib/db";
import { createProblemSet } from "@/lib/assignments";

export const dynamic = "force-dynamic";

// Admin: problem sets grouped by course. This index lists one card per course
// that has problem sets; drilling into a course (course/[courseId]) shows and
// manages that course's sets. Authoring happens on the per-course page or via
// the quick-create form here.
export default async function AdminProblemSetsPage() {
  const [courses, byCourse] = await Promise.all([
    db.course.findMany({
      orderBy: [{ isCurrent: "desc" }, { createdAt: "asc" }],
      select: { id: true, title: true, isCurrent: true },
    }),
    db.problemSet.groupBy({
      by: ["courseId", "isDraft"],
      _count: { _all: true },
    }),
  ]);

  // courseId -> { total, drafts, published }
  const counts = new Map<string, { total: number; drafts: number; published: number }>();
  for (const row of byCourse) {
    const c = counts.get(row.courseId) ?? { total: 0, drafts: 0, published: 0 };
    c.total += row._count._all;
    if (row.isDraft) c.drafts += row._count._all;
    else c.published += row._count._all;
    counts.set(row.courseId, c);
  }

  const coursesWithSets = courses.filter((c) => counts.has(c.id));

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-parchment">Problem Sets</h1>
        <p className="text-sm text-parchment-dim mt-1">
          Course-level homework (problems + solutions, Markdown + math). Once published, the
          problems and their worked solutions are{" "}
          <strong>public together</strong> — solutions render inline with the problem each one
          answers. Withhold a set&apos;s answers from its own editor. Choose a course to see and
          manage its problem sets.
        </p>
      </div>

      <form action={createProblemSet} className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-3">
        <p className="font-medium text-parchment">New problem set</p>
        <div className="flex flex-col sm:flex-row gap-2">
          <select
            name="courseId"
            required
            defaultValue={courses.find((c) => c.isCurrent)?.id ?? ""}
            className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment transition-colors"
          >
            <option value="" disabled>
              Choose a course…
            </option>
            {courses.map((c) => (
              <option key={c.id} value={c.id}>
                {c.title}
                {c.isCurrent ? " ★" : ""}
              </option>
            ))}
          </select>
          <input
            name="title"
            required
            placeholder="Title (e.g. Homework 21 — Electric Charge & the Field)"
            autoComplete="off"
            className="flex-[2] bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
          />
          <button
            type="submit"
            className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
          >
            Create &amp; edit
          </button>
        </div>
      </form>

      {coursesWithSets.length === 0 ? (
        <p className="text-parchment-dim text-sm">No problem sets yet. Create one above to get started.</p>
      ) : (
        <ul className="space-y-3">
          {coursesWithSets.map((c) => {
            const count = counts.get(c.id)!;
            return (
              <li key={c.id}>
                <Link
                  href={`/admin/problem-sets/course/${c.id}`}
                  className="group flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-xl p-4 transition-colors"
                >
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <span className="font-medium text-parchment group-hover:text-gold-300 transition-colors">
                        {c.title}
                      </span>
                      {c.isCurrent && (
                        <span className="text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border bg-gold-900/30 border-gold-700 text-gold-300">
                          Current
                        </span>
                      )}
                    </div>
                    <p className="text-xs text-parchment-dim mt-0.5">
                      {count.total} problem set{count.total === 1 ? "" : "s"}
                      {" · "}
                      {count.published} published · {count.drafts} draft{count.drafts === 1 ? "" : "s"}
                    </p>
                  </div>
                  <span className="shrink-0 text-parchment-dim group-hover:text-gold-300 transition-colors" aria-hidden>
                    →
                  </span>
                </Link>
              </li>
            );
          })}
        </ul>
      )}
    </main>
  );
}
