import { notFound, redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import AttemptRow from "@/components/AttemptRow";

export const dynamic = "force-dynamic";

function formatDate(iso: Date) {
  return iso.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

export default async function DashboardCoursePage({
  params,
}: {
  params: Promise<{ courseId: string }>;
}) {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) redirect("/auth/signin");

  const { courseId } = await params;
  const userId = session.user.id;

  const [course, progressRows, videoAttempts, testAttempts] = await Promise.all([
    db.course.findUnique({
      where: { id: courseId },
      include: {
        videos: { orderBy: { position: "asc" }, select: { id: true, title: true } },
        _count: { select: { quizQuestions: true } },
      },
    }),
    db.videoProgress.findMany({
      where: { userId, video: { courseId } },
      select: { videoId: true },
    }),
    db.quizAttempt.findMany({
      where: { userId, video: { courseId } },
      include: {
        video: { select: { id: true, title: true, courseId: true } },
      },
      orderBy: { completedAt: "desc" },
    }),
    db.quizAttempt.findMany({
      where: { userId, courseId, videoId: null },
      orderBy: { completedAt: "desc" },
    }),
  ]);

  if (!course) notFound();

  const watchedSet = new Set(progressRows.map((p) => p.videoId));
  const watchedCount = watchedSet.size;
  const totalCount = course.videos.length;
  const pct = totalCount > 0 ? Math.round((watchedCount / totalCount) * 100) : 0;
  const isComplete = watchedCount === totalCount && totalCount > 0;

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/dashboard" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← My Progress
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10 space-y-10">
        {/* Course header */}
        <div className="space-y-4">
          <div className="space-y-1">
            <p className="text-sm text-parchment-dim">Course Progress</p>
            <h1 className="text-2xl font-bold text-parchment">
              <Link
                href={`/courses/${course.id}`}
                className="hover:text-gold-300 transition-colors"
              >
                {course.title}
              </Link>
            </h1>
          </div>

          {/* Progress bar */}
          <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-2">
            <div className="flex justify-between text-xs">
              <span className="text-parchment-dim">{watchedCount} / {totalCount} lectures watched</span>
              <span className={isComplete ? "text-green-400 font-medium" : "text-parchment-dim"}>
                {isComplete ? "Complete ✓" : `${pct}%`}
              </span>
            </div>
            <div className="h-2 bg-crimson-800 rounded-full overflow-hidden">
              <div
                className={`h-full rounded-full transition-all ${isComplete ? "bg-green-500" : "bg-gold-500"}`}
                style={{ width: `${pct}%` }}
              />
            </div>
          </div>
        </div>

        {/* Video quiz attempts */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Video Quizzes
          </h2>
          {videoAttempts.length === 0 ? (
            <p className="text-parchment-dim text-sm">No quiz attempts yet.</p>
          ) : (
            <ul className="space-y-3">
              {videoAttempts.map((a) => (
                <li key={a.id}>
                  <AttemptRow
                    attemptId={a.id}
                    label={a.video?.title ?? "Unknown video"}
                    subtitleHref={
                      a.video ? `/courses/${a.video.courseId}/${a.video.id}` : undefined
                    }
                    date={formatDate(a.completedAt)}
                    score={a.score}
                    total={a.totalQuestions}
                  />
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Playlist test attempts */}
        {course._count.quizQuestions > 0 && (
          <section className="space-y-4">
            <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
              Playlist Tests
            </h2>
            {testAttempts.length === 0 ? (
              <div className="space-y-2">
                <p className="text-parchment-dim text-sm">No test attempts yet.</p>
                <Link
                  href={`/courses/${courseId}/test`}
                  className="inline-block text-sm text-gold-400 hover:text-gold-300 transition-colors"
                >
                  Take the playlist test →
                </Link>
              </div>
            ) : (
              <ul className="space-y-3">
                {testAttempts.map((a) => (
                  <li key={a.id}>
                    <AttemptRow
                      attemptId={a.id}
                      label="Playlist Test"
                      subtitleHref={`/courses/${courseId}/test`}
                      date={formatDate(a.completedAt)}
                      score={a.score}
                      total={a.totalQuestions}
                    />
                  </li>
                ))}
              </ul>
            )}
          </section>
        )}
      </div>
    </main>
  );
}
