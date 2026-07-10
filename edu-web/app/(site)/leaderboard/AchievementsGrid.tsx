"use client";

import { useState } from "react";
import { CATEGORIES, TIERS, type Badge, type Tier } from "@/lib/gamification/mock";

// Per-tier card styling. Omniscient is handled by its own bespoke card.
const TIER_STYLES: Record<Exclude<Tier, "omniscient">, { ring: string; chip: string; name: string }> = {
  bronze: { ring: "border-amber-700/70", chip: "bg-amber-700 text-amber-50", name: "text-amber-300" },
  silver: { ring: "border-zinc-400/70", chip: "bg-zinc-300 text-zinc-900", name: "text-zinc-100" },
  gold: { ring: "border-gold-500", chip: "bg-gold-500 text-crimson-950", name: "text-gold-300" },
  platinum: { ring: "border-sky-300/80", chip: "bg-sky-200 text-sky-950", name: "text-sky-200" },
};

export default function AchievementsGrid({ badges }: { badges: Badge[] }) {
  const [showAll, setShowAll] = useState(false);

  const omniscient = badges.find((b) => b.tier === "omniscient");
  const rest = badges.filter((b) => b.tier !== "omniscient");
  const earnedCount = rest.filter((b) => b.unlocked).length;

  return (
    <div className="space-y-8">
      {/* Tally reconciles with the six category counts (the catalog), with the
          one-of-a-kind Omniscient called out separately so nothing is hidden. */}
      <div className="flex flex-wrap items-center justify-between gap-3">
        <p className="text-xs text-parchment-dim">
          <span className="text-parchment font-medium">{earnedCount} / {rest.length}</span> earned
          {omniscient && (
            <span className="ml-3 text-gold-400">
              ✦ Omniscient — {omniscient.unlocked ? "Attained" : "Unclaimed"}
            </span>
          )}
        </p>
        <button
          onClick={() => setShowAll((v) => !v)}
          className="font-display text-xs tracking-[0.15em] uppercase text-gold-400 hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-4 py-2 transition-colors"
        >
          {showAll ? "Show only earned" : "Show all achievements"}
        </button>
      </div>

      {omniscient && <OmniscientCard badge={omniscient} />}

      {CATEGORIES.map((cat) => {
        const list = rest.filter((b) => b.category === cat.key);
        if (list.length === 0) return null;
        const earned = list.filter((b) => b.unlocked).length;
        const visible = showAll ? list : list.filter((b) => b.unlocked);
        if (visible.length === 0) return null; // hide categories with nothing earned when collapsed

        return (
          <section key={cat.key} className="space-y-3">
            <div className="flex items-baseline justify-between gap-3">
              <h3 className="font-display text-sm text-parchment">
                <span className="mr-2">{cat.icon}</span>
                {cat.label}
                <span className="text-parchment-dim font-sans text-xs ml-3">{cat.blurb}</span>
              </h3>
              <span className="text-xs text-parchment-dim shrink-0">
                {earned} / {list.length}
              </span>
            </div>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {visible.map((b) => (
                <BadgeCard key={b.key} badge={b} />
              ))}
            </div>
          </section>
        );
      })}
    </div>
  );
}

function BadgeCard({ badge }: { badge: Badge }) {
  const tier = TIERS[badge.tier];
  const style = TIER_STYLES[badge.tier as Exclude<Tier, "omniscient">];

  if (!badge.unlocked) {
    return (
      <div className="rounded-xl p-4 border border-crimson-800 bg-crimson-950 text-center opacity-50">
        <span className="inline-block text-[10px] uppercase tracking-widest rounded px-2 py-0.5 mb-2 font-display bg-crimson-800 text-parchment-dim">
          {tier.label} · Locked
        </span>
        <p className="text-sm font-medium text-parchment-dim">{badge.name}</p>
        <p className="text-xs text-parchment-dim mt-1 leading-snug">{badge.blurb}</p>
      </div>
    );
  }

  return (
    <div className={`rounded-xl p-4 border bg-crimson-900 text-center ${style.ring}`}>
      <span className={`inline-block text-[10px] uppercase tracking-widest rounded px-2 py-0.5 mb-2 font-display ${style.chip}`}>
        {tier.label}
      </span>
      <p className={`text-sm font-medium ${style.name}`}>{badge.name}</p>
      <p className="text-xs text-parchment-dim mt-1 leading-snug">{badge.blurb}</p>
    </div>
  );
}

// A tier all its own — shimmering gradient border + glow, gradient-filled title.
function OmniscientCard({ badge }: { badge: Badge }) {
  return (
    <div className="relative rounded-2xl p-[2px] bg-gradient-to-r from-gold-300 via-parchment to-gold-300 shadow-[0_0_45px_-10px] shadow-gold-400/60">
      <div className="absolute inset-0 rounded-2xl bg-gradient-to-r from-gold-300 via-parchment to-gold-300 opacity-40 blur-md animate-pulse pointer-events-none" />
      <div className="relative rounded-2xl bg-crimson-950 px-6 py-5 flex items-center justify-between gap-4">
        <div className="min-w-0">
          <span className="inline-block text-[10px] uppercase tracking-[0.3em] rounded px-2 py-0.5 mb-2 font-display bg-gradient-to-r from-gold-200 via-parchment to-gold-300 text-crimson-950">
            Omniscient · {TIERS.omniscient.points.toLocaleString()} pts
          </span>
          <p className="font-display text-2xl bg-gradient-to-r from-gold-200 via-parchment to-gold-300 bg-clip-text text-transparent">
            {badge.name}
          </p>
          <p className="text-xs text-parchment-dim mt-1 max-w-md leading-snug">{badge.blurb}</p>
        </div>
        <div className="shrink-0 text-right font-display text-xs uppercase tracking-widest">
          {badge.unlocked ? (
            <span className="text-gold-300">Attained</span>
          ) : (
            <span className="text-parchment-dim">Unclaimed</span>
          )}
        </div>
      </div>
    </div>
  );
}
