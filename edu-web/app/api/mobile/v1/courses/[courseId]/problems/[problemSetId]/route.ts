import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";
import { pairProblemSet, canSeeSolutions } from "@/lib/problem-sets";
import { requireMobileUser } from "@/lib/mobile-auth";
import { formatLabel, isTestTitle, lectureLabels, sortLectures } from "@/lib/lectures";

// Problem-set detail for the mobile app.
//
// The problem↔solution pairing runs HERE rather than in Swift: the split rules
// (numbered items, named sections, heading normalization, the fallback when the
// two halves don't line up) are subtle enough that a second implementation would
// drift from the web's. The client just renders what it's handed.
//
// Withheld solutions are stripped server-side, so a solution the viewer may not
// see is never sent to the device at all.
//
// A signed-in student enrolled in a section that assigned this set also gets
// `homework`: each such assignment with their submission, so the app can offer
// "turn it in" right where the problems are, as the web page does.
export async function GET(
  req: Request,
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

  // Covered lectures, in course order and labelled like the course page.
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: { manualOrder: true, videos: { select: { id: true, title: true, position: true, publishedAt: true } } },
  });
  const ordered = sortLectures(course?.videos ?? [], course?.manualOrder ?? false);
  const labels = lectureLabels(ordered);
  const coveredIds = new Set(ps.videos.map((v) => v.video.id));
  const lectures = ordered
    .filter((v) => coveredIds.has(v.id))
    .map((v) => ({
      id: v.id,
      title: v.title,
      position: v.position,
      label: formatLabel(labels.get(v.id)!),
    }));

  const userId = await requireMobileUser(req);
  const homework = userId
    ? (
        await db.assignment.findMany({
          where: {
            problemSetId: ps.id,
            section: { enrollments: { some: { userId, status: "active" } } },
          },
          orderBy: [{ dueAt: "asc" }, { createdAt: "asc" }],
          select: {
            id: true,
            title: true,
            points: true,
            dueAt: true,
            sectionId: true,
            section: { select: { name: true } },
            submissions: {
              where: { userId },
              select: { url: true, submittedAt: true, score: true, feedback: true, gradedAt: true },
            },
          },
        })
      ).map((a) => {
        const sub = a.submissions[0] ?? null;
        return {
          id: a.id,
          title: a.title ?? ps.title,
          points: a.points,
          dueAt: a.dueAt ? a.dueAt.toISOString() : null,
          sectionId: a.sectionId,
          sectionName: a.section.name,
          submission: sub
            ? {
                url: sub.url,
                submittedAt: sub.submittedAt.toISOString(),
                score: sub.score,
                feedback: sub.feedback,
                gradedAt: sub.gradedAt ? sub.gradedAt.toISOString() : null,
              }
            : null,
        };
      })
    : [];

  return ok({
    problemSet: {
      id: ps.id,
      title: ps.title,
      points: ps.points,
      extraCreditPoints: ps.extraCreditPoints,
      attachmentUrl: ps.attachmentUrl,
      updatedAt: ps.updatedAt,
      solutionsAvailable,
      isTest: isTestTitle(ps.title),
      lectures,
      content,
      homework,
    },
  });
}
