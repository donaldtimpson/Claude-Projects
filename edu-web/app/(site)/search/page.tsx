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
  const results = q ? await searchCatalog(q) : { courses: [], lectures: [], fuzzy: false };
  const { courses, lectures } = results;
  const total = courses.length + lectures.length;

  return (
    <main className="flex-1">
      <div className="mx-auto max-w-5xl px-6 py-8 space-y-8">
        <header className="space-y-3">
          {/* Plain GET form: the only search box on phones, where the header shows an icon. */}
          <form action="/search" role="search" className="sm:hidden flex gap-2 mb-6">
            <input
              type="search"
              name="q"
              defaultValue={q}
              placeholder="Search lectures, notes, and transcripts…"
              aria-label="Search"
              className="flex-1 min-w-0 bg-field border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/70 transition-colors"
            />
            <button
              type="submit"
              className="font-ui font-semibold px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm rounded-lg transition-colors"
            >
              Search
            </button>
          </form>
          <h1 className="font-bold text-2xl text-parchment">
            {q ? <>Results for &ldquo;{q}&rdquo;</> : "Search"}
          </h1>
          {q && (
            <p className="text-sm text-parchment-dim">
              {total === 0 ? "No matches found." : `${total} result${total === 1 ? "" : "s"}`}
            </p>
          )}
          {results.fuzzy && total > 0 && (
            <p className="text-sm text-parchment-dim italic">No exact matches — showing the closest results.</p>
          )}
        </header>

        {!q && (
          <p className="text-parchment-dim">
            Search across courses, lectures, study notes, and even what was said in each lecture.
            Try a topic like <em className="text-parchment">angular momentum</em> or{" "}
            <em className="text-parchment">proof by induction</em>.
          </p>
        )}

        {q && total === 0 && (
          <p className="text-parchment-dim">
            Nothing matched. Try different or fewer words.
          </p>
        )}

        {courses.length > 0 && (
          <section className="space-y-3">
            <h2 className="section-title">
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
            <h2 className="section-title">
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
                          <span className="shrink-0 text-xs font-medium tabular-nums text-gold-300">
                            jump to {formatTime(l.startSeconds)} →
                          </span>
                        )}
                      </div>
                      <span className="mt-0.5 block text-xs text-parchment-dim">{l.courseTitle}</span>
                      {l.snippet && (
                        <p className="mt-2 text-sm italic text-parchment-dim">
                          …{renderSnippet(l.snippet)}…
                          <span className="font-ui font-semibold ml-1 not-italic text-[0.7rem] uppercase tracking-wide text-parchment-dim/70">
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
