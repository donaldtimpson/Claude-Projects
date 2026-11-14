import { db } from "@/lib/db";
import { ok, badRequest } from "@/lib/mobile/respond";
import { sortLectures } from "@/lib/lectures";

// Published questions for a video quiz (videoId) or a playlist test
// (courseId). Client grades locally, so correctIndex is included.
//
// `reviewCourseId` returns the course review pool instead: every published
// lecture-quiz question in lecture order, then the course test, each tagged with
// its source (the web /courses/[id]/review pool).
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const reviewCourseId = searchParams.get("reviewCourseId");
  if (reviewCourseId) return reviewPool(reviewCourseId);
  const videoId = searchParams.get("videoId");
  const courseId = searchParams.get("courseId");

  const where = videoId
    ? { videoId, isDraft: false }
    : courseId
      ? { courseId, videoId: null, isDraft: false }
      : null;
  if (!where) return badRequest("videoId or courseId is required.");

  const questions = await db.quizQuestion.findMany({
    where,
    orderBy: { position: "asc" },
    select: {
      id: true,
      prompt: true,
      options: true,
      correctIndex: true,
      explanation: true,
      position: true,
    },
  });
  return ok({ questions });
}

const QUESTION = {
  id: true,
  prompt: true,
  options: true,
  correctIndex: true,
  explanation: true,
  position: true,
} as const;

async function reviewPool(courseId: string) {
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: {
      manualOrder: true,
      videos: {
        select: {
          title: true,
          position: true,
          publishedAt: true,
          quizQuestions: { where: { isDraft: false }, orderBy: { position: "asc" }, select: QUESTION },
        },
      },
      quizQuestions: { where: { videoId: null, isDraft: false }, orderBy: { position: "asc" }, select: QUESTION },
    },
  });
  if (!course) return ok({ questions: [] });
  const questions = [
    ...sortLectures(course.videos, course.manualOrder).flatMap((v) =>
      v.quizQuestions.map((q) => ({ ...q, source: v.title })),
    ),
    ...course.quizQuestions.map((q) => ({ ...q, source: "Course Test" })),
  ];
  return ok({ questions });
}
