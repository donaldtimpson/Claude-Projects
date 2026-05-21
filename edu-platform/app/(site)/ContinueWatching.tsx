import Link from "next/link";
import Image from "next/image";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";

const MAX_CARDS = 6;

export default async function ContinueWatching() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return null;

  const progress = await db.videoProgress.findMany({
    where: { userId: session.user.id },
    include: {
      video: {
        include: {
          course: {
            include: {
              videos: {
                select: { id: true, position: true, title: true, thumbnailUrl: true },
                orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
              },
            },
          },
        },
      },
    },
    orderBy: { watchedAt: "desc" },
  });

  if (progress.length === 0) return null;

  type Entry = {
    courseId: string;
    courseTitle: string;
    courseThumbnail: string;
    nextVideoId: string;
    nextVideoTitle: string;
    nextVideoThumbnail: string;
    watchedCount: number;
    totalCount: number;
    lastWatchedAt: Date;
  };

  const byCourse = new Map<string, { watched: Set<string>; lastWatchedAt: Date; course: typeof progress[number]["video"]["course"] }>();

  for (const p of progress) {
    const course = p.video.course;
    const existing = byCourse.get(course.id);
    if (existing) {
      existing.watched.add(p.videoId);
      if (p.watchedAt > existing.lastWatchedAt) existing.lastWatchedAt = p.watchedAt;
    } else {
      byCourse.set(course.id, {
        watched: new Set([p.videoId]),
        lastWatchedAt: p.watchedAt,
        course,
      });
    }
  }

  const entries: Entry[] = [];
  for (const { watched, lastWatchedAt, course } of byCourse.values()) {
    const totalCount = course.videos.length;
    if (totalCount === 0) continue;
    const nextVideo = course.videos.find((v) => !watched.has(v.id));
    if (!nextVideo) continue;
    entries.push({
      courseId: course.id,
      courseTitle: course.title,
      courseThumbnail: course.thumbnailUrl,
      nextVideoId: nextVideo.id,
      nextVideoTitle: nextVideo.title,
      nextVideoThumbnail: nextVideo.thumbnailUrl,
      watchedCount: watched.size,
      totalCount,
      lastWatchedAt,
    });
  }

  if (entries.length === 0) return null;

  entries.sort((a, b) => b.lastWatchedAt.getTime() - a.lastWatchedAt.getTime());
  const visible = entries.slice(0, MAX_CARDS);

  return (
    <section>
      <h2 className="font-display text-lg tracking-[0.25em] uppercase text-gold-400 mb-8 pb-3 border-b border-crimson-700">
        Continue Watching
      </h2>
      <div
        className={`grid gap-6 ${
          visible.length === 1
            ? "grid-cols-1 max-w-2xl"
            : visible.length === 2
            ? "grid-cols-1 sm:grid-cols-2"
            : "grid-cols-1 sm:grid-cols-2 lg:grid-cols-3"
        }`}
      >
        {visible.map((e) => {
          const thumb = e.nextVideoThumbnail || e.courseThumbnail;
          const pct = Math.round((e.watchedCount / e.totalCount) * 100);
          return (
            <Link
              key={e.courseId}
              href={`/courses/${e.courseId}/${e.nextVideoId}`}
              className="group bg-crimson-900 border border-crimson-700 rounded-lg overflow-hidden hover:border-gold-500 transition-colors"
            >
              {thumb ? (
                <div className="relative aspect-video">
                  <Image
                    src={thumb}
                    alt={e.courseTitle}
                    fill
                    className="object-cover opacity-90 group-hover:opacity-100 transition-opacity"
                  />
                </div>
              ) : (
                <div className="aspect-video bg-crimson-800 flex items-center justify-center">
                  <span className="text-parchment-dim text-sm">No thumbnail</span>
                </div>
              )}
              <div className="p-4">
                <h3 className="font-display text-xs tracking-wider uppercase text-parchment group-hover:text-gold-300 transition-colors line-clamp-2">
                  {e.courseTitle}
                </h3>
                <p className="text-sm text-parchment-dim mt-2 line-clamp-2">
                  Up next: {e.nextVideoTitle}
                </p>
                <div className="mt-3 flex items-center gap-3">
                  <div className="flex-1 h-1.5 bg-crimson-800 rounded-full overflow-hidden">
                    <div
                      className="h-full rounded-full bg-gold-500 transition-all"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <span className="text-xs text-parchment-dim shrink-0">
                    {e.watchedCount} / {e.totalCount}
                  </span>
                </div>
              </div>
            </Link>
          );
        })}
      </div>
    </section>
  );
}
