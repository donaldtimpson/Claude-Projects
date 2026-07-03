import Link from "next/link";
import { db } from "@/lib/db";
import { createProblemSet } from "@/lib/assignments";

export const dynamic = "force-dynamic";

// Admin: author course-level problem sets (problems + solutions). Problems are
// PUBLIC once published; solutions are released to students per-assignment.
export default async function AdminProblemSetsPage() {
  const [courses, problemSets] = await Promise.all([
    db.course.findMany({
      orderBy: [{ isCurrent: "desc" }, { createdAt: "asc" }],
      select: { id: true, title: true, isCurrent: true },
    }),
    db.problemSet.findMany({
      orderBy: [{ isDraft: "desc" }, { createdAt: "desc" }],
      select: {
        id: true,
        title: true,
        isDraft: true,
        course: { select: { id: true, title: true } },
        _count: { select: { assignments: true } },
      },
    }),
  ]);

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-8">
      <div>
        <h1 className="text-2xl font-bold text-parchment">Problem Sets</h1>
        <p className="text-sm text-parchment-dim mt-1">
          Course-level homework (problems + solutions, Markdown + math). Problems are{" "}
          <strong>public once published</strong>; solutions are revealed to students per class when you
          release them. Assign a published set to a class (in Classes) to collect graded submissions.
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

      {problemSets.length === 0 ? (
        <p className="text-parchment-dim text-sm">No problem sets yet.</p>
      ) : (
        <ul className="space-y-3">
          {problemSets.map((ps) => (
            <li
              key={ps.id}
              className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-start justify-between gap-4"
            >
              <div className="min-w-0">
                <div className="flex items-center gap-2 flex-wrap">
                  <Link
                    href={`/admin/problem-sets/${ps.id}`}
                    className="font-medium text-parchment hover:text-gold-300 transition-colors"
                  >
                    {ps.title}
                  </Link>
                  <span
                    className={`text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border ${
                      ps.isDraft ? "bg-amber-900/40 border-amber-700 text-amber-300" : "bg-green-900/30 border-green-700 text-green-300"
                    }`}
                  >
                    {ps.isDraft ? "Draft" : "Published"}
                  </span>
                </div>
                <p className="text-xs text-parchment-dim mt-0.5">
                  {ps.course.title} · assigned to {ps._count.assignments} class
                  {ps._count.assignments === 1 ? "" : "es"}
                </p>
              </div>
              <div className="flex items-center gap-3 shrink-0 text-sm">
                {!ps.isDraft && (
                  <Link
                    href={`/courses/${ps.course.id}/problems/${ps.id}`}
                    target="_blank"
                    className="text-parchment-dim hover:text-gold-300 transition-colors"
                  >
                    view ↗
                  </Link>
                )}
                <Link href={`/admin/problem-sets/${ps.id}`} className="text-gold-400 hover:text-gold-300 transition-colors">
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
