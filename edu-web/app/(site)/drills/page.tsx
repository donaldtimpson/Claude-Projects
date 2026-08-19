import Link from "next/link";
import type { Metadata } from "next";
import { drillBySlug } from "@/lib/drills/registry";
import { CATEGORIES, LESSON_CATEGORY_SLUG } from "@/lib/drills/categories";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getAcedLessonSlugs } from "@/lib/lessons";
import DrillsHub, { type CategoryMeta } from "./DrillsHub";

export const metadata: Metadata = {
  title: "Practice Drills",
  description: "Endless timed practice — grammar, mental math, trigonometry, calculus, linear algebra, and geography.",
};

export default async function DrillsHubPage() {
  const session = await getServerSession(authOptions);
  const acedSlugs = session?.user?.id ? await getAcedLessonSlugs(session.user.id) : [];

  // Serializable metadata only — DrillDefs hold generator functions, which cannot cross
  // the server→client boundary (and would drag the grammar banks + geo atlas into the
  // hub's bundle). The session page re-resolves the full def from the registry.
  const categories: CategoryMeta[] = CATEGORIES.map((c) => ({
    slug: c.slug,
    title: c.title,
    icon: c.icon,
    drills: c.drillSlugs
      .map(drillBySlug)
      .filter((d) => Boolean(d))
      .map((d) => ({ slug: d!.slug, title: d!.title, blurb: d!.blurb, icon: d!.icon })),
  })).filter((c) => c.drills.length > 0);

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-5xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-3xl mx-auto px-6 py-10 space-y-8">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">Practice Drills</h1>
          <p className="text-parchment-dim text-sm">
            Fluency comes from reps. Each drill generates an endless stream of fresh problems —
            practice a fixed set or race the clock.
          </p>
        </div>

        <DrillsHub
          categories={categories}
          acedSlugs={acedSlugs}
          lessonCategorySlug={LESSON_CATEGORY_SLUG}
        />
      </div>
    </main>
  );
}
