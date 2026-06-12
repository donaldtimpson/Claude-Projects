import Link from "next/link";
import { db } from "@/lib/db";
import SyncButton from "./SyncButton";

export default async function AdminDashboard() {
  const courses = await db.course.findMany({
    orderBy: [{ isCurrent: "desc" }, { createdAt: "asc" }],
    include: {
      _count: {
        select: { videos: true, quizQuestions: true, linksFrom: true, linksTo: true, offerings: true },
      },
      videos: { select: { _count: { select: { quizQuestions: true } } } },
      canonicalCourse: { select: { title: true } },
    },
  });

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-parchment">Dashboard</h1>
        <div className="flex items-center gap-4">
          <Link href="/admin/comments" className="text-sm text-gold-400 hover:text-gold-300 transition-colors">
            Comments
          </Link>
          <Link href="/admin/announcements" className="text-sm text-gold-400 hover:text-gold-300 transition-colors">
            Announcements
          </Link>
          <Link href="/admin/categories" className="text-sm text-gold-400 hover:text-gold-300 transition-colors">
            Categories
          </Link>
          <Link href="/admin/resources" className="text-sm text-gold-400 hover:text-gold-300 transition-colors">
            Resources
          </Link>
          <Link href="/admin/achievements" className="text-sm text-gold-400 hover:text-gold-300 transition-colors">
            Achievements
          </Link>
          <SyncButton />
        </div>
      </div>

      {courses.length === 0 ? (
        <p className="text-parchment-dim">No courses yet. Click Sync to import from YouTube.</p>
      ) : (
        <div className="space-y-3">
          {courses.map((course) => {
            const videoQuestions = course.videos.reduce((s, v) => s + v._count.quizQuestions, 0);
            const testQuestions = course._count.quizQuestions;
            const isSibling = course.canonicalCourseId != null;
            const connectionCount = course._count.linksFrom + course._count.linksTo;
            const pill = "text-[11px] px-2 py-0.5 rounded-full border whitespace-nowrap";
            return (
              <Link
                key={course.id}
                href={`/admin/courses/${course.id}`}
                className="group block bg-crimson-900 border border-crimson-700 rounded-xl p-5 hover:border-gold-500/60 hover:bg-crimson-800/40 transition-colors"
              >
                <div className="flex items-start justify-between gap-4">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 flex-wrap">
                      <h2 className="font-semibold text-parchment">{course.title}</h2>
                      {course.isCurrent && (
                        <span className={`${pill} border-gold-500 bg-gold-500 text-crimson-950`}>★ Current</span>
                      )}
                      {isSibling ? (
                        <span className={`${pill} border-crimson-700 text-parchment-dim`}>
                          ↳ offering of {course.canonicalCourse?.title}
                        </span>
                      ) : connectionCount > 0 ? (
                        <span className={`${pill} border-gold-600/60 text-gold-300`}>
                          {connectionCount} connection{connectionCount === 1 ? "" : "s"}
                        </span>
                      ) : (
                        <span className={`${pill} border-red-800 text-red-400`}>no connections</span>
                      )}
                      {!isSibling && course._count.offerings > 0 && (
                        <span className={`${pill} border-crimson-700 text-parchment-dim`}>
                          canonical · {course._count.offerings} offering{course._count.offerings === 1 ? "" : "s"}
                        </span>
                      )}
                    </div>
                    <p className="text-sm text-parchment-dim mt-1">
                      {course._count.videos} videos · {videoQuestions} quiz questions ·{" "}
                      <span className={testQuestions === 0 ? "text-red-400" : undefined}>
                        {testQuestions} test questions
                      </span>
                    </p>
                    {course.syncedAt && (
                      <p className="text-xs text-parchment-dim mt-1">
                        Last synced {new Date(course.syncedAt).toLocaleDateString()}
                      </p>
                    )}
                  </div>
                  <span className="shrink-0 text-parchment-dim group-hover:text-gold-300 transition-colors" aria-hidden="true">
                    →
                  </span>
                </div>
              </Link>
            );
          })}
        </div>
      )}
    </main>
  );
}
