import { db } from "@/lib/db";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";
import { getSectionGradebook, studentBreakdown } from "@/lib/gradebook";
import { sortLectures } from "@/lib/lectures";

// The app's Progress screen — the mobile half of the web /dashboard. Everything the
// web page computes inline, minus what /me and /me/badges already serve (streak,
// cards due, handle, badges).
//
// Grades come from getSectionGradebook, the SAME function the web dashboard and the
// admin gradebook call, so a student can never see one number in the app and a
// different one on the web. Only this student's own row is returned; the gradebook
// computes every enrolled student's, and the rest is nobody else's business.
export async function GET(req: Request) {
  return withUser(req, async (userId) => {
    const [enrollments, courses, watched] = await Promise.all([
      db.enrollment.findMany({
        where: { userId, status: "active" },
        include: { section: { include: { course: { select: { id: true, title: true } } } } },
        orderBy: { enrolledAt: "desc" },
      }),
      db.course.findMany({
        select: {
          id: true,
          title: true,
          manualOrder: true,
          videos: {
            select: { id: true, title: true, thumbnailUrl: true, position: true, publishedAt: true },
          },
        },
        orderBy: { createdAt: "asc" },
      }),
      db.videoProgress.findMany({ where: { userId }, select: { videoId: true, watchedAt: true } }),
    ]);

    const classes = (
      await Promise.all(
        enrollments.map(async (e) => {
          const gb = await getSectionGradebook(e.sectionId);
          const row = gb?.students.find((s) => s.userId === userId);
          if (!gb || !row) return null;
          return {
            sectionId: e.sectionId,
            sectionName: e.section.name,
            courseId: e.section.course.id,
            courseTitle: e.section.course.title,
            currentGrade: row.currentGrade,
            // Same six categories, in the same order, as the web breakdown.
            attendancePct: row.attendancePct,
            quizAvgPct: row.quizAvgPct,
            hwPct: row.hwPct,
            testPct: row.testPct,
            midtermPct: row.midtermPct,
            finalPct: row.finalPct,
            // Denominators, so the app can show "3/12 lectures" like the class hub.
            watchedCount: row.watchedCount,
            totalLectures: gb.totalLectures,
            quizzesTaken: row.quizzesTaken,
            totalQuizzes: gb.totalQuizzes,
            hwGradedCount: row.hwGradedCount,
            totalAssignments: gb.totalAssignments,
            hasTest: gb.hasTest,
            weights: gb.config.weights,
            // The categories that count in this class (zero weights dropped,
            // custom ones like Tests included), already labelled — preferred
            // over the fixed six above, which older app builds still read.
            categories: studentBreakdown(gb, row),
          };
        }),
      )
    ).filter((c): c is NonNullable<typeof c> => c !== null);

    // Courses the student has started, split the same way the web page splits them:
    // a course counts once at least one lecture is watched, and moves to "completed"
    // only when every lecture is.
    //
    // In-progress entries also carry the next unwatched lecture (in course order)
    // and when the student last watched anything there, for Continue Watching.
    type NextLecture = { id: string; title: string; thumbnailUrl: string | null };
    type CourseEntry = {
      id: string;
      title: string;
      watchedCount: number;
      totalCount: number;
      nextLecture?: NextLecture | null;
      lastWatchedAt?: string | null;
    };
    const watchedAt = new Map(watched.map((p) => [p.videoId, p.watchedAt]));
    const inProgress: CourseEntry[] = [];
    const completed: CourseEntry[] = [];
    for (const c of courses) {
      const totalCount = c.videos.length;
      if (totalCount === 0) continue;
      const watchedCount = c.videos.filter((v) => watchedAt.has(v.id)).length;
      if (watchedCount === 0) continue;
      const entry: CourseEntry = { id: c.id, title: c.title, watchedCount, totalCount };
      if (watchedCount === totalCount) {
        completed.push(entry);
        continue;
      }
      const next = sortLectures(c.videos, c.manualOrder).find((v) => !watchedAt.has(v.id));
      const last = Math.max(...c.videos.map((v) => watchedAt.get(v.id)?.getTime() ?? 0));
      inProgress.push({
        ...entry,
        nextLecture: next ? { id: next.id, title: next.title, thumbnailUrl: next.thumbnailUrl } : null,
        lastWatchedAt: last > 0 ? new Date(last).toISOString() : null,
      });
    }
    // Most recently watched first, as Continue Watching orders them.
    inProgress.sort((a, b) => (b.lastWatchedAt ?? "").localeCompare(a.lastWatchedAt ?? ""));

    return ok({ classes, inProgress, completed });
  });
}
