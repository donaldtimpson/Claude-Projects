import Link from "next/link";
import { db } from "@/lib/db";
import { createProblemSet } from "@/lib/assignments";

export const dynamic = "force-dynamic";

// Admin: author course-level problem sets. These are PUBLIC (shown on the course
// page for everyone); a section turns one into a graded assignment for its roster.
export default async function AdminProblemSetsPage() {
  const [courses, problemSets] = await Promise.all([
    db.course.findMany({
      orderBy: [{ isCurrent: "desc" }, { createdAt: "asc" }],
      select: { id: true, title: true, isCurrent: true },
    }),
    db.problemSet.findMany({
      orderBy: { createdAt: "desc" },
      include: {
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
          Course-level homework problems (Markdown + math). These are <strong>public</strong> — anyone
          can read them on the course page. Assign one to a class (in Classes) to collect graded
          submissions from your roster.
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
            placeholder="Title (e.g. Homework 1 — Capacitors)"
            autoComplete="off"
            className="flex-[2] bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
          />
        </div>
        <textarea
          name="body"
          rows={6}
          placeholder="Problem text — Markdown supported; math with $…$ and $$…$$ (KaTeX)."
          className="w-full bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 font-mono text-sm transition-colors"
        />
        <input
          name="attachmentUrl"
          placeholder="Optional attachment URL (e.g. a GitHub-hosted PDF)"
          autoComplete="off"
          className="w-full bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
        />
        <button
          type="submit"
          className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
        >
          Create problem set
        </button>
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
                <p className="font-medium text-parchment">{ps.title}</p>
                <p className="text-xs text-parchment-dim mt-0.5">
                  {ps.course.title} · assigned to {ps._count.assignments} class
                  {ps._count.assignments === 1 ? "" : "es"}
                </p>
              </div>
              <div className="flex items-center gap-3 shrink-0 text-sm">
                <Link
                  href={`/courses/${ps.course.id}/problems/${ps.id}`}
                  target="_blank"
                  className="text-parchment-dim hover:text-gold-300 transition-colors"
                >
                  view ↗
                </Link>
                <Link
                  href={`/admin/problem-sets/${ps.id}`}
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
