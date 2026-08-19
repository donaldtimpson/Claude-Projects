import Link from "next/link";
import { notFound } from "next/navigation";
import type { Metadata } from "next";
import { drillBySlug } from "@/lib/drills/registry";
import { CATEGORIES, categoryBySlug, LESSON_CATEGORY_SLUG } from "@/lib/drills/categories";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getAcedLessonSlugs } from "@/lib/lessons";

export function generateStaticParams() {
  return CATEGORIES.map((c) => ({ category: c.slug }));
}

export async function generateMetadata({
  params,
}: {
  params: Promise<{ category: string }>;
}): Promise<Metadata> {
  const { category } = await params;
  const c = categoryBySlug(category);
  if (!c) return { title: "Drills" };
  return { title: `${c.title} Drills`, description: `${c.title} practice drills.` };
}

export default async function CategoryDrillsPage({
  params,
}: {
  params: Promise<{ category: string }>;
}) {
  const { category } = await params;
  const cat = categoryBySlug(category);
  if (!cat) notFound();

  const drills = cat.drillSlugs.map(drillBySlug).filter((d) => Boolean(d));

  // Only the lesson track has an ✦ pass state, so skip the query for other categories.
  const session = cat.slug === LESSON_CATEGORY_SLUG ? await getServerSession(authOptions) : null;
  const aced = new Set(session?.user?.id ? await getAcedLessonSlugs(session.user.id) : []);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-3xl mx-auto">
          <Link href="/drills" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Drills
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <div className="flex items-center gap-3">
          <span className="text-4xl leading-none" aria-hidden>{cat.icon}</span>
          <div>
            <h1 className="font-display text-2xl text-parchment">{cat.title}</h1>
            <p className="text-parchment-dim text-sm">
              {cat.slug === LESSON_CATEGORY_SLUG
                ? aced.size > 0
                  ? `✦ ${aced.size}/${drills.length} aced`
                  : `${drills.length} lessons`
                : `${drills.length} drills`}
            </p>
          </div>
        </div>

        <ul className="space-y-3">
          {drills.map((d) => (
            <li key={d!.slug}>
              <Link
                href={`/drills/${d!.slug}`}
                className="flex items-start gap-3 bg-crimson-900 border border-crimson-700 rounded-xl p-4 hover:border-gold-400 transition-colors"
              >
                <span className="text-3xl leading-none shrink-0" aria-hidden>{d!.icon}</span>
                <span className="min-w-0 flex-1">
                  <span className="block font-display text-lg text-parchment">{d!.title}</span>
                  <span className="block text-sm text-parchment-dim">{d!.blurb}</span>
                  {aced.has(d!.slug) && (
                    <span className="block text-xs font-semibold text-gold-300 mt-1">✦ Aced</span>
                  )}
                </span>
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </main>
  );
}
