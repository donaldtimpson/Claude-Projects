import Link from "next/link";
import { notFound } from "next/navigation";
import { getSectionGradebook } from "@/lib/gradebook";

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
    </main>
  );
}
