import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";
import { getQuizAces } from "@/lib/gamification/engine";

// Lecture screen payload: video meta + published note + published quiz, plus the
// problem sets and lesson drills tagged as covering this lecture. Like the web
// QuizPlayer, quiz grading happens client-side, so correctIndex is included.
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

  // Hall of Aces — everyone who scored 100% on this lecture's quiz (empty if no quiz).
  const aces = quiz.length > 0 ? await getQuizAces(videoId) : [];

  // Problem sets tagged as covering this lecture (many-to-many, so there may be
  // several) — the app's Practice section.
  const problemSets = (
    await db.problemSetVideo.findMany({
      where: { videoId, problemSet: { isDraft: false } },
      include: {
        problemSet: {
          select: { id: true, title: true, points: true, solution: true, solutionsPublic: true },
        },
      },
    })
  ).map(({ problemSet: ps }) => ({
    id: ps.id,
    title: ps.title,
    points: ps.points,
    hasSolutions: ps.solutionsPublic && ps.solution.trim().length > 0,
  }));

  // Lesson drills tagged as covering this lecture. Only the slugs travel: the app
  // resolves title and blurb from its own bundled grammar banks, which are built
  // byte-identical to the web's from content/grammar/. Sending the text too would
  // let a row render for a drill the installed build can't actually play.
  const lessonSlugs = (
    await db.videoLesson.findMany({ where: { videoId }, select: { lessonSlug: true } })
  ).map((l) => l.lessonSlug);

  return ok({ video, note, quiz, aces, problemSets, lessonSlugs });
}
