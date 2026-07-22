import Link from "next/link";
import type { Metadata } from "next";
import { drillBySlug } from "@/lib/drills/registry";
import type { DrillDef } from "@/lib/drills/types";

export const metadata: Metadata = {
  title: "Practice Drills",
  description: "Endless timed practice — mental math, trigonometry, calculus, linear algebra, and geography.",
};

// Grouped like the iOS hub, so the growing list stays scannable. Each entry is a
// category with the drills (by slug) that belong to it, in display order.
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
];

function DrillCard({ d }: { d: DrillDef }) {
  return (
    <Link
      href={`/drills/${d.slug}`}
      className="group block h-full bg-crimson-900 border border-crimson-700 rounded-xl p-5 hover:border-gold-400 transition-colors"
    >
      <div className="flex items-center gap-3 mb-2">
        <span className="text-2xl" aria-hidden>{d.icon}</span>
        <h3 className="font-display text-lg text-parchment group-hover:text-gold-300 transition-colors">{d.title}</h3>
      </div>
      <p className="text-sm text-parchment-dim">{d.blurb}</p>
    </Link>
  );
}

export default function DrillsHubPage() {
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
                    <DrillCard d={d} />
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
