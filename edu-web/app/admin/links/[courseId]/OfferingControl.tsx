"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";

type Course = { id: string; title: string };

export default function OfferingControl({
  courseId,
  canonicalCourseId,
  canonicalTitle,
  offerings,
  representatives,
}: {
  courseId: string;
  canonicalCourseId: string | null;
  canonicalTitle: string | null;
  offerings: Course[];
  representatives: Course[];
}) {
  const router = useRouter();
  const [pending, startTransition] = useTransition();
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const hasOfferings = offerings.length > 0;

  async function setCanonical(value: string) {
    setBusy(true);
    setError(null);
    try {
      const res = await fetch("/api/admin/course-offerings", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ courseId, canonicalCourseId: value || null }),
      });
      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        setError(data.error ?? "Something went wrong.");
        return;
      }
      startTransition(() => router.refresh());
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-lg px-4 py-3">
      <h2 className="font-display tracking-wider uppercase text-sm text-gold-300">Subject</h2>

      {hasOfferings ? (
        <p className="text-xs text-parchment-dim mt-1">
          This is the canonical offering for its subject. Other offerings:{" "}
          <span className="text-parchment">{offerings.map((o) => o.title).join(", ")}</span>. Detach them
          (on their own pages) before making this an offering of another subject.
        </p>
      ) : (
        <>
          <p className="text-xs text-parchment-dim mt-1 mb-2">
            If you teach this subject more than once, mark this playlist as another offering of the canonical
            one. Connections are then defined once on the canonical and inherited here.
          </p>
          <label className="flex flex-wrap items-center gap-2 text-sm">
            <span className="text-parchment-dim">This course is</span>
            <select
              value={canonicalCourseId ?? ""}
              disabled={busy}
              onChange={(e) => setCanonical(e.target.value)}
              className="bg-crimson-950 border border-crimson-700 rounded px-2 py-1 text-parchment focus:border-gold-500 outline-none disabled:opacity-50 max-w-xs"
            >
              <option value="">its own subject</option>
              {representatives.map((c) => (
                <option key={c.id} value={c.id}>
                  an offering of — {c.title}
                </option>
              ))}
            </select>
          </label>
          {canonicalTitle && (
            <p className="text-xs text-parchment-dim mt-2">
              Currently an offering of <span className="text-parchment">{canonicalTitle}</span>.
            </p>
          )}
        </>
      )}

      {error && <p className="text-xs text-red-400 mt-2">{error}</p>}
      {pending && <p className="text-xs text-parchment-dim mt-2">Saving…</p>}
    </section>
  );
}
