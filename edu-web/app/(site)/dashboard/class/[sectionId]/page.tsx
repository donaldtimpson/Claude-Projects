import { Fragment } from "react";
import Link from "next/link";
import { notFound, redirect } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { getSectionGradebook, studentBreakdown } from "@/lib/gradebook";
import SubmitForm from "@/components/SubmitForm";
import { getAcedLessonSlugs } from "@/lib/lessons";
import { grammarLessonDrills } from "@/lib/drills/grammar";

export const dynamic = "force-dynamic";

const pct = (v: number | null | undefined) => (v === null || v === undefined ? "—" : `${Math.round(v)}%`);
function pctClass(v: number | null | undefined): string {
  if (v === null || v === undefined) return "text-parchment-dim";
  if (v >= 90) return "text-green-400";
  if (v >= 70) return "text-amber-300";
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
      orderBy: [{ dueAt: "asc" }, { createdAt: "asc" }],
      include: {
        problemSet: {
          select: { id: true, title: true, solution: true, solutionsPublic: true },
        },
        submissions: { where: { userId }, select: { url: true, score: true, feedback: true } },
      },
    })
  )
    .map((a) => ({ ...a, sub: a.submissions[0] ?? null }))
    // Open work first; graded problem sets sink to the bottom as compact rows.
    .sort((x, y) => Number(x.sub?.score != null && !x.lessonSlug) - Number(y.sub?.score != null && !y.lessonSlug));
  const firstGraded = assignments.findIndex((a) => a.sub?.score != null && !a.lessonSlug);

  // Lesson-drill assignments are auto-graded by an ace — resolve titles + this
  // student's passed lessons so we can show pass status instead of a submit form.
  const lessonTitle = new Map(grammarLessonDrills.map((d) => [d.slug, d.title]));
  const acedLessons = new Set(await getAcedLessonSlugs(userId));

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

  const breakdown = studentBreakdown(gb, row);
  const showCourseTest = gb.hasTest && w.test > 0;

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 py-4">
        <div className="max-w-3xl mx-auto px-6">
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
          <h2 className="section-title">
            How your grade is calculated
          </h2>
          <div className="overflow-x-auto rounded-xl border border-crimson-700 bg-crimson-900 shadow-card">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-crimson-800/60 text-left">
                  <th className="px-4 py-2.5 eyebrow text-parchment-dim">Category</th>
                  <th className="px-4 py-2.5 eyebrow text-parchment-dim">Your score</th>
                  <th className="px-4 py-2.5 eyebrow text-parchment-dim">Weight</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-crimson-800">
                {breakdown.map((c) => (
                  <tr key={c.key}>
                    <td className="px-4 py-2.5">
                      <span className="text-parchment">{c.label}</span>
                      <span className="block sm:inline text-xs text-parchment-dim"><span className="hidden sm:inline"> · </span>{c.detail}</span>
                    </td>
                    <td className="px-4 py-2.5">
                      <span className={pctClass(c.pct)}>{pct(c.pct)}</span>
                      {c.pct === null && <span className="text-xs text-parchment-dim"> (pending)</span>}
                    </td>
                    <td className="px-4 py-2.5 text-parchment-dim">{c.weight}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <p className="text-xs text-parchment-dim">
            Your current grade is the weighted average of the categories that have data so far —
            categories still marked <em>pending</em>{" "}don&apos;t count against you yet.
          </p>
        </section>

        {/* Instructor-defined categories (e.g. Tests), one score per item */}
        {gb.customCategories
          .filter((c) => c.weight > 0 && c.items.length > 0)
          .map((c) => (
            <section key={c.id} className="space-y-4">
              <h2 className="section-title">
                {c.name}
              </h2>
              <ul className="space-y-2">
                {c.items.map((it) => {
                  const sc = row.customScores[it.id];
                  const has = sc !== null && sc !== undefined;
                  return (
                    <li
                      key={it.id}
                      className="flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-2.5"
                    >
                      <span className="text-sm text-parchment truncate">{it.name}</span>
                      {has ? (
                        <span className={`font-ui text-sm font-semibold tabular-nums shrink-0 ${pctClass((sc / it.maxPoints) * 100)}`}>
                          {sc}/{it.maxPoints}
                        </span>
                      ) : (
                        <span className="text-xs text-parchment-dim shrink-0">Not graded yet</span>
                      )}
                    </li>
                  );
                })}
              </ul>
            </section>
          ))}

        {/* Homework */}
        <section className="space-y-4">
          <h2 className="section-title">
            Homework
          </h2>
          {assignments.length === 0 ? (
            <p className="text-parchment-dim text-sm">No homework assigned yet.</p>
          ) : (
            <ul className="space-y-3">
              {assignments.map((a, i) => {
                // Lesson-drill homework: auto-graded by acing the 30-run. No URL
                // submission — the student just does the drill; ✦ = full credit.
                if (a.lessonSlug) {
                  const aced = acedLessons.has(a.lessonSlug);
                  const title = a.title ?? lessonTitle.get(a.lessonSlug) ?? a.lessonSlug;
                  return (
                    <li key={a.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
                      <div className="flex items-start justify-between gap-4 flex-wrap">
                        <div className="min-w-0">
                          <Link
                            href={`/drills/${a.lessonSlug}`}
                            className="font-medium text-parchment hover:text-gold-300 transition-colors"
                          >
                            {title}
                          </Link>
                          <p className="text-xs text-parchment-dim mt-0.5">
                            Grammar lesson · pass the 30-question run · {a.points} pts
                          </p>
                        </div>
                        {aced ? (
                          <span className="font-ui text-sm font-semibold text-gold-300 shrink-0">✦ Aced · {a.points}/{a.points}</span>
                        ) : (
                          <span className="text-xs text-parchment-dim shrink-0">Not yet aced</span>
                        )}
                      </div>
                      <Link
                        href={`/drills/${a.lessonSlug}`}
                        className="inline-block text-sm text-gold-400 hover:text-gold-300 transition-colors"
                      >
                        {aced ? "Practice again →" : "Do the homework drill →"}
                      </Link>
                    </li>
                  );
                }

                const ps = a.problemSet!;
                const graded = a.sub && a.sub.score !== null;
                const solutionsLink = ps.solutionsPublic && ps.solution.trim() && (
                  <Link
                    href={`/courses/${courseId}/problems/${ps.id}`}
                    className="text-sm text-gold-400 hover:text-gold-300 transition-colors"
                  >
                    {graded ? "Solutions →" : "View problems & worked solutions →"}
                  </Link>
                );
                // Graded work collapses to a compact row: title, solutions, score.
                if (graded) {
                  return (
                    <Fragment key={a.id}>
                    {i === firstGraded && i > 0 && (
                      <li className="eyebrow text-parchment-dim pt-4">Graded</li>
                    )}
                    <li className="bg-crimson-900 border border-crimson-700 rounded-xl px-4 py-3">
                      <div className="flex items-center justify-between gap-4">
                        <div className="min-w-0 flex items-baseline gap-3 flex-wrap">
                          <Link
                            href={`/courses/${courseId}/problems/${ps.id}`}
                            className="font-medium text-parchment hover:text-gold-300 transition-colors"
                          >
                            {a.title ?? ps.title}
                          </Link>
                          {solutionsLink}
                        </div>
                        <span className="font-ui text-sm font-semibold tabular-nums text-parchment shrink-0">
                          {a.sub!.score}/{a.points}
                        </span>
                      </div>
                      {a.sub!.feedback && (
                        <p className="mt-2 text-sm text-parchment-dim border-l-2 border-crimson-700 pl-3">{a.sub!.feedback}</p>
                      )}
                    </li>
                    </Fragment>
                  );
                }
                return (
                  <li key={a.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
                    <div className="flex items-start justify-between gap-4 flex-wrap">
                      <div className="min-w-0">
                        <Link
                          href={`/courses/${courseId}/problems/${ps.id}`}
                          className="font-medium text-parchment hover:text-gold-300 transition-colors"
                        >
                          {a.title ?? ps.title}
                        </Link>
                        <p className="text-xs text-parchment-dim mt-0.5">
                          {a.title ? `${ps.title} · ` : ""}
                          {a.dueAt ? `Due ${new Date(a.dueAt).toLocaleString()}` : "No due date"} · {a.points} pts
                        </p>
                      </div>
                      {a.sub ? (
                        <span className="text-xs text-green-400 shrink-0">Submitted · awaiting grade</span>
                      ) : (
                        <span className="text-xs text-parchment-dim shrink-0">Not submitted</span>
                      )}
                    </div>
                    <SubmitForm assignmentId={a.id} currentUrl={a.sub?.url ?? null} />
                    {/* Solutions live inline with the problems they answer, so
                        point there rather than duplicating them here. */}
                    {solutionsLink && <div>{solutionsLink}</div>}
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        {/* Quizzes & test */}
        {(quizVideos.length > 0 || showCourseTest) && (
          <section className="space-y-4">
            <h2 className="section-title">
              {showCourseTest ? <>Quizzes &amp; Test</> : "Quizzes"}
            </h2>
            <p className="text-xs text-parchment-dim">
              Best attempt counts — retake any quiz{showCourseTest ? " or the test" : ""} to improve your score.
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
                      {best === null ? (
                        <span className="text-xs text-parchment-dim shrink-0">Not taken</span>
                      ) : (
                        <span className={`font-ui text-sm font-semibold tabular-nums shrink-0 ${pctClass(best)}`}>{pct(best)}</span>
                      )}
                    </Link>
                  </li>
                );
              })}
              {showCourseTest && (
                <li>
                  <Link
                    href={`/courses/${courseId}/test`}
                    className="group flex items-center justify-between gap-4 bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-2.5 hover:border-gold-500 transition-colors"
                  >
                    <span className="text-sm text-parchment group-hover:text-gold-300 transition-colors">
                      Course Test
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
