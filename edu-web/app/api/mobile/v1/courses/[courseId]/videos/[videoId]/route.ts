import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";

// Lecture screen payload: video meta + published note + published quiz. Like the
// web QuizPlayer, quiz grading happens client-side, so correctIndex is included.
export async function GET(
  _req: Request,
  { params }: { params: Promise<{ courseId: string; videoId: string }> },
) {
  const { courseId, videoId } = await params;
  const video = await db.video.findFirst({
    where: { id: videoId, courseId },
    select: {
      id: true,
      youtubeVideoId: true,
      title: true,
      description: true,
      position: true,
      durationSeconds: true,
      updatedAt: true,
    },
  });
  if (!video) return fail(404, "Lecture not found.");

  const [note, quiz] = await Promise.all([
    db.lectureNote.findFirst({
      where: { videoId, isDraft: false },
      select: { content: true, updatedAt: true },
    }),
    db.quizQuestion.findMany({
      where: { videoId, isDraft: false },
      orderBy: { position: "asc" },
      select: {
        id: true,
        prompt: true,
        options: true,
        correctIndex: true,
        explanation: true,
        position: true,
      },
    }),
  ]);

  return ok({ video, note, quiz });
}
