import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";
import { requireMobileUser } from "@/lib/mobile-auth";
import { isTestTitle, formatLabel, lectureLabels, lectureSpan, sortLectures } from "@/lib/lectures";

// Course detail: ordered videos, published problem sets, and attached resources.
// Lecture order and labels come from lib/lectures (shared with the web course
// page). Signed-in callers also get `viewer`: watched lectures and their class.
export async function GET(
  req: Request,
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
      syllabus: true,
      thumbnailUrl: true,
      videoCount: true,
      isCurrent: true,
      manualOrder: true,
      updatedAt: true,
      canonicalCourseId: true,
      // Published course-level questions — the course test. videoId: null is what
      // distinguishes them from the per-lecture quizzes. The app needs the count to
      // decide whether to offer the test at all, exactly as the web course page does.
      _count: { select: { quizQuestions: { where: { videoId: null, isDraft: false } } } },
      videos: {
        select: {
          id: true,
          youtubeVideoId: true,
          title: true,
          position: true,
          publishedAt: true,
          durationSeconds: true,
          thumbnailUrl: true,
          _count: { select: { comments: { where: { deletedAt: null } } } },
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
          videos: { select: { video: { select: { id: true, position: true } } } },
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

  const ordered = sortLectures(course.videos, course.manualOrder);
  const labels = lectureLabels(ordered);

  // Course review drills every published question: each lecture's quiz plus the test.
  const reviewQuestionCount = await db.quizQuestion.count({
    where: { isDraft: false, OR: [{ courseId, videoId: null }, { video: { courseId } }] },
  });

  // Connections live on the subject's representative course.
  const links = await db.courseLink.findMany({
    where: { OR: [{ fromCourseId: repId }, { toCourseId: repId }] },
    select: {
      kind: true,
      fromCourseId: true,
      toCourseId: true,
      fromCourse: { select: { id: true, title: true } },
      toCourse: { select: { id: true, title: true } },
    },
  });
  const connections = {
    buildsOn: links.filter((l) => l.kind === "RECOMMENDED" && l.toCourseId === repId).map((l) => l.fromCourse),
    leadsTo: links.filter((l) => l.kind === "RECOMMENDED" && l.fromCourseId === repId).map((l) => l.toCourse),
    related: links
      .filter((l) => l.kind === "RELATED")
      .map((l) => (l.fromCourseId === repId ? l.toCourse : l.fromCourse)),
  };

  // Viewer state. Registration never gates the materials; it only records who is
  // in the live class. The code form is offered on the current course when a
  // section exists and the viewer isn't already in one.
  const userId = await requireMobileUser(req);
  let watchedVideoIds: string[] = [];
  let enrollment: { sectionId: string; sectionName: string } | null = null;
  if (userId) {
    const [progress, enr] = await Promise.all([
      db.videoProgress.findMany({
        where: { userId, videoId: { in: ordered.map((v) => v.id) } },
        select: { videoId: true },
      }),
      db.enrollment.findFirst({
        where: { userId, status: "active", section: { courseId } },
        select: { sectionId: true, section: { select: { name: true } } },
      }),
    ]);
    watchedVideoIds = progress.map((p) => p.videoId);
    if (enr) enrollment = { sectionId: enr.sectionId, sectionName: enr.section.name };
  }
  const registrationOpen =
    course.isCurrent && !enrollment && (await db.section.count({ where: { courseId } })) > 0;

  const {
    resources,
    problemSets,
    canonicalCourseId: _canon,
    _count,
    manualOrder: _manual,
    videos: _videos,
    ...rest
  } = course;
  return ok({
    course: {
      ...rest,
      videos: ordered.map(({ _count: c, publishedAt: _p, ...v }) => ({
        ...v,
        // "Lecture 3" / "Lesson 9": the number students see on the video.
        label: formatLabel(labels.get(v.id)!),
        commentCount: c.comments,
      })),
      testQuestionCount: _count.quizQuestions,
      reviewQuestionCount,
      problemSets: problemSets.map((ps) => {
        const positions = ps.videos.map((v) => v.video.position).sort((a, b) => a - b);
        return {
          id: ps.id,
          title: ps.title,
          points: ps.points,
          attachmentUrl: ps.attachmentUrl,
          hasSolutions: ps.solutionsPublic && ps.solution.trim().length > 0,
          isTest: isTestTitle(ps.title),
          // "Lectures 4–5", labelled like the lectures themselves.
          lectureSpan: lectureSpan(
            ps.videos.map((v) => v.video.id),
            ordered,
            labels,
          ),
          // Deprecated: raw positions, still read by app builds before 1.1.
          lecturePositions: positions,
        };
      }),
      resources: resources.map((r) => ({ position: r.position, ...r.resource })),
      offerings,
      connections,
      registrationOpen,
      viewer: userId ? { watchedVideoIds, enrollment } : null,
    },
  });
}
