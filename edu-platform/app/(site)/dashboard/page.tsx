import { redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import AttemptRow from "@/components/AttemptRow";

export const dynamic = "force-dynamic";

function formatDate(iso: Date) {
  return iso.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
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

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Video Quizzes
          </h2>
          {videoAttempts.length === 0 ? (
            <p className="text-parchment-dim text-sm">No quiz attempts yet.</p>
          ) : (
            <ul className="space-y-3">
              {videoAttempts.map((a) => {
                const courseId = a.video?.courseId ?? a.video?.course?.id;
                const videoId = a.video?.id;
                return (
                  <li key={a.id}>
                    <AttemptRow
                      attemptId={a.id}
                      label={a.video?.title ?? "Unknown video"}
                      subtitle={a.video?.course?.title}
                      subtitleHref={courseId && videoId ? `/courses/${courseId}/${videoId}` : undefined}
                      date={formatDate(a.completedAt)}
                      score={a.score}
                      total={a.totalQuestions}
                    />
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Playlist Tests
          </h2>
          {testAttempts.length === 0 ? (
            <p className="text-parchment-dim text-sm">No test attempts yet.</p>
          ) : (
            <ul className="space-y-3">
              {testAttempts.map((a) => (
                <li key={a.id}>
                  <AttemptRow
                    attemptId={a.id}
                    label="Playlist Test"
                    subtitle={a.course?.title}
                    subtitleHref={a.course ? `/courses/${a.course.id}/test` : undefined}
                    date={formatDate(a.completedAt)}
                    score={a.score}
                    total={a.totalQuestions}
                  />
                </li>
              ))}
            </ul>
          )}
        </section>
      </div>
    </main>
  );
}
