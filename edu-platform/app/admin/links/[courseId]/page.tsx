import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ConnectionsEditor from "./ConnectionsEditor";

export const dynamic = "force-dynamic";

export default async function CourseLinksPage({
  params,
}: {
  params: Promise<{ courseId: string }>;
}) {
  const { courseId } = await params;

  const [course, allCourses, links] = await Promise.all([
    db.course.findUnique({ where: { id: courseId }, select: { id: true, title: true } }),
    db.course.findMany({ orderBy: { title: "asc" }, select: { id: true, title: true } }),
    db.courseLink.findMany({
      where: { OR: [{ fromCourseId: courseId }, { toCourseId: courseId }] },
      select: { fromCourseId: true, toCourseId: true, kind: true },
    }),
  ]);

  if (!course) notFound();

  // Split this course's links into the three editor groups.
  const buildsOn: string[] = []; // RECOMMENDED into this course → the prerequisite
  const leadsTo: string[] = []; // RECOMMENDED out of this course → the follow-up
  const related: string[] = []; // RELATED on either end → the other course
  for (const l of links) {
    if (l.kind === "RECOMMENDED") {
      if (l.toCourseId === courseId) buildsOn.push(l.fromCourseId);
      else leadsTo.push(l.toCourseId);
    } else {
      related.push(l.fromCourseId === courseId ? l.toCourseId : l.fromCourseId);
    }
  }

  const others = allCourses.filter((c) => c.id !== courseId);

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Connections</h1>
        <p className="text-sm text-parchment-dim mt-1">{course.title}</p>
      </div>

      <ConnectionsEditor
        courseId={course.id}
        others={others}
        initialBuildsOn={buildsOn}
        initialLeadsTo={leadsTo}
        initialRelated={related}
      />
    </main>
  );
}
