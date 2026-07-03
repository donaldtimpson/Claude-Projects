import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import { updateProblemSet, deleteProblemSet } from "@/lib/assignments";

export const dynamic = "force-dynamic";

export default async function EditProblemSetPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = await params;
  const ps = await db.problemSet.findUnique({
    where: { id },
    include: { course: { select: { id: true, title: true } } },
  });
  if (!ps) notFound();

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-6">
      <div>
        <Link href="/admin/problem-sets" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Problem Sets
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-2">Edit problem set</h1>
        <p className="text-sm text-parchment-dim mt-1">
          {ps.course.title} ·{" "}
          <Link
            href={`/courses/${ps.course.id}/problems/${ps.id}`}
            target="_blank"
            className="hover:text-gold-300 transition-colors"
          >
            view public page ↗
          </Link>
        </p>
      </div>

      <form action={updateProblemSet} className="space-y-3">
        <input type="hidden" name="id" value={ps.id} />
        <input
          name="title"
          required
          defaultValue={ps.title}
          className="w-full bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment transition-colors"
        />
        <textarea
          name="body"
          rows={16}
          defaultValue={ps.body}
          placeholder="Problem text — Markdown + $…$ / $$…$$ math."
          className="w-full bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment font-mono text-sm transition-colors"
        />
        <input
          name="attachmentUrl"
          defaultValue={ps.attachmentUrl ?? ""}
          placeholder="Optional attachment URL"
          className="w-full bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
        />
        <button
          type="submit"
          className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
        >
          Save
        </button>
      </form>

      <form action={deleteProblemSet} className="pt-4 border-t border-crimson-800">
        <input type="hidden" name="id" value={ps.id} />
        <button
          type="submit"
          className="text-sm text-parchment-dim hover:text-red-400 transition-colors"
        >
          Delete this problem set
        </button>
      </form>
    </main>
  );
}
