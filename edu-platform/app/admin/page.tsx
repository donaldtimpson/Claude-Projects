import Link from "next/link";
import { db } from "@/lib/db";
import SyncButton from "./SyncButton";

export default async function AdminDashboard() {
  const courses = await db.course.findMany({
    orderBy: { createdAt: "asc" },
    include: {
      _count: { select: { videos: true, quizQuestions: true } },
    },
  });

  return (
    <main className="max-w-4xl mx-auto px-6 py-10 space-y-8">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold text-white">Dashboard</h1>
        <SyncButton />
      </div>

      {courses.length === 0 ? (
        <p className="text-slate-400">No courses yet. Click Sync to import from YouTube.</p>
      ) : (
        <div className="space-y-3">
          {courses.map((course) => (
            <div
              key={course.id}
              className="bg-slate-900 border border-slate-800 rounded-xl p-5 flex items-start justify-between gap-4"
            >
              <div>
                <h2 className="font-semibold text-white">{course.title}</h2>
                <p className="text-sm text-slate-400 mt-1">
                  {course._count.videos} videos · {course._count.quizQuestions} quiz questions
                </p>
                {course.syncedAt && (
                  <p className="text-xs text-slate-600 mt-1">
                    Last synced {new Date(course.syncedAt).toLocaleDateString()}
                  </p>
                )}
              </div>
              <div className="flex gap-3 shrink-0">
                <Link
                  href={`/admin/courses/${course.id}`}
                  className="text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
                >
                  Edit Quizzes
                </Link>
                <Link
                  href={`/admin/test/${course.id}`}
                  className="text-sm text-indigo-400 hover:text-indigo-300 transition-colors"
                >
                  Edit Test
                </Link>
              </div>
            </div>
          ))}
        </div>
      )}
    </main>
  );
}
