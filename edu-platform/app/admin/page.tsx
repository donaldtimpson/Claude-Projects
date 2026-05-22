import Link from "next/link";
import { db } from "@/lib/db";
import SyncButton from "./SyncButton";
import CurrentToggle from "./CurrentToggle";

export default async function AdminDashboard() {
  const courses = await db.course.findMany({
    orderBy: [{ isCurrent: "desc" }, { createdAt: "asc" }],
    include: {
      _count: { select: { videos: true, quizQuestions: true } },
      videos: { select: { _count: { select: { quizQuestions: true } } } },
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
          <SyncButton />
        </div>
      </div>

      {courses.length === 0 ? (
        <p className="text-parchment-dim">No courses yet. Click Sync to import from YouTube.</p>
      ) : (
        <div className="space-y-3">
          {courses.map((course) => {
            const videoQuestions = course.videos.reduce((s, v) => s + v._count.quizQuestions, 0);
            const totalQuestions = videoQuestions + course._count.quizQuestions;
            return (
            <div
              key={course.id}
              className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 flex items-start justify-between gap-4"
            >
              <div>
                <h2 className="font-semibold text-parchment">{course.title}</h2>
                <p className="text-sm text-parchment-dim mt-1">
                  {course._count.videos} videos · {totalQuestions} quiz questions
                </p>
                {course.syncedAt && (
                  <p className="text-xs text-parchment-dim mt-1">
                    Last synced {new Date(course.syncedAt).toLocaleDateString()}
                  </p>
                )}
              </div>
              <div className="flex items-center gap-3 shrink-0">
                <CurrentToggle courseId={course.id} initial={course.isCurrent} />
                <Link
                  href={`/admin/courses/${course.id}`}
                  className="text-sm text-gold-400 hover:text-gold-300 transition-colors"
                >
                  Edit Quizzes
                </Link>
                <Link
                  href={`/admin/test/${course.id}`}
                  className="text-sm text-gold-400 hover:text-gold-300 transition-colors"
                >
                  Edit Test
                </Link>
              </div>
            </div>
            );
          })}
        </div>
      )}
    </main>
  );
}
