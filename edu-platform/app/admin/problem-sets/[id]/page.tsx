import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ProblemSetEditor from "../ProblemSetEditor";

export const dynamic = "force-dynamic";

export default async function EditProblemSetPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ mode?: string }>;
}) {
  const { id } = await params;
  const initialMode = (await searchParams).mode === "edit" ? "edit" : "preview";
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
        <p className="text-sm text-parchment-dim mt-2">{ps.course.title}</p>
      </div>

      <ProblemSetEditor
        ps={{
          id: ps.id,
          title: ps.title,
          body: ps.body,
          solution: ps.solution,
          attachmentUrl: ps.attachmentUrl,
          isDraft: ps.isDraft,
        }}
        courseId={ps.course.id}
        initialMode={initialMode}
      />
    </main>
  );
}
