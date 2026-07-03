import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { getSectionGradebook } from "@/lib/gradebook";
import { createAssignment, deleteAssignment } from "@/lib/assignments";

const fmtDue = (d: Date | null) =>
  d ? new Date(d).toLocaleString(undefined, { month: "short", day: "numeric", hour: "numeric", minute: "2-digit" }) : "no due date";

export const dynamic = "force-dynamic";

const pct = (v: number | null) => (v === null ? "—" : `${Math.round(v)}%`);

// Color a percentage: green ≥90, gold ≥70, red below (matches the attempt-review scheme).
function pctClass(v: number | null): string {
  if (v === null) return "text-parchment-dim";
  if (v >= 90) return "text-green-400";
  if (v >= 70) return "text-gold-300";
  return "text-red-400";
}

export default async function GradebookPage({
  params,
}: {
  params: Promise<{ sectionId: string }>;
}) {
  const { sectionId } = await params;
  const gb = await getSectionGradebook(sectionId);
  if (!gb) notFound();

  const [problemSets, videos, assignments] = await Promise.all([
    db.problemSet.findMany({
      where: { courseId: gb.section.course.id },
      orderBy: { createdAt: "desc" },
      select: { id: true, title: true },
    }),
    db.video.findMany({
      where: { courseId: gb.section.course.id },
      orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
      select: { id: true, title: true },
    }),
    db.assignment.findMany({
      where: { sectionId },
      orderBy: { createdAt: "desc" },
      include: {
        problemSet: { select: { title: true } },
        _count: { select: { submissions: true } },
      },
    }),
  ]);

  return (
    <main className="max-w-5xl mx-auto px-6 py-10 space-y-6">
      <div>
        <Link href="/admin/classes" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Classes
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-2">{gb.section.name}</h1>
        <p className="text-sm text-parchment-dim mt-1">
          <Link href={`/courses/${gb.section.course.id}`} className="hover:text-gold-300 transition-colors">
            {gb.section.course.title}
          </Link>{" "}
          · {gb.students.length} student{gb.students.length === 1 ? "" : "s"} · {gb.totalLectures} lectures ·{" "}
          {gb.totalQuizzes} quizzes{gb.hasTest ? " · final test" : ""}
        </p>
      </div>

      <p className="text-xs text-parchment-dim bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-3">
        Auto-tracked columns below (attendance from lecture watches; quizzes and the final test are
        best-attempt). Homework, midterm, and final columns — plus the weighted final grade — arrive in
        later phases.
      </p>

      {gb.students.length === 0 ? (
        <p className="text-parchment-dim text-sm">No students registered yet.</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border border-crimson-700">
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-crimson-900 text-left">
                <th className="px-4 py-3 font-medium text-parchment-dim">Student</th>
                <th className="px-4 py-3 font-medium text-parchment-dim whitespace-nowrap">
                  Attendance
                </th>
                <th className="px-4 py-3 font-medium text-parchment-dim whitespace-nowrap">Quizzes</th>
                <th className="px-4 py-3 font-medium text-parchment-dim whitespace-nowrap">Homework</th>
                <th className="px-4 py-3 font-medium text-parchment-dim whitespace-nowrap">Final Test</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-crimson-800">
              {gb.students.map((s) => {
                const attendancePct =
                  gb.totalLectures > 0 ? (s.watchedCount / gb.totalLectures) * 100 : null;
                return (
                  <tr key={s.userId} className="bg-crimson-950/40">
                    <td className="px-4 py-3">
                      <p className="text-parchment">{s.name ?? "—"}</p>
                      <p className="text-xs text-parchment-dim">{s.email}</p>
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={pctClass(attendancePct)}>
                        {s.watchedCount}/{gb.totalLectures}
                      </span>
                      <span className="text-parchment-dim"> · {pct(attendancePct)}</span>
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={pctClass(s.quizAvgPct)}>{pct(s.quizAvgPct)}</span>
                      <span className="text-parchment-dim"> · {s.quizzesTaken}/{gb.totalQuizzes} taken</span>
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={pctClass(s.hwPct)}>{pct(s.hwPct)}</span>
                      <span className="text-parchment-dim"> · {s.hwGradedCount}/{gb.totalAssignments} graded</span>
                    </td>
                    <td className={`px-4 py-3 whitespace-nowrap ${pctClass(s.testPct)}`}>
                      {pct(s.testPct)}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}

      {/* Assignments */}
      <section className="space-y-4 pt-4">
        <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
          Homework Assignments
        </h2>

        {problemSets.length === 0 ? (
          <p className="text-sm text-parchment-dim">
            No problem sets for this course yet.{" "}
            <Link href="/admin/problem-sets" className="text-gold-400 hover:text-gold-300 transition-colors">
              Create one
            </Link>{" "}
            first, then assign it here.
          </p>
        ) : (
          <form action={createAssignment} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
            <input type="hidden" name="sectionId" value={sectionId} />
            <div className="flex flex-col sm:flex-row gap-2">
              <select
                name="problemSetId"
                required
                defaultValue=""
                className="flex-[2] bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors"
              >
                <option value="" disabled>
                  Problem set…
                </option>
                {problemSets.map((ps) => (
                  <option key={ps.id} value={ps.id}>
                    {ps.title}
                  </option>
                ))}
              </select>
              <select
                name="videoId"
                defaultValue=""
                className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors"
              >
                <option value="">(optional) relates to lecture…</option>
                {videos.map((v) => (
                  <option key={v.id} value={v.id}>
                    {v.title}
                  </option>
                ))}
              </select>
            </div>
            <div className="flex flex-col sm:flex-row gap-2 sm:items-center">
              <label className="text-sm text-parchment-dim flex items-center gap-2">
                Points
                <input
                  name="points"
                  type="number"
                  min={0}
                  defaultValue={100}
                  className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors"
                />
              </label>
              <label className="text-sm text-parchment-dim flex items-center gap-2">
                Due
                <input
                  name="dueAt"
                  type="datetime-local"
                  className="bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors"
                />
              </label>
              <button
                type="submit"
                className="sm:ml-auto font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
              >
                Assign
              </button>
            </div>
          </form>
        )}

        {assignments.length > 0 && (
          <ul className="space-y-2">
            {assignments.map((a) => (
              <li
                key={a.id}
                className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center justify-between gap-4"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium text-parchment truncate">{a.problemSet.title}</p>
                  <p className="text-xs text-parchment-dim mt-0.5">
                    Due {fmtDue(a.dueAt)} · {a.points} pts · {a._count.submissions}/{gb.students.length} submitted
                  </p>
                </div>
                <div className="flex items-center gap-3 shrink-0 text-sm">
                  <Link
                    href={`/admin/classes/${sectionId}/assignments/${a.id}`}
                    className="text-gold-400 hover:text-gold-300 transition-colors"
                  >
                    Grade →
                  </Link>
                  <form action={deleteAssignment}>
                    <input type="hidden" name="id" value={a.id} />
                    <button type="submit" className="text-parchment-dim hover:text-red-400 transition-colors">
                      delete
                    </button>
                  </form>
                </div>
              </li>
            ))}
          </ul>
        )}
      </section>
    </main>
  );
}
