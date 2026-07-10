import { db } from "@/lib/db";
import { ok, badRequest } from "@/lib/mobile/respond";

// Published questions for a video quiz (videoId) or a playlist test
// (courseId). Client grades locally, so correctIndex is included.
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
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
