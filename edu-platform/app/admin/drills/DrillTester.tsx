"use client";

import { useState } from "react";
import DrillSession from "@/app/(site)/drills/[slug]/DrillSession";

type DrillCard = { slug: string; title: string; blurb: string; icon: string; subject: string };

export default function DrillTester({ drills }: { drills: DrillCard[] }) {
  const [slug, setSlug] = useState<string | null>(null);
  const active = drills.find((d) => d.slug === slug);

  return (
    <div className="space-y-6">
      <div className="flex flex-wrap gap-2">
        {drills.map((d) => (
          <button
            key={d.slug}
            onClick={() => setSlug(d.slug)}
            className={`flex items-center gap-2 px-3 py-2 rounded-lg border text-sm transition-colors ${
              slug === d.slug
                ? "border-gold-500 bg-crimson-800 text-gold-300"
                : "border-crimson-700 bg-crimson-800 text-parchment-dim hover:border-gold-400 hover:text-parchment"
            }`}
          >
            <span aria-hidden>{d.icon}</span>
            {d.title}
          </button>
        ))}
      </div>

      {active ? (
        <div className="space-y-3">
          <p className="text-sm text-parchment-dim">{active.blurb}</p>
          {/* Re-key on slug so switching drills resets the session cleanly. */}
          <DrillSession key={active.slug} slug={active.slug} persist={false} />
        </div>
      ) : (
        <p className="text-parchment-dim text-sm">Pick a drill above to try it.</p>
      )}
    </div>
  );
}
