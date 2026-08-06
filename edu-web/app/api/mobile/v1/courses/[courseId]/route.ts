import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";

// Course detail: ordered videos, published problem sets, and attached resources.
export async function GET(
  _req: Request,
  { params }: { params: Promise<{ courseId: string }> },
) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: {
      id: true,
      title: true,
      shortTitle: true,
      description: true,
      thumbnailUrl: true,
      videoCount: true,
      isCurrent: true,
      updatedAt: true,
      canonicalCourseId: true,
      videos: {
        orderBy: { position: "asc" },
        select: {
          id: true,
          youtubeVideoId: true,
          title: true,
          position: true,
          durationSeconds: true,
          thumbnailUrl: true,
        },
      },
      problemSets: {
        where: { isDraft: false },
        orderBy: { createdAt: "asc" },
        select: {
          id: true,
          title: true,
          points: true,
          attachmentUrl: true,
          // `solution` is selected only to derive hasSolutions below — the text
          // itself is never sent in the list payload.
          solution: true,
          solutionsPublic: true,
          videos: { select: { video: { select: { position: true } } } },
        },
      },
      resources: {
        orderBy: { position: "asc" },
        select: {
          position: true,
          resource: { select: { id: true, title: true, url: true, kind: true } },
        },
      },
    },
  });
  if (!course) return fail(404, "Course not found.");

  // Other offerings of the same subject. All versions = the representative
  // (canonicalCourseId null) + its siblings; exclude the one being viewed.
  const repId = course.canonicalCourseId ?? course.id;
  const group = await db.course.findMany({
    where: { OR: [{ id: repId }, { canonicalCourseId: repId }], NOT: { id: course.id } },
    orderBy: { publishedAt: "desc" },
    select: { id: true, title: true, publishedAt: true },
  });
  const offerings = group.map((c) => ({
    id: c.id,
    title: c.title,
    year: c.publishedAt ? c.publishedAt.getUTCFullYear() : null,
  }));

  const { resources, problemSets, canonicalCourseId: _canon, ...rest } = course;
  return ok({
    course: {
      ...rest,
      problemSets: problemSets.map((ps) => {
        const positions = ps.videos.map((v) => v.video.position).sort((a, b) => a - b);
        return {
          id: ps.id,
          title: ps.title,
          points: ps.points,
          attachmentUrl: ps.attachmentUrl,
          hasSolutions: ps.solutionsPublic && ps.solution.trim().length > 0,
          // Lecture positions this set covers, for a "Lectures 4–5" subtitle.
          lecturePositions: positions,
        };
      }),
      resources: resources.map((r) => ({ position: r.position, ...r.resource })),
      offerings,
    },
  });
}
