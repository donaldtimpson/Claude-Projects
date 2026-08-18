import Link from "next/link";
import type { Metadata } from "next";
import { drillBySlug } from "@/lib/drills/registry";
import { grammarLessonDrills, grammarPracticeDrills } from "@/lib/drills/grammar";
import type { DrillDef } from "@/lib/drills/types";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getAcedLessonSlugs } from "@/lib/lessons";

export const metadata: Metadata = {
  title: "Practice Drills",
  description: "Endless timed practice — grammar, mental math, trigonometry, calculus, linear algebra, and geography.",
};

// Grouped like the iOS hub, so the growing list stays scannable. Each entry is a
// category with the drills (by slug) that belong to it, in display order. The two
// grammar categories derive their slugs from the bundled banks so they stay in sync.
const CATEGORIES: { title: string; icon: string; slugs: string[] }[] = [
  {
    title: "Mental Math",
    icon: "🧮",
    slugs: ["arithmetic", "percentages", "order-of-operations", "powers-of-two", "squares", "gcd", "primes", "sequences", "logarithms"],
  },
  { title: "Trigonometry", icon: "📐", slugs: ["unit-circle", "vectors"] },
  { title: "Calculus", icon: "∫", slugs: ["derivative", "integral"] },
  { title: "Linear Algebra", icon: "▦", slugs: ["determinant", "solve-system", "matrix-vector", "dot-product"] },
  { title: "Geography", icon: "🌍", slugs: ["name-country", "name-state", "locate-country", "locate-state"] },
  { title: "Grammar", icon: "✒️", slugs: grammarPracticeDrills.map((d) => d.slug) },
  { title: "Grammar Lessons", icon: "🎓", slugs: grammarLessonDrills.map((d) => d.slug) },
];

function DrillCard({ d, aced }: { d: DrillDef; aced?: boolean }) {
  return (
    <Link
      href={`/drills/${d.slug}`}
      className="group block h-full bg-crimson-900 border border-crimson-700 rounded-xl p-5 hover:border-gold-400 transition-colors"
    >
      <div className="flex items-center gap-3 mb-2">
        <span className="text-2xl" aria-hidden>{d.icon}</span>
        <h3 className="font-display text-lg text-parchment group-hover:text-gold-300 transition-colors">{d.title}</h3>
        {aced && <span className="ml-auto text-gold-300" title="Aced — a flawless homework run">✦</span>}
      </div>
      <p className="text-sm text-parchment-dim">{d.blurb}</p>
    </Link>
  );
}

export default async function DrillsHubPage() {
  const session = await getServerSession(authOptions);
  const acedSet = session?.user?.id
    ? new Set(await getAcedLessonSlugs(session.user.id))
    : new Set<string>();
  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-5xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-5xl mx-auto px-6 py-10 space-y-10">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">Practice Drills</h1>
          <p className="text-parchment-dim text-sm">
            Fluency comes from reps. Each drill generates an endless stream of fresh problems —
            practice a fixed set or race the clock.
          </p>
        </div>

        {CATEGORIES.map((cat) => {
          const drills = cat.slugs.map(drillBySlug).filter((d): d is DrillDef => Boolean(d));
          if (drills.length === 0) return null;
          return (
            <section key={cat.title} className="space-y-4">
              <h2 className="flex items-center gap-2 font-display text-sm tracking-[0.15em] uppercase text-gold-400">
                <span className="text-lg not-italic" aria-hidden>{cat.icon}</span>
                {cat.title}
              </h2>
              <ul className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
                {drills.map((d) => (
                  <li key={d.slug}>
                    <DrillCard d={d} aced={acedSet.has(d.slug)} />
                  </li>
                ))}
              </ul>
            </section>
          );
        })}
      </div>
    </main>
  );
}
