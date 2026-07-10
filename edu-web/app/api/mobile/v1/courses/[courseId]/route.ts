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
      description: true,
      thumbnailUrl: true,
      videoCount: true,
      isCurrent: true,
      updatedAt: true,
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
        select: { id: true, title: true, points: true, attachmentUrl: true },
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

  const { resources, ...rest } = course;
  return ok({
    course: {
      ...rest,
      resources: resources.map((r) => ({ position: r.position, ...r.resource })),
    },
  });
}
