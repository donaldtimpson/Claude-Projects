"use client";

import { useState } from "react";

type Course = { id: string; title: string };
type Kind = "RECOMMENDED" | "RELATED";

// Each group maps a toggled course to an edge. `flip` swaps from/to so "Builds on"
// records `picked -> thisCourse` while "Leads to" records `thisCourse -> picked`.
const GROUPS = [
  {
    key: "buildsOn" as const,
    kind: "RECOMMENDED" as Kind,
    flip: true,
    title: "Builds on",
    blurb: "Recommended background — courses to watch before this one.",
  },
  {
    key: "leadsTo" as const,
    kind: "RECOMMENDED" as Kind,
    flip: false,
    title: "Leads to",
    blurb: "Natural follow-ups that build on this course.",
  },
  {
    key: "related" as const,
    kind: "RELATED" as Kind,
    flip: false,
    title: "Related material",
    blurb: "Thematically connected, in no particular order. Shows on both courses.",
  },
];

export default function ConnectionsEditor({
  courseId,
  others,
  initialBuildsOn,
  initialLeadsTo,
  initialRelated,
}: {
  courseId: string;
  others: Course[];
  initialBuildsOn: string[];
  initialLeadsTo: string[];
  initialRelated: string[];
}) {
  const [selected, setSelected] = useState<Record<string, Set<string>>>({
    buildsOn: new Set(initialBuildsOn),
    leadsTo: new Set(initialLeadsTo),
    related: new Set(initialRelated),
  });
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState<string | null>(null); // `${groupKey}:${otherId}`

  async function toggle(group: (typeof GROUPS)[number], otherId: string) {
    const isOn = selected[group.key].has(otherId);
    const method = isOn ? "DELETE" : "POST";
    const fromCourseId = group.flip ? otherId : courseId;
    const toCourseId = group.flip ? courseId : otherId;
    const tag = `${group.key}:${otherId}`;

    setBusy(tag);
    setError(null);
    try {
      const res = await fetch("/api/admin/course-links", {
        method,
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fromCourseId, toCourseId, kind: group.kind }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        setError(data.error ?? "Something went wrong.");
        return;
      }
      setSelected((prev) => {
        const next = new Set(prev[group.key]);
        if (isOn) next.delete(otherId);
        else next.add(otherId);
        return { ...prev, [group.key]: next };
      });
    } finally {
      setBusy(null);
    }
  }

  return (
    <div className="space-y-8">
      {error && (
        <p className="text-sm text-red-400 bg-red-950/40 border border-red-800 rounded-lg px-3 py-2">
          {error}
        </p>
      )}

      {GROUPS.map((group) => (
        <section key={group.key}>
          <h2 className="font-display tracking-wider uppercase text-sm text-gold-300">{group.title}</h2>
          <p className="text-xs text-parchment-dim mt-0.5 mb-3">{group.blurb}</p>
          <div className="flex flex-wrap gap-2">
            {others.map((c) => {
              const on = selected[group.key].has(c.id);
              const tag = `${group.key}:${c.id}`;
              // Avoid the obvious contradiction: a course can't be both a
              // prerequisite of and a follow-up to this one.
              const conflict =
                (group.key === "buildsOn" && selected.leadsTo.has(c.id)) ||
                (group.key === "leadsTo" && selected.buildsOn.has(c.id));
              return (
                <button
                  key={c.id}
                  type="button"
                  disabled={busy === tag || (conflict && !on)}
                  onClick={() => toggle(group, c.id)}
                  className={`text-xs px-3 py-1.5 rounded-full border transition-colors disabled:opacity-40 ${
                    on
                      ? "bg-gold-500 text-crimson-950 border-gold-500 hover:bg-gold-400"
                      : "bg-transparent text-parchment-dim border-crimson-700 hover:border-gold-500 hover:text-gold-300"
                  }`}
                >
                  {c.title}
                </button>
              );
            })}
          </div>
        </section>
      ))}
    </div>
  );
}
