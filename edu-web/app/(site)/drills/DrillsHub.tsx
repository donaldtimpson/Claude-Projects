"use client";

// The drills hub browser — mirrors the iOS DrillsView: a search field, a "Continue"
// strip of recently-opened drills, and seven category rows you click into. With a
// query typed, it switches to matching categories + drills with the match highlighted.
//
// Takes plain serializable metadata (not DrillDefs, which hold functions) so the hub
// stays a light client bundle and never pulls the drill banks or geo atlas onto it.

import { useMemo, useState, useSyncExternalStore } from "react";
import Link from "next/link";
import {
  subscribeRecents,
  getRecentsSnapshot,
  getRecentsServerSnapshot,
} from "@/lib/drills/recents";

export type DrillMeta = { slug: string; title: string; blurb: string; icon: string };
export type CategoryMeta = { slug: string; title: string; icon: string; drills: DrillMeta[] };

// Bold + gold the case-insensitive matches of `query`, so the user sees why a result matched.
function Highlight({ text, query }: { text: string; query: string }) {
  const q = query.trim();
  if (!q) return <>{text}</>;
  const parts: React.ReactNode[] = [];
  const lower = text.toLowerCase();
  const needle = q.toLowerCase();
  let i = 0;
  let k = 0;
  for (;;) {
    const at = lower.indexOf(needle, i);
    if (at === -1) break;
    if (at > i) parts.push(text.slice(i, at));
    parts.push(
      <strong key={k++} className="text-gold-300 font-semibold">
        {text.slice(at, at + q.length)}
      </strong>,
    );
    i = at + q.length;
  }
  parts.push(text.slice(i));
  return <>{parts}</>;
}

function DrillRow({ d, aced, query = "" }: { d: DrillMeta; aced?: boolean; query?: string }) {
  return (
    <Link
      href={`/drills/${d.slug}`}
      className="flex items-start gap-3 bg-crimson-900 border border-crimson-700 rounded-xl p-4 hover:border-gold-400 transition-colors"
    >
      <span className="text-3xl leading-none shrink-0" aria-hidden>{d.icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block font-display text-lg text-parchment">
          <Highlight text={d.title} query={query} />
        </span>
        <span className="block text-sm text-parchment-dim">
          <Highlight text={d.blurb} query={query} />
        </span>
        {aced && (
          <span className="block text-xs font-semibold text-gold-300 mt-1">✦ Aced</span>
        )}
      </span>
    </Link>
  );
}

function SectionHeader({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="font-display text-sm tracking-[0.15em] uppercase text-gold-400">{children}</h2>
  );
}

export default function DrillsHub({
  categories,
  acedSlugs,
  lessonCategorySlug,
}: {
  categories: CategoryMeta[];
  acedSlugs: string[];
  lessonCategorySlug: string;
}) {
  const [query, setQuery] = useState("");
  const aced = useMemo(() => new Set(acedSlugs), [acedSlugs]);

  // Device-local recents. Empty on the server, real after hydration — see recents.ts.
  const recentsCSV = useSyncExternalStore(
    subscribeRecents,
    getRecentsSnapshot,
    getRecentsServerSnapshot,
  );

  const bySlug = useMemo(() => {
    const m = new Map<string, DrillMeta>();
    for (const c of categories) for (const d of c.drills) m.set(d.slug, d);
    return m;
  }, [categories]);

  const recents = useMemo(
    () =>
      recentsCSV
        .split(",")
        .filter(Boolean)
        .map((s) => bySlug.get(s))
        .filter((d): d is DrillMeta => Boolean(d)),
    [recentsCSV, bySlug],
  );

  const q = query.trim().toLowerCase();
  const matchingCategories = categories.filter((c) => c.title.toLowerCase().includes(q));
  // Match on title, blurb, AND category name — so "geography" surfaces every map drill.
  const matchingDrills = q
    ? categories.flatMap((c) =>
        c.drills.filter((d) => `${d.title} ${d.blurb} ${c.title}`.toLowerCase().includes(q)),
      )
    : [];

  return (
    <div className="space-y-8">
      <label className="block">
        <span className="sr-only">Search drills</span>
        <input
          type="search"
          value={query}
          onChange={(e) => setQuery(e.target.value)}
          placeholder="Search drills…"
          className="w-full bg-crimson-900 border border-crimson-700 rounded-xl px-4 py-3 text-parchment placeholder:text-parchment-dim focus:border-gold-400 focus:outline-none transition-colors"
        />
      </label>

      {q ? (
        <div className="space-y-8">
          {matchingCategories.length === 0 && matchingDrills.length === 0 && (
            <p className="text-parchment-dim py-10 text-center">No matches for “{query}”.</p>
          )}

          {matchingCategories.length > 0 && (
            <section className="space-y-4">
              <SectionHeader>Categories</SectionHeader>
              <ul className="space-y-3">
                {matchingCategories.map((c) => (
                  <li key={c.slug}>
                    <CategoryRow
                      c={c}
                      query={query}
                      acedCount={
                        c.slug === lessonCategorySlug
                          ? c.drills.filter((d) => aced.has(d.slug)).length
                          : undefined
                      }
                    />
                  </li>
                ))}
              </ul>
            </section>
          )}

          {matchingDrills.length > 0 && (
            <section className="space-y-4">
              <SectionHeader>Drills</SectionHeader>
              <ul className="space-y-3">
                {matchingDrills.map((d) => (
                  <li key={d.slug}>
                    <DrillRow d={d} aced={aced.has(d.slug)} query={query} />
                  </li>
                ))}
              </ul>
            </section>
          )}
        </div>
      ) : (
        <div className="space-y-8">
          {recents.length > 0 && (
            <section className="space-y-4">
              <SectionHeader>Continue</SectionHeader>
              <ul className="flex gap-3 overflow-x-auto pb-2">
                {recents.map((d) => (
                  <li key={d.slug} className="shrink-0">
                    <Link
                      href={`/drills/${d.slug}`}
                      className="flex w-32 h-32 flex-col items-center justify-center gap-2 text-center bg-crimson-900 border border-crimson-700 rounded-xl p-3 hover:border-gold-400 transition-colors"
                    >
                      <span className="text-4xl leading-none" aria-hidden>{d.icon}</span>
                      <span className="text-sm text-parchment line-clamp-2">{d.title}</span>
                      {aced.has(d.slug) && (
                        <span className="text-xs font-semibold text-gold-300">✦ Aced</span>
                      )}
                    </Link>
                  </li>
                ))}
              </ul>
            </section>
          )}

          <section className="space-y-4">
            <SectionHeader>Categories</SectionHeader>
            <ul className="space-y-3">
              {categories.map((c) => (
                <li key={c.slug}>
                  <CategoryRow
                    c={c}
                    acedCount={
                      c.slug === lessonCategorySlug
                        ? c.drills.filter((d) => aced.has(d.slug)).length
                        : undefined
                    }
                  />
                </li>
              ))}
            </ul>
          </section>
        </div>
      )}
    </div>
  );
}

function CategoryRow({
  c,
  query = "",
  acedCount,
}: {
  c: CategoryMeta;
  query?: string;
  acedCount?: number;
}) {
  // The lesson track counts aced lessons; every other category just counts drills.
  const subtitle =
    acedCount !== undefined
      ? acedCount > 0
        ? `✦ ${acedCount}/${c.drills.length} aced`
        : `${c.drills.length} lessons`
      : `${c.drills.length} drills`;
  return (
    <Link
      href={`/drills/c/${c.slug}`}
      className="flex items-center gap-4 bg-crimson-900 border border-crimson-700 rounded-xl p-4 hover:border-gold-400 transition-colors"
    >
      <span className="text-3xl leading-none shrink-0" aria-hidden>{c.icon}</span>
      <span className="min-w-0 flex-1">
        <span className="block font-display text-lg text-parchment">
          <Highlight text={c.title} query={query} />
        </span>
        <span
          className={`block text-sm ${
            acedCount !== undefined && acedCount > 0 ? "text-gold-400" : "text-parchment-dim"
          }`}
        >
          {subtitle}
        </span>
      </span>
      <span className="text-parchment-dim shrink-0" aria-hidden>›</span>
    </Link>
  );
}
