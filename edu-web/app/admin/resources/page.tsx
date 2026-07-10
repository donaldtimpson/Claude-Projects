import Link from "next/link";
import { ResourceKind } from "@prisma/client";
import { db } from "@/lib/db";
import { RESOURCE_KIND_LABELS, RESOURCE_KIND_OPTIONS } from "@/lib/resource-kinds";
import ResourceCreateForm from "./ResourceCreateForm";

export const dynamic = "force-dynamic";

const VALID_KINDS = new Set(Object.keys(RESOURCE_KIND_LABELS));

export default async function AdminResourcesPage({
  searchParams,
}: {
  searchParams: Promise<{ kind?: string }>;
}) {
  const { kind: kindParam } = await searchParams;
  const activeKind = kindParam && VALID_KINDS.has(kindParam) ? (kindParam as ResourceKind) : null;

  const resources = await db.resource.findMany({
    orderBy: [{ kind: "asc" }, { title: "asc" }],
    include: { _count: { select: { courses: true } } },
  });

  const countByKind = new Map<ResourceKind, number>();
  for (const r of resources) countByKind.set(r.kind, (countByKind.get(r.kind) ?? 0) + 1);

  const filtered = activeKind ? resources.filter((r) => r.kind === activeKind) : resources;

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

      {resources.length > 0 && (
        <div className="flex flex-wrap gap-2">
          <FilterPill href="/admin/resources" label="All" count={resources.length} active={activeKind === null} />
          {RESOURCE_KIND_OPTIONS.map((opt) => {
            const count = countByKind.get(opt.value) ?? 0;
            if (count === 0) return null;
            return (
              <FilterPill
                key={opt.value}
                href={`/admin/resources?kind=${opt.value}`}
                label={opt.label}
                count={count}
                active={activeKind === opt.value}
              />
            );
          })}
        </div>
      )}

      {resources.length === 0 ? (
        <p className="text-parchment-dim text-sm">No resources yet.</p>
      ) : filtered.length === 0 ? (
        <p className="text-parchment-dim text-sm">No resources of this kind.</p>
      ) : (
        <div className="space-y-3">
          {filtered.map((r) => (
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

function FilterPill({
  href,
  label,
  count,
  active,
}: {
  href: string;
  label: string;
  count: number;
  active: boolean;
}) {
  return (
    <Link
      href={href}
      className={`px-3 py-1.5 rounded-full text-xs font-medium border transition-colors ${
        active
          ? "bg-gold-500 border-gold-500 text-crimson-950"
          : "bg-crimson-900 border-crimson-700 text-parchment hover:border-gold-500 hover:text-gold-300"
      }`}
    >
      {label} <span className={active ? "text-crimson-900/70" : "text-parchment-dim"}>{count}</span>
    </Link>
  );
}
