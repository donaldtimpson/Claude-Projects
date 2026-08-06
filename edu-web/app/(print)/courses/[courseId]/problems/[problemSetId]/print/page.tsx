import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { cookies } from "next/headers";
import { db } from "@/lib/db";
import MarkdownNotes from "@/components/MarkdownNotes";
import PrintControls from "@/components/PrintControls";
import { pairProblemSet, canSeeSolutions } from "@/lib/problem-sets";

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
          {paired.solutionPreamble && showSolutions && (
            <MarkdownNotes content={paired.solutionPreamble} variant="print" />
          )}
          <ol className="list-none p-0 m-0">
            {paired.parts.map((p) => (
              // break-inside-avoid keeps a problem and its answer on one page
              // where it fits, instead of splitting across the fold.
              <li key={p.key} className="mt-6 break-inside-avoid">
                <MarkdownNotes content={p.problem} variant="print" />
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
