import Link from "next/link";
import { db } from "@/lib/db";
import { RESOURCE_KIND_LABELS } from "@/lib/resource-kinds";
import ResourceCreateForm from "./ResourceCreateForm";

export const dynamic = "force-dynamic";

export default async function AdminResourcesPage() {
  const resources = await db.resource.findMany({
    orderBy: [{ kind: "asc" }, { title: "asc" }],
    include: { _count: { select: { courses: true } } },
  });

  return (
    <main className="max-w-3xl mx-auto px-6 py-10 space-y-8">
      <div>
        <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
          ← Dashboard
        </Link>
        <h1 className="text-2xl font-bold text-parchment mt-3">Resources</h1>
        <p className="text-sm text-parchment-dim mt-1">
          Create a resource once, then attach it to any number of courses.
        </p>
      </div>

      {resources.length === 0 ? (
        <p className="text-parchment-dim text-sm">No resources yet.</p>
      ) : (
        <div className="space-y-3">
          {resources.map((r) => (
            <div
              key={r.id}
              className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 flex items-center justify-between gap-4"
            >
              <div className="min-w-0 flex-1">
                <p className="font-semibold text-parchment truncate">{r.title}</p>
                <p className="text-xs text-parchment-dim mt-0.5">
                  {RESOURCE_KIND_LABELS[r.kind]}
                  {" · "}
                  {r._count.courses} course{r._count.courses !== 1 ? "s" : ""}
                </p>
                <p className="text-xs text-parchment-dim/70 font-mono mt-1 truncate">{r.url}</p>
              </div>
              <Link
                href={`/admin/resources/${r.id}`}
                className="text-sm text-gold-400 hover:text-gold-300 transition-colors shrink-0"
              >
                Edit
              </Link>
            </div>
          ))}
        </div>
      )}

      <section className="space-y-3">
        <h2 className="font-semibold text-parchment">New Resource</h2>
        <ResourceCreateForm />
      </section>
    </main>
  );
}
