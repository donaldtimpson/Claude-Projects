import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { gradeSubmission } from "@/lib/assignments";

export const dynamic = "force-dynamic";

export default async function GradeAssignmentPage({
  params,
}: {
  params: Promise<{ sectionId: string; assignmentId: string }>;
}) {
  const { sectionId, assignmentId } = await params;

  const assignment = await db.assignment.findUnique({
    where: { id: assignmentId },
    include: {
      problemSet: { select: { title: true } },
      section: {
        select: {
          id: true,
          name: true,
          enrollments: {
            where: { status: "active" },
            orderBy: { enrolledAt: "asc" },
            include: { user: { select: { id: true, name: true, email: true } } },
          },
        },
      },
      submissions: {
        select: { userId: true, url: true, submittedAt: true, score: true, feedback: true, gradedAt: true },
      },
    },
  });
  if (!assignment || assignment.section.id !== sectionId) notFound();

  const subByUser = new Map(assignment.submissions.map((s) => [s.userId, s]));

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-6">
      <div>
        <Link href={`/admin/classes/${sectionId}`} className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← {assignment.section.name}
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-2">{assignment.problemSet.title}</h1>
        <p className="text-sm text-parchment-dim mt-1">
          {assignment.points} points · {assignment.submissions.length}/{assignment.section.enrollments.length} submitted
        </p>
      </div>

      <ul className="space-y-3">
        {assignment.section.enrollments.map((e) => {
          const sub = subByUser.get(e.user.id);
          return (
            <li key={e.user.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
              <div className="flex items-start justify-between gap-4 flex-wrap">
                <div className="min-w-0">
                  <p className="text-parchment">{e.user.name ?? "—"}</p>
                  <p className="text-xs text-parchment-dim">{e.user.email}</p>
                </div>
                {sub ? (
                  <a
                    href={sub.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="text-sm text-gold-400 hover:text-gold-300 transition-colors break-all"
                  >
                    open submission ↗
                  </a>
                ) : (
                  <span className="text-sm text-parchment-dim">not submitted</span>
                )}
              </div>

              {sub && (
                <p className="text-xs text-parchment-dim">
                  Submitted {new Date(sub.submittedAt).toLocaleString()}
                  {sub.gradedAt ? ` · graded ${new Date(sub.gradedAt).toLocaleDateString()}` : ""}
                </p>
              )}

              {sub ? (
                <form action={gradeSubmission} className="flex flex-col sm:flex-row gap-2 sm:items-start">
                  <input type="hidden" name="assignmentId" value={assignmentId} />
                  <input type="hidden" name="userId" value={e.user.id} />
                  <label className="text-sm text-parchment-dim flex items-center gap-2 shrink-0">
                    Score
                    <input
                      name="score"
                      type="number"
                      min={0}
                      max={assignment.points}
                      defaultValue={sub.score ?? ""}
                      placeholder="—"
                      className="w-20 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors"
                    />
                    <span className="text-parchment-dim">/ {assignment.points}</span>
                  </label>
                  <input
                    name="feedback"
                    defaultValue={sub.feedback ?? ""}
                    placeholder="Feedback (optional)"
                    className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm placeholder:text-parchment-dim/60 transition-colors"
                  />
                  <button
                    type="submit"
                    className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
                  >
                    Save
                  </button>
                </form>
              ) : null}
            </li>
          );
        })}
      </ul>
    </main>
  );
}
