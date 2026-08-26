import SubmitForm from "@/components/SubmitForm";

// The student's own homework card, shown on a problem set page when that set is
// assigned to a section they're actively enrolled in. Same submit action the
// class hub uses — this just puts it where the work actually gets done, instead
// of making them walk My Progress → class → find the assignment.

export type ProblemSetAssignment = {
  id: string;
  title: string | null;
  points: number;
  dueAt: Date | null;
  sectionId: string;
  sectionName: string;
  sub: { url: string; score: number | null; feedback: string | null } | null;
};

/** One-line "this is homework" strip for the top of the page, anchored to the form below. */
export function HomeworkBanner({ assignments }: { assignments: ProblemSetAssignment[] }) {
  if (assignments.length === 0) return null;
  const a = assignments[0];
  const many = assignments.length > 1;
  const submitted = assignments.every((x) => x.sub);
  return (
    <a
      href="#submit-homework"
      className="flex items-center justify-between gap-4 flex-wrap bg-crimson-900 border border-gold-600/50 hover:border-gold-500 rounded-xl px-4 py-3 transition-colors"
    >
      <span className="text-sm text-parchment">
        <span className="font-display text-[0.65rem] tracking-[0.2em] uppercase text-gold-400 mr-2">
          Homework
        </span>
        {many
          ? `Assigned in ${assignments.length} of your classes`
          : `Assigned in ${a.sectionName}`}
        {!many && a.dueAt && (
          <span className="text-parchment-dim"> · due {new Date(a.dueAt).toLocaleString()}</span>
        )}
      </span>
      <span className="text-xs text-gold-400 shrink-0">
        {submitted ? "Change your submission ↓" : "Turn it in ↓"}
      </span>
    </a>
  );
}

/** The submit card itself — one per assignment (a student in two sections gets two). */
export default function ProblemSetHomework({
  assignments,
}: {
  assignments: ProblemSetAssignment[];
}) {
  if (assignments.length === 0) return null;
  const now = Date.now();

  return (
    <section id="submit-homework" className="space-y-3 pt-4 border-t border-crimson-700">
      <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400">
        Turn in your homework
      </h2>
      <ul className="space-y-3">
        {assignments.map((a) => {
          const graded = a.sub && a.sub.score !== null;
          const late = !a.sub && a.dueAt !== null && new Date(a.dueAt).getTime() < now;
          return (
            <li key={a.id} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
              <div className="flex items-start justify-between gap-4 flex-wrap">
                <div className="min-w-0">
                  <p className="font-medium text-parchment">{a.title ?? "Homework"}</p>
                  <p className="text-xs text-parchment-dim mt-0.5">
                    {a.sectionName} ·{" "}
                    <span className={late ? "text-red-400" : undefined}>
                      {a.dueAt ? `Due ${new Date(a.dueAt).toLocaleString()}` : "No due date"}
                    </span>{" "}
                    · {a.points} pts
                  </p>
                </div>
                {graded ? (
                  <span className="text-sm text-gold-300 shrink-0">
                    {a.sub!.score}/{a.points}
                  </span>
                ) : a.sub ? (
                  <span className="text-xs text-green-400 shrink-0">submitted · awaiting grade</span>
                ) : (
                  <span className={`text-xs shrink-0 ${late ? "text-red-400" : "text-parchment-dim"}`}>
                    {late ? "past due · not submitted" : "not submitted"}
                  </span>
                )}
              </div>
              {graded && a.sub!.feedback && (
                <p className="text-sm text-parchment-dim border-l-2 border-crimson-700 pl-3">
                  {a.sub!.feedback}
                </p>
              )}
              <SubmitForm assignmentId={a.id} currentUrl={a.sub?.url ?? null} />
            </li>
          );
        })}
      </ul>
      <p className="text-xs text-parchment-dim">
        Your grade and every other assignment live in{" "}
        <a href="/dashboard" className="text-gold-400 hover:text-gold-300 transition-colors">
          My Progress
        </a>
        .
      </p>
    </section>
  );
}
