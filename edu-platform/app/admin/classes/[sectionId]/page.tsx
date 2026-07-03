import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { getSectionGradebook } from "@/lib/gradebook";
import { deleteAssignment, toggleSolutionsReleased } from "@/lib/assignments";
import { setGradeWeights, setManualMarks } from "@/lib/grades";
import AssignForm from "./AssignForm";

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
      where: { courseId: gb.section.course.id, isDraft: false },
      orderBy: { createdAt: "desc" },
      select: { id: true, title: true, points: true },
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

  const w = gb.config.weights;
  const weightTotal = w.attendance + w.quizzes + w.test + w.homework + w.midterm + w.final;

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
        Attendance, quizzes, homework, and the final test are auto-tracked; midterm, final, and any
        attendance override are entered by you. <strong>Grade</strong> is the weighted average over the
        categories that have data so far (a running grade).
      </p>

      {/* Grade weights */}
      <details className="bg-crimson-900 border border-crimson-700 rounded-xl px-4 py-3">
        <summary className="cursor-pointer text-sm text-parchment">
          Grade weights (total {weightTotal}%) &amp; exam maxes
        </summary>
        <form action={setGradeWeights} className="mt-3 flex flex-wrap items-end gap-3">
          <input type="hidden" name="sectionId" value={sectionId} />
          {(
            [
              ["attendance", "Attendance"],
              ["quizzes", "Quizzes"],
              ["test", "Final Test"],
              ["homework", "Homework"],
              ["midterm", "Midterm"],
              ["final", "Final"],
            ] as const
          ).map(([key, label]) => (
            <label key={key} className="text-xs text-parchment-dim flex flex-col gap-1">
              {label} %
              <input
                name={key}
                type="number"
                min={0}
                defaultValue={gb.config.weights[key]}
                className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment text-sm transition-colors"
              />
            </label>
          ))}
          <span className="text-parchment-dim self-center">|</span>
          <label className="text-xs text-parchment-dim flex flex-col gap-1">
            Midterm max
            <input
              name="midtermMax"
              type="number"
              min={1}
              defaultValue={gb.config.midtermMax}
              className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment text-sm transition-colors"
            />
          </label>
          <label className="text-xs text-parchment-dim flex flex-col gap-1">
            Final max
            <input
              name="finalMax"
              type="number"
              min={1}
              defaultValue={gb.config.finalMax}
              className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment text-sm transition-colors"
            />
          </label>
          <button
            type="submit"
            className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
          >
            Save weights
          </button>
        </form>
      </details>

      {gb.students.length === 0 ? (
        <p className="text-parchment-dim text-sm">No students registered yet.</p>
      ) : (
        <div className="overflow-x-auto rounded-xl border border-crimson-700">
          {/* One hidden form per student — inputs/buttons in the table reference it
              by id (HTML `form` attribute) so a whole row saves together. */}
          {gb.students.map((s) => (
            <form key={`f-${s.userId}`} id={`marks-${s.userId}`} action={setManualMarks}>
              <input type="hidden" name="sectionId" value={sectionId} />
              <input type="hidden" name="userId" value={s.userId} />
            </form>
          ))}
          <table className="w-full text-sm">
            <thead>
              <tr className="bg-crimson-900 text-left">
                <th className="px-3 py-3 font-medium text-parchment-dim">Student</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Attendance</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Quizzes</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Homework</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Test</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Midterm</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Final</th>
                <th className="px-3 py-3 font-medium text-parchment-dim whitespace-nowrap">Grade</th>
                <th className="px-3 py-3" />
              </tr>
            </thead>
            <tbody className="divide-y divide-crimson-800">
              {gb.students.map((s) => {
                const f = `marks-${s.userId}`;
                const inputCls =
                  "w-14 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded px-2 py-1 text-parchment text-sm transition-colors";
                return (
                  <tr key={s.userId} className="bg-crimson-950/40 align-top">
                    <td className="px-3 py-3">
                      <p className="text-parchment">{s.name ?? "—"}</p>
                      <p className="text-xs text-parchment-dim">{s.email}</p>
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap">
                      <span className={pctClass(s.attendancePct)}>{pct(s.attendancePct)}</span>
                      <span className="text-parchment-dim text-xs"> ({s.watchedCount}/{gb.totalLectures})</span>
                      <input
                        form={f}
                        name="attendanceOverride"
                        type="number"
                        min={0}
                        max={100}
                        defaultValue={s.attendanceOverride ?? ""}
                        placeholder="ovr"
                        className={`${inputCls} block mt-1`}
                        title="Attendance override %"
                      />
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap">
                      <span className={pctClass(s.quizAvgPct)}>{pct(s.quizAvgPct)}</span>
                      <span className="text-parchment-dim text-xs"> ({s.quizzesTaken}/{gb.totalQuizzes})</span>
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap">
                      <span className={pctClass(s.hwPct)}>{pct(s.hwPct)}</span>
                      <span className="text-parchment-dim text-xs"> ({s.hwGradedCount}/{gb.totalAssignments})</span>
                    </td>
                    <td className={`px-3 py-3 whitespace-nowrap ${pctClass(s.testPct)}`}>{pct(s.testPct)}</td>
                    <td className="px-3 py-3 whitespace-nowrap">
                      <input
                        form={f}
                        name="midtermScore"
                        type="number"
                        min={0}
                        defaultValue={s.midtermScore ?? ""}
                        className={inputCls}
                      />
                      <span className="text-parchment-dim text-xs"> /{gb.config.midtermMax}</span>
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap">
                      <input
                        form={f}
                        name="finalScore"
                        type="number"
                        min={0}
                        defaultValue={s.finalScore ?? ""}
                        className={inputCls}
                      />
                      <span className="text-parchment-dim text-xs"> /{gb.config.finalMax}</span>
                    </td>
                    <td className={`px-3 py-3 whitespace-nowrap font-semibold ${pctClass(s.currentGrade)}`}>
                      {pct(s.currentGrade)}
                    </td>
                    <td className="px-3 py-3 whitespace-nowrap">
                      <button
                        form={f}
                        type="submit"
                        className="text-xs text-gold-400 hover:text-gold-300 transition-colors"
                      >
                        Save
                      </button>
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
            No published problem sets for this course yet.{" "}
            <Link href="/admin/problem-sets" className="text-gold-400 hover:text-gold-300 transition-colors">
              Create &amp; publish one
            </Link>{" "}
            first, then assign it here.
          </p>
        ) : (
          <AssignForm sectionId={sectionId} problemSets={problemSets} videos={videos} />
        )}

        {assignments.length > 0 && (
          <ul className="space-y-2">
            {assignments.map((a) => (
              <li
                key={a.id}
                className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center justify-between gap-4"
              >
                <div className="min-w-0">
                  <p className="text-sm font-medium text-parchment truncate">{a.title ?? a.problemSet.title}</p>
                  <p className="text-xs text-parchment-dim mt-0.5">
                    {a.title ? `${a.problemSet.title} · ` : ""}Due {fmtDue(a.dueAt)} · {a.points} pts · {a._count.submissions}/{gb.students.length} submitted
                  </p>
                </div>
                <div className="flex items-center gap-3 shrink-0 text-sm">
                  <form action={toggleSolutionsReleased}>
                    <input type="hidden" name="assignmentId" value={a.id} />
                    <button
                      type="submit"
                      className={
                        a.solutionsReleased
                          ? "text-green-400 hover:text-green-300 transition-colors"
                          : "text-parchment-dim hover:text-gold-300 transition-colors"
                      }
                      title="Toggle whether students in this class can see the solution"
                    >
                      {a.solutionsReleased ? "solutions: shown" : "solutions: hidden"}
                    </button>
                  </form>
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
