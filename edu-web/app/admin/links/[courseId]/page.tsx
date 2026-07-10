import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ConnectionsEditor from "./ConnectionsEditor";
import OfferingControl from "./OfferingControl";

export const dynamic = "force-dynamic";

export default async function CourseLinksPage({
  params,
}: {
  params: Promise<{ courseId: string }>;
}) {
  const { courseId } = await params;

  const [course, allCourses, links] = await Promise.all([
    db.course.findUnique({
      where: { id: courseId },
      select: {
        id: true,
        title: true,
        canonicalCourseId: true,
        canonicalCourse: { select: { id: true, title: true } },
        offerings: { select: { id: true, title: true }, orderBy: { title: "asc" } },
      },
    }),
    db.course.findMany({
      orderBy: { title: "asc" },
      select: { id: true, title: true, canonicalCourseId: true },
    }),
    db.courseLink.findMany({
      where: { OR: [{ fromCourseId: courseId }, { toCourseId: courseId }] },
      select: { fromCourseId: true, toCourseId: true, kind: true },
    }),
  ]);

  if (!course) notFound();

  const isSibling = course.canonicalCourseId != null;
  // You connect subjects, so only representatives (their own subject) are valid
  // endpoints — and only a representative with no offerings can become a sibling.
  const representatives = allCourses.filter((c) => c.canonicalCourseId == null && c.id !== courseId);

  // Split this representative's links into the three editor groups.
  const buildsOn: string[] = [];
  const leadsTo: string[] = [];
  const related: string[] = [];
  for (const l of links) {
    if (l.kind === "RECOMMENDED") {
      if (l.toCourseId === courseId) buildsOn.push(l.fromCourseId);
      else leadsTo.push(l.toCourseId);
    } else {
      related.push(l.fromCourseId === courseId ? l.toCourseId : l.fromCourseId);
    }
  }

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Connections</h1>
        <p className="text-sm text-parchment-dim mt-1">{course.title}</p>
      </div>

      <OfferingControl
        courseId={course.id}
        canonicalCourseId={course.canonicalCourseId}
        canonicalTitle={course.canonicalCourse?.title ?? null}
        offerings={course.offerings}
        representatives={representatives}
      />

      {isSibling ? (
        <p className="text-sm text-parchment-dim bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-3">
          This is another offering of{" "}
          <span className="text-parchment">{course.canonicalCourse?.title}</span>. Connections for the
          subject are managed on its canonical offering —{" "}
          <Link
            href={`/admin/links/${course.canonicalCourseId}`}
            className="text-gold-400 hover:text-gold-300 transition-colors"
          >
            edit them there
          </Link>
          .
        </p>
      ) : (
        <ConnectionsEditor
          courseId={course.id}
          others={representatives.map(({ id, title }) => ({ id, title }))}
          initialBuildsOn={buildsOn}
          initialLeadsTo={leadsTo}
          initialRelated={related}
        />
      )}
    </main>
  );
}
