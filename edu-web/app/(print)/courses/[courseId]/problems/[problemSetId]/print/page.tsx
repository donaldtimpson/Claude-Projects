import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { db } from "@/lib/db";
import MarkdownNotes from "@/components/MarkdownNotes";
import PrintControls from "@/components/PrintControls";
import {
  pairProblemSet,
  canSeeSolutions,
  splitAuthored,
  splitWorkSpaces,
  estimateWorkLines,
} from "@/lib/problem-sets";

// Blank work space for students to work the problem by hand on a printout.
// Deliberately unruled: lines forced students to space equations and matrices
// to the rule height.
function WorkSpace({ inches }: { inches: number }) {
  return <div aria-hidden className="mt-3" style={{ height: `${inches}in` }} />;
}

// The estimate's unit: one "line" of work space.
const LINE_IN = 0.3;

const hasAuthoredSpace = (problem: string) =>
  splitWorkSpaces(problem).some((s) => s.inches !== null);

// Worksheet body of one problem. Authored `[work]` markers leave room under
// each part, and a part stays on one page with its room so a statement never
// sits at the foot of a page with its space overleaf. Without markers, the
// whole problem gets one block sized from its solution.
function WorksheetProblem({ problem, solution }: { problem: string; solution?: string }) {
  if (!hasAuthoredSpace(problem)) {
    return (
      <>
        <MarkdownNotes content={problem} variant="print" />
        <WorkSpace inches={estimateWorkLines(solution) * LINE_IN} />
      </>
    );
  }
  return (
    <>
      {splitWorkSpaces(problem).map((s, i) => (
        <div key={i} className="break-inside-avoid">
          {s.text && <MarkdownNotes content={s.text} variant="print" />}
          {s.inches !== null && <WorkSpace inches={s.inches} />}
        </div>
      ))}
    </>
  );
}

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ problemSetId: string }>;
}): Promise<Metadata> {
  const { problemSetId } = await params;
  const ps = await db.problemSet.findUnique({
    where: { id: problemSetId },
    select: { title: true },
  });
  return { title: ps ? `${ps.title} — Problems` : "Problem Set", robots: { index: false } };
}

async function isAdmin() {
  const cookieStore = await cookies();
  return cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;
}

// Print / PDF view of a problem set. `?solutions=1` interleaves each worked
// solution under the problem it answers — the same pairing the on-site page
// uses, minus the reveal toggles (paper has no toggles). Without the flag it's
// a clean problem sheet to work on.
export default async function PrintProblemSetPage({
  params,
  searchParams,
}: {
  params: Promise<{ courseId: string; problemSetId: string }>;
  searchParams: Promise<{ solutions?: string }>;
}) {
  const { courseId, problemSetId } = await params;
  const wantSolutions = (await searchParams).solutions === "1";

  const ps = await db.problemSet.findUnique({
    where: { id: problemSetId },
    include: { course: { select: { title: true } } },
  });
  if (!ps || ps.courseId !== courseId) notFound();

  // Drafts are printable only by an admin (mirrors the notes print page).
  const admin = ps.isDraft ? await isAdmin() : false;
  if (ps.isDraft && !admin) notFound();

  const allowed = canSeeSolutions({ solutionsPublic: ps.solutionsPublic }) || admin;
  const showSolutions = wantSolutions && allowed && ps.solution.trim().length > 0;
  const paired = pairProblemSet(ps.body, ps.solution, showSolutions);

  // Worksheet mode (no solutions shown): leave ruled work space under each
  // problem, sized from its solution. Keyed the same way as the parts, so we can
  // gauge space per problem even though the solution text itself stays hidden.
  const worksheet = !showSolutions;
  const solutionByKey = new Map(
    worksheet ? splitAuthored(ps.solution.trim()).chunks.map((c) => [c.key, c.content]) : []
  );

  // A heading with no answer (e.g. a "Part II" divider) gets no work space. On a
  // worksheet it's folded into the problem after it, so the two always share a
  // page instead of the heading stranding at the foot of the previous one.
  const isDivider = (key: string) => !key.startsWith("item:") && !solutionByKey.has(key);
  const parts =
    paired.mode === "blocks"
      ? []
      : worksheet
        ? paired.parts.reduce<typeof paired.parts>((acc, p, i, all) => {
            const prev = all[i - 1];
            if (isDivider(p.key) && i + 1 < all.length) return acc;
            if (prev && isDivider(prev.key)) {
              acc.push({ ...p, problem: `${prev.problem}\n\n${p.problem}` });
            } else {
              acc.push(p);
            }
            return acc;
          }, [])
        : paired.parts;

  return (
    <main className="max-w-3xl mx-auto px-8 py-10">
      <PrintControls auto={!ps.isDraft} />

      <header className="mb-8 pb-5 border-b border-zinc-200">
        <div className="flex items-center gap-3">
          {/* Plain <img> (not next/image) so the seal eager-loads before the print dialog fires. */}
          {/* eslint-disable-next-line @next/next/no-img-element */}
          <img
            src="/logo.png"
            alt="The Timpson Lyceum seal"
            width={44}
            height={44}
            className="h-10 w-auto shrink-0"
          />
          <p className="font-display text-xs tracking-[0.2em] uppercase text-zinc-400">
            The Timpson Lyceum · {ps.course.title}
          </p>
        </div>
        <h1 className="font-display text-2xl font-bold text-zinc-900 mt-3">{ps.title}</h1>
        <p className="text-xs text-zinc-500 mt-1">
          {showSolutions ? "Problems with worked solutions" : "Problem sheet"}
          {ps.points > 0 && ` · ${ps.points} points`}
          {ps.extraCreditPoints > 0 && ` · ${ps.extraCreditPoints} extra credit`}
        </p>
      </header>

      {paired.mode === "blocks" ? (
        <>
          <MarkdownNotes content={paired.body} variant="print" />
          {worksheet && <WorkSpace inches={estimateWorkLines(ps.solution) * LINE_IN} />}
          {paired.solution && (
            <section className="mt-10 pt-6 border-t border-zinc-300">
              <h2 className="font-display text-sm tracking-[0.2em] uppercase text-zinc-500 mb-4">
                Solutions
              </h2>
              <MarkdownNotes content={paired.solution} variant="print" />
            </section>
          )}
        </>
      ) : (
        <>
          {paired.problemsPreamble && (
            <MarkdownNotes content={paired.problemsPreamble} variant="print" />
          )}
          <ol className="list-none p-0 m-0">
            {parts.map((p) => (
              // In solutions mode, keep a problem and its answer together on one
              // page. In worksheet mode an estimated work space can be tall, so it
              // flows across the fold; an authored-space problem is sized to fit a
              // page, so it stays whole and its later parts never land a page away
              // from the givens they use.
              <li
                key={p.key}
                className={`mt-6 ${!worksheet || hasAuthoredSpace(p.problem) ? "break-inside-avoid" : ""}`}
              >
                {worksheet && !isDivider(p.key) ? (
                  <WorksheetProblem problem={p.problem} solution={solutionByKey.get(p.key)} />
                ) : (
                  <MarkdownNotes content={p.problem} variant="print" />
                )}
                {p.solution && (
                  <div className="mt-2 pl-4 border-l-2 border-zinc-300">
                    <p className="font-display text-[0.6rem] tracking-[0.2em] uppercase text-zinc-400">
                      Solution
                    </p>
                    <MarkdownNotes content={p.solution} variant="print" />
                  </div>
                )}
              </li>
            ))}
          </ol>
        </>
      )}
    </main>
  );
}
