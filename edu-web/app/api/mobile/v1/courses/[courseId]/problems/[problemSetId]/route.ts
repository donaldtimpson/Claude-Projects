import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";
import { pairProblemSet, canSeeSolutions } from "@/lib/problem-sets";

// Problem-set detail for the mobile app.
//
// The problem↔solution pairing runs HERE rather than in Swift: the split rules
// (numbered items, named sections, heading normalization, the fallback when the
// two halves don't line up) are subtle enough that a second implementation would
// drift from the web's. The client just renders what it's handed.
//
// Withheld solutions are stripped server-side, so a solution the viewer may not
// see is never sent to the device at all.
export async function GET(
  _req: Request,
  { params }: { params: Promise<{ courseId: string; problemSetId: string }> },
) {
  const { courseId, problemSetId } = await params;

  const ps = await db.problemSet.findFirst({
    where: { id: problemSetId, courseId, isDraft: false },
    select: {
      id: true,
      title: true,
      body: true,
      solution: true,
      solutionsPublic: true,
      points: true,
      extraCreditPoints: true,
      attachmentUrl: true,
      updatedAt: true,
      videos: {
        select: { video: { select: { id: true, title: true, position: true } } },
      },
    },
  });
  if (!ps) return fail(404, "Problem set not found.");

  const solutionsAvailable =
    canSeeSolutions({ solutionsPublic: ps.solutionsPublic }) && ps.solution.trim().length > 0;
  const content = pairProblemSet(ps.body, ps.solution, solutionsAvailable);

  return ok({
    problemSet: {
      id: ps.id,
      title: ps.title,
      points: ps.points,
      extraCreditPoints: ps.extraCreditPoints,
      attachmentUrl: ps.attachmentUrl,
      updatedAt: ps.updatedAt,
      solutionsAvailable,
      lectures: ps.videos
        .map((v) => v.video)
        .sort((a, b) => a.position - b.position),
      content,
    },
  });
}
