import { db } from "@/lib/db";
import { ok, fail } from "@/lib/mobile/respond";
import { getQuizAces } from "@/lib/gamification/engine";
import { requireMobileUser } from "@/lib/mobile-auth";
import { formatLabel, isTestTitle, lectureLabels, sortLectures } from "@/lib/lectures";

// Lecture screen payload: video meta + published note + published quiz, plus the
// problem sets and lesson drills tagged as covering this lecture. Like the web
// QuizPlayer, quiz grading happens client-side, so correctIndex is included.
// Also: the lecture's label and its neighbours (prev/next in course order), and
// for a signed-in caller whether they've marked it watched.
export async function GET(
  req: Request,
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

  // Course order, for the label and prev/next.
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: {
      manualOrder: true,
      _count: { select: { quizQuestions: { where: { videoId: null, isDraft: false } } } },
      videos: { select: { id: true, title: true, position: true, publishedAt: true } },
    },
  });
  const ordered = sortLectures(course?.videos ?? [], course?.manualOrder ?? false);
  const labels = lectureLabels(ordered);
  const idx = ordered.findIndex((v) => v.id === videoId);
  const neighbour = (v: (typeof ordered)[number] | undefined) =>
    v ? { id: v.id, title: v.title, label: formatLabel(labels.get(v.id)!) } : null;

  const userId = await requireMobileUser(req);
  const watched = userId
    ? (await db.videoProgress.count({ where: { userId, videoId } })) > 0
    : null;

  return ok({
    video: { ...video, label: labels.get(videoId) ? formatLabel(labels.get(videoId)!) : null },
    note,
    quiz,
    aces,
    // Numeric title order, so "2.10" follows "2.9".
    problemSets: problemSets
      .map((ps) => ({ ...ps, isTest: isTestTitle(ps.title) }))
      .sort((a, b) => a.title.localeCompare(b.title, undefined, { numeric: true })),
    lessonSlugs,
    prev: neighbour(ordered[idx - 1]),
    next: idx >= 0 ? neighbour(ordered[idx + 1]) : null,
    // The last lecture leads into the course test, as on the web.
    courseTestQuestionCount: course?._count.quizQuestions ?? 0,
    watched,
  });
}
