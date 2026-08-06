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

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-6">
      <div>
        <Link
          href={`/admin/problem-sets/course/${ps.course.id}`}
          className="text-sm text-parchment-dim hover:text-parchment transition-colors"
        >
          ← {ps.course.title}
        </Link>
      </div>

      <ProblemSetEditor
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
      />
    </main>
  );
}
