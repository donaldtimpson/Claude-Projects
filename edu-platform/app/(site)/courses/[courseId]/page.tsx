import type { Metadata } from "next";
import Link from "next/link";
import VideoThumb from "@/components/VideoThumb";
import { notFound } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { RESOURCE_KIND_LABELS } from "@/lib/resource-kinds";
import AnnouncementsFeed from "@/components/AnnouncementsFeed";
import RegisterForm from "./RegisterForm";

export const dynamic = "force-dynamic";

export async function generateMetadata({
  params,
}: {
  params: Promise<{ courseId: string }>;
}): Promise<Metadata> {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: {
      title: true,
      description: true,
      thumbnailUrl: true,
      videos: { select: { thumbnailUrl: true }, orderBy: { position: "asc" }, take: 1 },
    },
  });
  if (!course) return {};

  const description =
    course.description?.trim().slice(0, 200) || "A classical course at The Timpson Lyceum.";
  // Prefer the course thumbnail, else its first lecture's thumbnail; otherwise the
  // site's default card (inherited from the root opengraph-image) is used.
  const image = course.thumbnailUrl || course.videos[0]?.thumbnailUrl || undefined;

  return {
    title: course.title,
    description,
    openGraph: {
      title: course.title,
      description,
      ...(image ? { images: [image] } : {}),
    },
    twitter: {
      card: "summary_large_image",
      title: course.title,
      description,
      ...(image ? { images: [image] } : {}),
    },
  };
}

function formatDuration(secs: number) {
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;
  if (h > 0) return `${h}:${String(m).padStart(2, "0")}:${String(s).padStart(2, "0")}`;
  return `${m}:${String(s).padStart(2, "0")}`;
}

export default async function CoursePage({ params }: { params: Promise<{ courseId: string }> }) {
  const { courseId } = await params;

  const [course, session, announcements] = await Promise.all([
    db.course.findUnique({
      where: { id: courseId },
      include: {
        videos: {
          // Chronological (oldest lecture first). publishedAt is reliable lecture
          // order across all courses; position can be reversed for active playlists
          // that YouTube sorts newest-first.
          orderBy: [{ publishedAt: "asc" }, { position: "asc" }],
          include: { _count: { select: { comments: true } } },
        },
        _count: { select: { quizQuestions: { where: { isDraft: false } } } },
        resources: {
          include: { resource: true },
          orderBy: [{ position: "asc" }, { resource: { kind: "asc" } }],
        },
      },
    }),
    getServerSession(authOptions),
    db.announcement.findMany({
      where: { OR: [{ courseId }, { courseId: null }] },
      orderBy: [{ pinned: "desc" }, { createdAt: "desc" }],
      include: { course: { select: { id: true, title: true } } },
    }),
  ]);

  if (!course) notFound();

  // Course Review drills the whole pool — per-lecture quizzes AND the course test —
  // so it's offered whenever the course has any published question (the _count above
  // only covers the course test).
  const reviewQuestionCount = await db.quizQuestion.count({
    where: { isDraft: false, OR: [{ courseId, videoId: null }, { video: { courseId } }] },
  });

  const userId = session?.user?.id ?? null;
  const watchedSet = new Set<string>();
  if (userId) {
    const progress = await db.videoProgress.findMany({
      where: { userId, videoId: { in: course.videos.map((v) => v.id) } },
      select: { videoId: true },
    });
    progress.forEach((p) => watchedSet.add(p.videoId));
  }

  // Class registration + homework. Registration never gates the materials; it only
  // records who's in the live class for grading. Problem sets are public; only an
  // enrolled student sees their section's assignments + a submit box.
  let myEnrollment: { sectionId: string; sectionName: string } | null = null;
  if (userId) {
    const enr = await db.enrollment.findFirst({
      where: { userId, status: "active", section: { courseId: course.id } },
      select: { sectionId: true, section: { select: { name: true } } },
    });
    if (enr) myEnrollment = { sectionId: enr.sectionId, sectionName: enr.section.name };
  }

  // Show the join-code form only on the current course, when a section exists and
  // the viewer isn't already enrolled.
  let registrationOpen = false;
  if (course.isCurrent && !myEnrollment) {
    registrationOpen = (await db.section.count({ where: { courseId: course.id } })) > 0;
  }

  // Public problem sets for this course (visible to everyone).
  const problemSets = await db.problemSet.findMany({
    where: { courseId: course.id },
    orderBy: { createdAt: "desc" },
    select: { id: true, title: true },
  });

  // (Homework moved to the student's class hub: /dashboard/class/[sectionId].)

  // Connections live on the subject's canonical (representative) course; a sibling
  // offering inherits them. Resolve to the representative, then load its links.
  const repId = course.canonicalCourseId ?? course.id;
  const connectionLinks = await db.courseLink.findMany({
    where: { OR: [{ fromCourseId: repId }, { toCourseId: repId }] },
    include: {
      fromCourse: { select: { id: true, title: true } },
      toCourse: { select: { id: true, title: true } },
    },
  });

  // Endpoints are always representatives, so each chip links straight to the
  // canonical offering of the linked subject.
  const buildsOn = connectionLinks
    .filter((l) => l.kind === "RECOMMENDED" && l.toCourseId === repId)
    .map((l) => l.fromCourse);
  const leadsTo = connectionLinks
    .filter((l) => l.kind === "RECOMMENDED" && l.fromCourseId === repId)
    .map((l) => l.toCourse);
  const related = connectionLinks
    .filter((l) => l.kind === "RELATED")
    .map((l) => (l.fromCourseId === repId ? l.toCourse : l.fromCourse));

  const connectionGroups: { title: string; courses: { id: string; title: string }[] }[] = [
    { title: "Builds on", courses: buildsOn },
    { title: "Leads to", courses: leadsTo },
    { title: "Related Courses", courses: related },
  ].filter((g) => g.courses.length > 0);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10">
        <div className="mb-8">
          <h1 className="text-3xl font-bold text-parchment mb-2">{course.title}</h1>
          <p className="text-parchment-dim">
            {course.videos.length === 0
              ? "Coming soon"
              : `${course.videos.length} video${course.videos.length !== 1 ? "s" : ""}`}
            {userId && watchedSet.size > 0 && (
              <span className="ml-2 text-green-400">
                · {watchedSet.size} watched
              </span>
            )}
          </p>
          {course.description && (
            <p className="mt-3 text-parchment-dim leading-relaxed">{course.description}</p>
          )}
          {(course._count.quizQuestions > 0 || reviewQuestionCount > 0) && (
            <div className="mt-4 flex flex-wrap gap-3">
              {course._count.quizQuestions > 0 && (
                <Link
                  href={`/courses/${course.id}/test`}
                  className="inline-block px-5 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
                >
                  Take Playlist Test ({course._count.quizQuestions} questions)
                </Link>
              )}
              {reviewQuestionCount > 0 && (
                <Link
                  href={`/courses/${course.id}/review`}
                  className="inline-block px-5 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
                >
                  Review Course ({reviewQuestionCount} questions)
                </Link>
              )}
            </div>
          )}
        </div>

        {myEnrollment ? (
          <div className="mb-8">
            <Link
              href={`/dashboard/class/${myEnrollment.sectionId}`}
              className="inline-flex items-center gap-2 text-sm bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-lg px-4 py-2 text-parchment hover:text-gold-300 transition-colors"
            >
              ✓ You&apos;re in this class ({myEnrollment.sectionName}) — view your grade &amp; homework →
            </Link>
          </div>
        ) : registrationOpen ? (
          <details className="mb-8 text-sm">
            <summary className="cursor-pointer text-parchment-dim hover:text-parchment transition-colors">
              Taking this class for a grade? Register with your class code
            </summary>
            <div className="mt-3 max-w-md">
              {userId ? (
                <RegisterForm />
              ) : (
                <p className="text-parchment-dim">
                  <Link href="/auth/signin" className="text-gold-400 hover:text-gold-300 transition-colors">
                    Sign in
                  </Link>{" "}
                  and enter your class code to register.
                </p>
              )}
            </div>
          </details>
        ) : null}

        {course.videos.length === 0 ? (
          <div className="bg-crimson-900 border border-crimson-700 border-dashed rounded-xl p-8 text-center mb-8">
            <p className="text-parchment-dim">
              No lectures yet — check back soon for the first video in this course.
            </p>
          </div>
        ) : (
          <ol className="space-y-3 mb-8">
          {course.videos.map((video, idx) => {
            const isWatched = watchedSet.has(video.id);
            return (
              <li key={video.id}>
                <Link
                  href={`/courses/${course.id}/${video.id}`}
                  className="group flex gap-4 items-start bg-crimson-900 border border-crimson-700 rounded-xl p-4 hover:border-gold-500 transition-colors"
                >
                  <span className="text-parchment-dim text-sm w-6 shrink-0 mt-0.5">{idx + 1}</span>
                  <div className="relative w-32 aspect-video shrink-0 rounded-md overflow-hidden bg-crimson-800">
                    <VideoThumb videoId={video.youtubeVideoId} src={video.thumbnailUrl} alt={video.title} />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-medium text-parchment group-hover:text-gold-300 transition-colors line-clamp-2">
                      {video.title}
                    </p>
                    <p className="text-xs text-parchment-dim mt-1 flex items-center gap-3">
                      {video.durationSeconds > 0 && <span>{formatDuration(video.durationSeconds)}</span>}
                      {video._count.comments > 0 && (
                        <span>
                          {video._count.comments} comment{video._count.comments === 1 ? "" : "s"}
                        </span>
                      )}
                    </p>
                  </div>
                  {isWatched && (
                    <span className="shrink-0 text-green-400 text-sm self-center" title="Watched">✓</span>
                  )}
                </Link>
              </li>
            );
          })}
          </ol>
        )}

        {problemSets.length > 0 && (
          <section className="mb-8">
            <h2 className="text-sm uppercase tracking-wider text-parchment-dim mb-3">Problem Sets</h2>
            <ul className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              {problemSets.map((ps) => (
                <li key={ps.id}>
                  <Link
                    href={`/courses/${course.id}/problems/${ps.id}`}
                    className="block bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-xl p-4 transition-colors group"
                  >
                    <span className="font-medium text-parchment group-hover:text-gold-300 transition-colors">
                      {ps.title}
                    </span>
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        )}

        {connectionGroups.length > 0 && (
          <section className="mb-8 space-y-4">
            {connectionGroups.map((group) => (
              <div key={group.title}>
                <h2 className="text-sm uppercase tracking-wider text-parchment-dim mb-2">
                  {group.title}
                </h2>
                <div className="flex flex-wrap gap-2">
                  {group.courses.map((c) => (
                    <Link
                      key={c.id}
                      href={`/courses/${c.id}`}
                      className="text-sm px-3 py-1.5 rounded-full border border-crimson-700 text-parchment-dim hover:border-gold-500 hover:text-gold-300 transition-colors"
                    >
                      {c.title}
                    </Link>
                  ))}
                </div>
              </div>
            ))}
          </section>
        )}

        {announcements.length > 0 && (
          <div className="mb-8">
            <AnnouncementsFeed announcements={announcements} showScope />
          </div>
        )}

        {course.resources.length > 0 && (
          <section className="mb-8">
            <h2 className="text-sm uppercase tracking-wider text-parchment-dim mb-3">Resources</h2>
            <ul className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {course.resources.map(({ resource }) => (
                <li key={resource.id}>
                  <a
                    href={resource.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="block bg-crimson-900 border border-crimson-700 hover:border-gold-500 rounded-xl p-4 transition-colors group h-full"
                  >
                    <div className="flex items-center justify-between gap-3">
                      <div className="min-w-0">
                        <p className="font-medium text-parchment group-hover:text-gold-300 transition-colors truncate">
                          {resource.title}
                        </p>
                        <p className="text-xs text-parchment-dim mt-0.5">
                          {resource.description || RESOURCE_KIND_LABELS[resource.kind]}
                        </p>
                      </div>
                      <span className="text-parchment-dim group-hover:text-gold-300 transition-colors shrink-0">↗</span>
                    </div>
                  </a>
                </li>
              ))}
            </ul>
          </section>
        )}

      </div>
    </main>
  );
}
