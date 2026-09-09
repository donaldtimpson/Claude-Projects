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

  // Keep edit/preview mode as you page through.
  const modeSuffix = initialMode === "edit" ? "?mode=edit" : "";
  const navBtn =
    "text-sm text-gold-400 hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors max-w-[45%] truncate";
  const nav = (
    <nav className="flex items-center justify-between gap-3">
      {prev ? (
        <Link href={`/admin/problem-sets/${prev.id}${modeSuffix}`} className={navBtn}>
          ← {prev.title}
        </Link>
      ) : (
        <span className="text-sm text-parchment-dim/50 px-3 py-1.5">← Start</span>
      )}
      {next ? (
        <Link href={`/admin/problem-sets/${next.id}${modeSuffix}`} className={navBtn}>
          {next.title} →
        </Link>
      ) : (
        <span className="text-sm text-parchment-dim/50 px-3 py-1.5">End →</span>
      )}
    </nav>
  );

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

      {nav}

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

      {nav}
    </main>
  );
}
