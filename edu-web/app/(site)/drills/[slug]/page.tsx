import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { DRILLS, drillBySlug } from "@/lib/drills/registry";
import DrillSession from "./DrillSession";
import RecordRecent from "./RecordRecent";
import { categoryOfDrill } from "@/lib/drills/categories";

export function generateStaticParams() {
  return DRILLS.map((d) => ({ slug: d.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ slug: string }>;
}): Promise<Metadata> {
  const { slug } = await params;
  const def = drillBySlug(slug);
  if (!def) return { title: "Drill" };
  return { title: def.title, description: def.blurb };
}

export default async function DrillSessionPage({
  params,
}: {
  params: Promise<{ slug: string }>;
}) {
  const { slug } = await params;
  const def = drillBySlug(slug);
  if (!def) notFound();
  const cat = categoryOfDrill(def.slug);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link
            href={cat ? `/drills/c/${cat.slug}` : "/drills"}
            className="text-sm text-parchment-dim hover:text-parchment transition-colors"
          >
            ← {cat ? cat.title : "All Drills"}
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">{def.title}</h1>
          <p className="text-parchment-dim text-sm">{def.blurb}</p>
        </div>
        {/* The DrillDef holds functions, which can't cross the server→client
            boundary — pass the slug and re-resolve from the registry client-side. */}
        <DrillSession slug={def.slug} />
        <RecordRecent slug={def.slug} />
      </div>
    </main>
  );
}
