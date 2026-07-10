import Link from "next/link";
import { notFound } from "next/navigation";
import { db } from "@/lib/db";
import ResourceEditor from "./ResourceEditor";

export const dynamic = "force-dynamic";

export default async function AdminResourceEditPage({
  params,
}: {
  params: Promise<{ resourceId: string }>;
}) {
  const { resourceId } = await params;

  const [resource, allCourses] = await Promise.all([
    db.resource.findUnique({
      where: { id: resourceId },
      include: { courses: { select: { courseId: true } } },
    }),
    db.course.findMany({ orderBy: { title: "asc" }, select: { id: true, title: true } }),
  ]);

  if (!resource) notFound();

  const assignedIds = resource.courses.map((c) => c.courseId);

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link
          href="/admin/resources"
          className="text-sm text-parchment-dim hover:text-parchment transition-colors"
        >
          ← Resources
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Edit Resource</h1>
      </div>

      <ResourceEditor
        resourceId={resource.id}
        initialTitle={resource.title}
        initialUrl={resource.url}
        initialKind={resource.kind}
        initialDescription={resource.description}
        allCourses={allCourses}
        initialAssignedIds={assignedIds}
      />
    </main>
  );
}
