import { redirect } from "next/navigation";
import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { generateHandle, getUserBadges, getStreak } from "@/lib/gamification/engine";
import { getDueCount } from "@/lib/srs";
import HandleForm from "./HandleForm";
import AchievementsGrid from "../leaderboard/AchievementsGrid";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) redirect("/auth/signin");

  const userId = session.user.id;

  const [courses, allProgress, me, myBadges, streak, dueCount] = await Promise.all([
    db.course.findMany({
      include: { videos: { select: { id: true }, orderBy: { position: "asc" } } },
      orderBy: { createdAt: "asc" },
    }),
    db.videoProgress.findMany({
      where: { userId },
      select: { videoId: true },
    }),
    db.user.findUnique({ where: { id: userId }, select: { handle: true } }),
    getUserBadges(userId),
    getStreak(userId),
    getDueCount(userId),
  ]);

  const handlePlaceholder = generateHandle(userId);

  const watchedSet = new Set(allProgress.map((p) => p.videoId));

  type CourseEntry = { id: string; title: string; watchedCount: number; totalCount: number };
  const inProgress: CourseEntry[] = [];
  const completed: CourseEntry[] = [];

  for (const course of courses) {
    const totalCount = course.videos.length;
    if (totalCount === 0) continue;
    const watchedCount = course.videos.filter((v) => watchedSet.has(v.id)).length;
    if (watchedCount === 0) continue;
    const entry: CourseEntry = { id: course.id, title: course.title, watchedCount, totalCount };
    if (watchedCount === totalCount) {
      completed.push(entry);
    } else {
      inProgress.push(entry);
    }
  }

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

        <div className="bg-crimson-900 border border-gold-500 rounded-xl p-5 flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-2xl font-bold text-gold-300">
              {streak.count > 0 ? `🔥 ${streak.count}-day streak` : "Start your streak today"}
            </p>
            <p className="text-sm text-parchment-dim mt-1">
              {dueCount > 0
                ? `${dueCount} card${dueCount === 1 ? "" : "s"} due for review`
                : streak.activeToday
                  ? "All caught up — see you tomorrow"
                  : "Study anything today to keep your streak alive"}
            </p>
          </div>
          <Link
            href="/review"
            className="px-5 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors shrink-0"
          >
            {dueCount > 0 ? "Start daily review" : "Open review"}
          </Link>
        </div>

        <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 flex flex-wrap items-center justify-between gap-4">
          <div>
            <p className="text-parchment font-medium">Sharpen your skills</p>
            <p className="text-sm text-parchment-dim mt-1">
              Endless timed practice — arithmetic, the unit circle, and vector components.
            </p>
          </div>
          <Link
            href="/drills"
            className="px-5 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors shrink-0"
          >
            Practice drills
          </Link>
        </div>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Your Handle
          </h2>
          <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-3">
            <p className="text-sm text-parchment-dim">
              The only name shown publicly in the{" "}
              <Link href="/leaderboard" className="text-gold-400 hover:text-gold-300 transition-colors">
                Hall of Scholars
              </Link>{" "}
              — never your real name or email.{" "}
              {me?.handle ? (
                <>Currently <span className="text-gold-300 font-medium">{me.handle}</span>.</>
              ) : (
                <>You're using the auto-assigned <span className="text-parchment">{handlePlaceholder}</span> — pick your own below.</>
              )}
            </p>
            <HandleForm current={me?.handle ?? null} placeholder={handlePlaceholder} />
          </div>
        </section>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            In Progress
          </h2>
          {inProgress.length === 0 ? (
            <p className="text-parchment-dim text-sm">No courses in progress yet.</p>
          ) : (
            <ul className="space-y-3">
              {inProgress.map((c) => (
                <li key={c.id}>
                  <CourseProgressCard {...c} />
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Completed
          </h2>
          {completed.length === 0 ? (
            <p className="text-parchment-dim text-sm">No completed courses yet.</p>
          ) : (
            <ul className="space-y-3">
              {completed.map((c) => (
                <li key={c.id}>
                  <CourseProgressCard {...c} />
                </li>
              ))}
            </ul>
          )}
        </section>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Your Achievements
          </h2>
          <AchievementsGrid badges={myBadges} />
        </section>
      </div>
    </main>
  );
}

function CourseProgressCard({
  id,
  title,
  watchedCount,
  totalCount,
}: {
  id: string;
  title: string;
  watchedCount: number;
  totalCount: number;
}) {
  const pct = Math.round((watchedCount / totalCount) * 100);
  const isComplete = watchedCount === totalCount;

  return (
    <Link
      href={`/dashboard/course/${id}`}
      className="group block bg-crimson-900 border border-crimson-700 rounded-xl p-4 hover:border-gold-500 transition-colors"
    >
      <div className="flex items-center justify-between mb-3">
        <p className="text-sm font-medium text-parchment group-hover:text-gold-300 transition-colors line-clamp-1">
          {title}
        </p>
        <span className={`text-xs font-medium shrink-0 ml-4 ${isComplete ? "text-green-400" : "text-parchment-dim"}`}>
          {watchedCount} / {totalCount}
        </span>
      </div>
      <div className="h-1.5 bg-crimson-800 rounded-full overflow-hidden">
        <div
          className={`h-full rounded-full transition-all ${isComplete ? "bg-green-500" : "bg-gold-500"}`}
          style={{ width: `${pct}%` }}
        />
      </div>
    </Link>
  );
}
