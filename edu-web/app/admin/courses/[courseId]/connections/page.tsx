import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ConnectionsEditor from "./ConnectionsEditor";
import OfferingControl from "./OfferingControl";

export const dynamic = "force-dynamic";

// Connections tab: the course dependency graph (builds-on / leads-to / related)
// plus the canonical/sibling offering control.
export default async function AdminCourseConnections({
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
    <div className="space-y-8">
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
            href={`/admin/courses/${course.canonicalCourseId}/connections`}
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
    </div>
  );
}
