import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import CurrentToggle from "../../CurrentToggle";
import CourseTabs from "./CourseTabs";

export const dynamic = "force-dynamic";

// Shared shell for every course-scoped admin tab: back link, title, the
// Current toggle (visible from any tab), and the tab bar.
export default async function AdminCourseLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ courseId: string }>;
}) {
  const { courseId } = await params;
  const course = await db.course.findUnique({
    where: { id: courseId },
    select: { id: true, title: true, isCurrent: true },
  });
  if (!course) notFound();

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div className="space-y-4">
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <div className="flex items-center gap-3 flex-wrap">
          <h1 className="text-2xl font-bold text-parchment">{course.title}</h1>
          <CurrentToggle courseId={course.id} initial={course.isCurrent} />
        </div>
        <CourseTabs courseId={course.id} />
      </div>
      {children}
    </main>
  );
}
