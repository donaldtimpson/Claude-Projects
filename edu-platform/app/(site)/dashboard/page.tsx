import { redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";

export const dynamic = "force-dynamic";

function formatDate(iso: Date) {
  return iso.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
}

function pct(score: number, total: number) {
  return Math.round((score / total) * 100);
}

function scoreColor(p: number) {
  if (p === 100) return "text-green-400";
  if (p >= 70) return "text-gold-400";
  return "text-red-400";
}

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) redirect("/auth/signin");

  const attempts = await db.quizAttempt.findMany({
    where: { userId: session.user.id },
    include: {
      video: {
        select: {
          id: true,
          title: true,
          courseId: true,
          course: { select: { id: true, title: true } },
        },
      },
      course: { select: { id: true, title: true } },
    },
    orderBy: { completedAt: "desc" },
  });

  const videoAttempts = attempts.filter((a) => a.videoId !== null);
  const testAttempts = attempts.filter((a) => a.courseId !== null && a.videoId === null);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10 space-y-12">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">My Progress</h1>
          <p className="text-parchment-dim text-sm">
            Signed in as <span className="text-parchment">{session.user.name}</span>
          </p>
        </div>

        {/* Video Quizzes */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Video Quizzes
          </h2>
          {videoAttempts.length === 0 ? (
            <p className="text-parchment-dim text-sm">No quiz attempts yet.</p>
          ) : (
            <ul className="space-y-3">
              {videoAttempts.map((a) => {
                const p = pct(a.score, a.totalQuestions);
                const courseId = a.video?.courseId ?? a.video?.course?.id;
                const videoId = a.video?.id;
                return (
                  <li key={a.id}>
                    <Link
                      href={`/dashboard/attempt/${a.id}`}
                      className="group bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center gap-4 hover:border-gold-500 transition-colors"
                    >
                      <div className="flex-1 min-w-0">
                        {a.video?.course && courseId && videoId && (
                          <Link
                            href={`/courses/${courseId}/${videoId}`}
                            onClick={(e) => e.stopPropagation()}
                            className="text-xs text-parchment-dim hover:text-gold-300 transition-colors mb-0.5 block truncate"
                          >
                            {a.video.course.title} ↗
                          </Link>
                        )}
                        <p className="text-sm font-medium text-parchment group-hover:text-gold-300 transition-colors line-clamp-1">
                          {a.video?.title ?? "Unknown video"}
                        </p>
                        <p className="text-xs text-parchment-dim mt-0.5">{formatDate(a.completedAt)}</p>
                      </div>
                      <div className="text-right shrink-0">
                        <p className={`text-lg font-bold ${scoreColor(p)}`}>
                          {a.score}/{a.totalQuestions}
                        </p>
                        <p className={`text-xs ${scoreColor(p)}`}>{p}%</p>
                      </div>
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        {/* Playlist Tests */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Playlist Tests
          </h2>
          {testAttempts.length === 0 ? (
            <p className="text-parchment-dim text-sm">No test attempts yet.</p>
          ) : (
            <ul className="space-y-3">
              {testAttempts.map((a) => {
                const p = pct(a.score, a.totalQuestions);
                return (
                  <li key={a.id}>
                    <Link
                      href={`/dashboard/attempt/${a.id}`}
                      className="group bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center gap-4 hover:border-gold-500 transition-colors"
                    >
                      <div className="flex-1 min-w-0">
                        {a.course && (
                          <Link
                            href={`/courses/${a.course.id}/test`}
                            onClick={(e) => e.stopPropagation()}
                            className="text-xs text-parchment-dim hover:text-gold-300 transition-colors mb-0.5 block truncate"
                          >
                            {a.course.title} ↗
                          </Link>
                        )}
                        <p className="text-sm font-medium text-parchment group-hover:text-gold-300 transition-colors">
                          Playlist Test
                        </p>
                        <p className="text-xs text-parchment-dim mt-0.5">{formatDate(a.completedAt)}</p>
                      </div>
                      <div className="text-right shrink-0">
                        <p className={`text-lg font-bold ${scoreColor(p)}`}>
                          {a.score}/{a.totalQuestions}
                        </p>
                        <p className={`text-xs ${scoreColor(p)}`}>{p}%</p>
                      </div>
                    </Link>
                  </li>
                );
              })}
            </ul>
          )}
        </section>
      </div>
    </main>
  );
}
