import { db } from "@/lib/db";
import { withUser } from "@/lib/mobile/guard";
import { ok } from "@/lib/mobile/respond";
import { getSectionGradebook } from "@/lib/gradebook";

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
        select: { id: true, title: true, videos: { select: { id: true } } },
        orderBy: { createdAt: "asc" },
      }),
      db.videoProgress.findMany({ where: { userId }, select: { videoId: true } }),
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
          };
        }),
      )
    ).filter((c): c is NonNullable<typeof c> => c !== null);

    // Courses the student has started, split the same way the web page splits them:
    // a course counts once at least one lecture is watched, and moves to "completed"
    // only when every lecture is.
    type CourseEntry = { id: string; title: string; watchedCount: number; totalCount: number };
    const watchedIds = new Set(watched.map((p) => p.videoId));
    const inProgress: CourseEntry[] = [];
    const completed: CourseEntry[] = [];
    for (const c of courses) {
      const totalCount = c.videos.length;
      if (totalCount === 0) continue;
      const watchedCount = c.videos.filter((v) => watchedIds.has(v.id)).length;
      if (watchedCount === 0) continue;
      const entry: CourseEntry = { id: c.id, title: c.title, watchedCount, totalCount };
      (watchedCount === totalCount ? completed : inProgress).push(entry);
    }

    return ok({ classes, inProgress, completed });
  });
}
