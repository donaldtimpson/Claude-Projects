import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ProblemSetEditor, { type EditorMode } from "../ProblemSetEditor";

export const dynamic = "force-dynamic";

export default async function EditProblemSetPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>;
  searchParams: Promise<{ mode?: string }>;
}) {
  const { id } = await params;
  // Review (problems beside their solutions) is the default. "edit" is the old
  // name for Source, still used by links and the create redirect.
  const modeParam = (await searchParams).mode;
  const initialMode: EditorMode =
    modeParam === "source" || modeParam === "edit" ? "source" : modeParam === "student" ? "student" : "review";
  const ps = await db.problemSet.findUnique({
    where: { id },
    include: {
      course: { select: { id: true, title: true } },
      videos: { select: { videoId: true } },
    },
  });
  if (!ps) notFound();

  // Every lecture in this set's course, for the "covers lectures" tagger.
  const lectures = await db.video.findMany({
    where: { courseId: ps.course.id },
    orderBy: [{ position: "asc" }],
    select: { id: true, title: true, position: true },
  });

  // Prev/next problem set in this course, by createdAt (import order = 1.1 → 8.6),
  // so the editor can page straight through the sets without going back to the list.
  const [prev, next] = await Promise.all([
    db.problemSet.findFirst({
      where: { courseId: ps.course.id, createdAt: { lt: ps.createdAt } },
      orderBy: { createdAt: "desc" },
      select: { id: true, title: true },
    }),
    db.problemSet.findFirst({
      where: { courseId: ps.course.id, createdAt: { gt: ps.createdAt } },
      orderBy: { createdAt: "asc" },
      select: { id: true, title: true },
    }),
  ]);

  return (
    <main className="max-w-7xl mx-auto px-6 pt-10 space-y-6">
      <div>
        <Link
          href={`/admin/courses/${ps.course.id}/problem-sets`}
          className="text-sm text-parchment-dim hover:text-parchment transition-colors"
        >
          ← {ps.course.title}
        </Link>
      </div>

      {/* Keyed so paging to another set starts from fresh editor state. */}
      <ProblemSetEditor
        key={ps.id}
        ps={{
          id: ps.id,
          title: ps.title,
          body: ps.body,
          solution: ps.solution,
          attachmentUrl: ps.attachmentUrl,
          isDraft: ps.isDraft,
          points: ps.points,
          extraCreditPoints: ps.extraCreditPoints,
          solutionsPublic: ps.solutionsPublic,
          videoIds: ps.videos.map((v) => v.videoId),
        }}
        courseId={ps.course.id}
        lectures={lectures}
        initialMode={initialMode}
        prev={prev}
        next={next}
      />
    </main>
  );
}
