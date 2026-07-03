import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { getSectionGradebook } from "@/lib/gradebook";
import SubmitForm from "@/components/SubmitForm";
import MarkdownNotes from "@/components/MarkdownNotes";

export const dynamic = "force-dynamic";

const pct = (v: number | null | undefined) => (v === null || v === undefined ? "—" : `${Math.round(v)}%`);
function pctClass(v: number | null | undefined): string {
  if (v === null || v === undefined) return "text-parchment-dim";
  if (v >= 90) return "text-green-400";
  if (v >= 70) return "text-gold-300";
  return "text-red-400";
}

export default async function ClassHubPage({
  params,
}: {
  params: Promise<{ sectionId: string }>;
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) redirect("/auth/signin");
  const userId = session.user.id;
  const { sectionId } = await params;

  // Only an enrolled student can view their own class hub.
  const enrollment = await db.enrollment.findUnique({
    where: { sectionId_userId: { sectionId, userId } },
    select: { status: true },
  });
  if (!enrollment || enrollment.status !== "active") notFound();

  const gb = await getSectionGradebook(sectionId);
  const row = gb?.students.find((s) => s.userId === userId);
  if (!gb || !row) notFound();

  const courseId = gb.section.course.id;
  const w = gb.config.weights;

  // Assignments with this student's own submission.
  const assignments = (
    await db.assignment.findMany({
      where: { sectionId },
      orderBy: [{ dueAt: "asc" }, { createdAt: "desc" }],
      include: {
        problemSet: { select: { id: true, title: true, solution: true } },
        submissions: { where: { userId }, select: { url: true, score: true, feedback: true } },
      },
    })
  ).map((a) => ({ ...a, sub: a.submissions[0] ?? null }));

  // Per-lecture quiz best scores + final test best.
  const videos = await db.video.findMany({
    where: { courseId },
    orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
    select: { id: true, title: true, _count: { select: { quizQuestions: { where: { isDraft: false } } } } },
  });
  const quizVideos = videos.filter((v) => v._count.quizQuestions > 0);
  const quizVideoIds = quizVideos.map((v) => v.id);
  const myAttempts = await db.quizAttempt.findMany({
    where: { userId, OR: [{ videoId: { in: quizVideoIds } }, { courseId, videoId: null }] },
    select: { videoId: true, courseId: true, score: true, totalQuestions: true },
  });
  const bestByVideo = new Map<string, number>();
  let bestTest: number | null = null;
  for (const a of myAttempts) {
    if (a.totalQuestions <= 0) continue;
    const p = (a.score / a.totalQuestions) * 100;
    if (a.videoId) bestByVideo.set(a.videoId, Math.max(bestByVideo.get(a.videoId) ?? 0, p));
    else if (a.courseId === courseId) bestTest = Math.max(bestTest ?? 0, p);
  }

  const breakdown = [
    { label: "Attendance", pctv: row.attendancePct, weight: w.attendance, detail: `${row.watchedCount}/${gb.totalLectures} lectures` },
    { label: "Quizzes", pctv: row.quizAvgPct, weight: w.quizzes, detail: `${row.quizzesTaken}/${gb.totalQuizzes} taken` },
    { label: "Homework", pctv: row.hwPct, weight: w.homework, detail: `${row.hwGradedCount}/${gb.totalAssignments} graded` },
    { label: "Final Test", pctv: row.testPct, weight: w.test, detail: gb.hasTest ? "best attempt" : "no test yet" },
    { label: "Midterm", pctv: row.midtermPct, weight: w.midterm, detail: "in class" },
    { label: "Final", pctv: row.finalPct, weight: w.final, detail: "in class" },
  ];

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/dashboard" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← My Progress
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-10">
        {/* Grade header */}
        <div className="flex items-start justify-between gap-4 flex-wrap">
          <div className="min-w-0">
            <h1 className="text-2xl font-bold text-parchment">{gb.section.name}</h1>
            <p className="text-sm text-parchment-dim mt-1">
              <Link href={`/courses/${courseId}`} className="hover:text-gold-300 transition-colors">
                {gb.section.course.title} — go to lectures →
              </Link>
            </p>
          </div>
          <div className="text-right shrink-0">
            <p className={`text-4xl font-bold ${pctClass(row.currentGrade)}`}>{pct(row.currentGrade)}</p>
            <p className="text-xs text-parchment-dim">current grade</p>
          </div>
        </div>

        {/* Grade breakdown */}
        <section className="space-y-3">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            How your grade is calculated
          </h2>
          <div className="overflow-x-auto rounded-xl border border-crimson-700">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-crimson-900 text-left">
                  <th className="px-4 py-2.5 font-medium text-parchment-dim">Category</th>
                  <th className="px-4 py-2.5 font-medium text-parchment-dim">Your score</th>
                  <th className="px-4 py-2.5 font-medium text-parchment-dim">Weight</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-crimson-800">
                {breakdown.map((c) => (
                  <tr key={c.label} className="bg-crimson-950/40">
                    <td className="px-4 py-2.5">
                      <span className="text-parchment">{c.label}</span>
                      <span className="text-xs text-parchment-dim"> · {c.detail}</span>
                    </td>
                    <td className="px-4 py-2.5">
                      <span className={pctClass(c.pctv)}>{pct(c.pctv)}</span>
                      {c.pctv === null && <span className="text-xs text-parchment-dim"> (pending)</span>}
                    </td>
                    <td className="px-4 py-2.5 text-parchment-dim">{c.weight}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="text-xs text-parchment-dim">
            Your current grade is the weighted average of the categories that have data so far —
            categories still marked <em>pending</em> don&apos;t count against you yet.
          </p>
        </section>

        {/* Homework */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Homework
          </h2>
          {assignments.length === 0 ? (
            <p className="text-parchment-dim text-sm">No homework assigned yet.</p>
          ) : (
            <ul className="space-y-3">
              {assignments.map((a) => {
                const graded = a.sub && a.sub.score !== null;
                return (
                  <li key={a.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
                    <div className="flex items-start justify-between gap-4 flex-wrap">
                      <div className="min-w-0">
                        <Link
                          href={`/courses/${courseId}/problems/${a.problemSet.id}`}
                          className="font-medium text-parchment hover:text-gold-300 transition-colors"
                        >
                          {a.problemSet.title}
                        </Link>
                        <p className="text-xs text-parchment-dim mt-0.5">
                          {a.dueAt ? `Due ${new Date(a.dueAt).toLocaleString()}` : "No due date"} · {a.points} pts
                        </p>
                      </div>
                      {graded ? (
                        <span className="text-sm text-gold-300 shrink-0">
                          {a.sub!.score}/{a.points}
                        </span>
                      ) : a.sub ? (
                        <span className="text-xs text-green-400 shrink-0">submitted · awaiting grade</span>
                      ) : (
                        <span className="text-xs text-parchment-dim shrink-0">not submitted</span>
                      )}
                    </div>
                    {graded && a.sub!.feedback && (
                      <p className="text-sm text-parchment-dim border-l-2 border-crimson-700 pl-3">{a.sub!.feedback}</p>
                    )}
                    <SubmitForm assignmentId={a.id} currentUrl={a.sub?.url ?? null} />
                    {a.solutionsReleased && a.problemSet.solution.trim() && (
                      <details className="pt-1">
                        <summary className="cursor-pointer text-sm text-gold-400 hover:text-gold-300 transition-colors">
                          View solutions
                        </summary>
                        <div className="mt-3 border-t border-crimson-800 pt-3">
                          <MarkdownNotes content={a.problemSet.solution} />
                        </div>
                      </details>
                    )}
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        {/* Quizzes & test */}
        {(quizVideos.length > 0 || gb.hasTest) && (
          <section className="space-y-4">
            <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
              Quizzes &amp; Test
            </h2>
            <p className="text-xs text-parchment-dim">
              Best attempt counts — retake any quiz or the test to improve your score.
            </p>
            <ul className="space-y-2">
              {quizVideos.map((v) => {
                const best = bestByVideo.get(v.id) ?? null;
                return (
                  <li key={v.id}>
                    <Link
                      href={`/courses/${courseId}/${v.id}`}
                      className="group flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-2.5 hover:border-gold-500 transition-colors"
                    >
                      <span className="text-sm text-parchment group-hover:text-gold-300 transition-colors truncate">
                        {v.title}
                      </span>
                      <span className={`text-sm shrink-0 ${pctClass(best)}`}>
                        {best === null ? "not taken" : pct(best)}
                      </span>
                    </Link>
                  </li>
                );
              })}
              {gb.hasTest && (
                <li>
                  <Link
                    href={`/courses/${courseId}/test`}
                    className="group flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-2.5 hover:border-gold-500 transition-colors"
                  >
                    <span className="text-sm text-parchment group-hover:text-gold-300 transition-colors">
                      Final Course Test
                    </span>
                    <span className={`text-sm shrink-0 ${pctClass(bestTest)}`}>
                      {bestTest === null ? "not taken" : pct(bestTest)}
                    </span>
                  </Link>
                </li>
              )}
            </ul>
          </section>
        )}
      </div>
    </main>
  );
}
