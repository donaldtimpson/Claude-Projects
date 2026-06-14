import type { Metadata } from "next";
import Link from "next/link";
import { searchCatalog } from "@/lib/search";

export const dynamic = "force-dynamic";

export const metadata: Metadata = { title: "Search" };

function formatTime(s: number): string {
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const x = s % 60;
  const ss = String(x).padStart(2, "0");
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
}

// Turn a ts_headline snippet ([[hl]]…[[/hl]] around matches) into highlighted nodes.
function renderSnippet(snippet: string) {
  const parts = snippet.split(/\[\[hl\]\](.*?)\[\[\/hl\]\]/g);
  return parts.map((part, i) =>
    i % 2 === 1 ? (
      <mark key={i} className="rounded bg-gold-500/30 px-0.5 text-parchment">
        {part}
      </mark>
    ) : (
      <span key={i}>{part}</span>
    ),
  );
}

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const q = ((await searchParams).q ?? "").trim();
  const { courses, lectures } = q ? await searchCatalog(q) : { courses: [], lectures: [] };
  const total = courses.length + lectures.length;

  return (
    <main className="flex-1">
      <div className="mx-auto max-w-5xl px-6 py-8 space-y-8">
        <header className="space-y-1">
          <h1 className="text-2xl font-bold text-parchment">
            {q ? <>Results for &ldquo;{q}&rdquo;</> : "Search"}
          </h1>
          {q && (
            <p className="text-sm text-parchment-dim">
              {total === 0 ? "No matches found." : `${total} result${total === 1 ? "" : "s"}`}
            </p>
          )}
        </header>

        {!q && (
          <p className="text-parchment-dim">
            Search across courses, lectures, study notes, and even what was said in each lecture.
            Try a topic like <span className="text-gold-300">angular momentum</span> or{" "}
            <span className="text-gold-300">proof by induction</span>.
          </p>
        )}

        {q && total === 0 && (
          <p className="text-parchment-dim">
            Nothing matched. Try different or fewer words.
          </p>
        )}

        {courses.length > 0 && (
          <section className="space-y-3">
            <h2 className="font-display text-sm uppercase tracking-[0.15em] text-gold-300">
              Courses
            </h2>
            <ul className="space-y-2">
              {courses.map((c) => (
                <li key={c.id}>
                  <Link
                    href={`/courses/${c.id}`}
                    className="block rounded-xl border border-crimson-700 bg-crimson-900 px-4 py-3 transition-colors hover:border-gold-500"
                  >
                    <span className="font-semibold text-parchment">{c.title}</span>
                    {c.description && (
                      <span className="mt-1 block text-sm text-parchment-dim line-clamp-2">
                        {c.description}
                      </span>
                    )}
                  </Link>
                </li>
              ))}
            </ul>
          </section>
        )}

        {lectures.length > 0 && (
          <section className="space-y-3">
            <h2 className="font-display text-sm uppercase tracking-[0.15em] text-gold-300">
              Lectures
            </h2>
            <ul className="space-y-2">
              {lectures.map((l) => {
                const href =
                  l.startSeconds != null
                    ? `/courses/${l.courseId}/${l.videoId}?t=${l.startSeconds}`
                    : `/courses/${l.courseId}/${l.videoId}`;
                return (
                  <li key={l.videoId}>
                    <Link
                      href={href}
                      className="block rounded-xl border border-crimson-700 bg-crimson-900 px-4 py-3 transition-colors hover:border-gold-500"
                    >
                      <div className="flex items-baseline justify-between gap-3">
                        <span className="font-semibold text-parchment">{l.title}</span>
                        {l.startSeconds != null && (
                          <span className="shrink-0 font-display text-xs tracking-[0.1em] text-gold-300">
                            jump to {formatTime(l.startSeconds)} →
                          </span>
                        )}
                      </div>
                      <span className="mt-0.5 block text-xs text-parchment-dim">{l.courseTitle}</span>
                      {l.snippet && (
                        <p className="mt-2 text-sm italic text-parchment-dim">
                          …{renderSnippet(l.snippet)}…
                          <span className="ml-1 not-italic text-[0.7rem] uppercase tracking-wide text-parchment-dim/70">
                            from transcript
                          </span>
                        </p>
                      )}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </section>
        )}
      </div>
    </main>
  );
}
