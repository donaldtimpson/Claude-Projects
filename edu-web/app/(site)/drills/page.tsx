import Link from "next/link";
import type { Metadata } from "next";
import { DRILLS } from "@/lib/drills/registry";

export const metadata: Metadata = {
  title: "Practice Drills",
  description: "Endless timed practice — mental arithmetic, the unit circle, and vector components.",
};

export default function DrillsHubPage() {
  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10 space-y-8">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">Practice Drills</h1>
          <p className="text-parchment-dim text-sm">
            Fluency comes from reps. Each drill generates an endless stream of fresh problems —
            practice a fixed set or race the clock.
          </p>
        </div>

        <ul className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {DRILLS.map((d) => (
            <li key={d.slug}>
              <Link
                href={`/drills/${d.slug}`}
                className="group block h-full bg-crimson-900 border border-crimson-700 rounded-xl p-6 hover:border-gold-400 transition-colors"
              >
                <div className="flex items-center gap-3 mb-2">
                  <span className="text-2xl" aria-hidden>{d.icon}</span>
                  <h2 className="font-display text-lg text-parchment group-hover:text-gold-300 transition-colors">
                    {d.title}
                  </h2>
                </div>
                <p className="text-sm text-parchment-dim">{d.blurb}</p>
                <p className="mt-3 font-display text-[11px] uppercase tracking-[0.15em] text-gold-500">
                  {d.subject}
                </p>
              </Link>
            </li>
          ))}
        </ul>
      </div>
    </main>
  );
}
