"use client";

import Link from "next/link";
import { useRouter, useSearchParams } from "next/navigation";
import { useState, useEffect, useRef } from "react";

type CourseHit = { id: string; title: string; description: string };
type LectureHit = {
  videoId: string;
  courseId: string;
  title: string;
  courseTitle: string;
  startSeconds: number | null;
};
type Results = { courses: CourseHit[]; lectures: LectureHit[]; fuzzy?: boolean };

// How many of each to show in the compact dropdown; the rest live behind "see all".
const COURSE_CAP = 3;
const LECTURE_CAP = 6;

function formatTime(s: number): string {
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const ss = String(s % 60).padStart(2, "0");
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
}

function lectureHref(l: LectureHit): string {
  return l.startSeconds != null
    ? `/courses/${l.courseId}/${l.videoId}?t=${l.startSeconds}`
    : `/courses/${l.courseId}/${l.videoId}`;
}

// Live type-ahead search. Results appear in a dropdown as you type (debounced,
// with a spinner). The component lives in the persistent SiteHeader, so its state
// survives navigation — after clicking a result you can re-focus the box and your
// results are right there (easy mis-click recovery). Enter (or "see all") goes to
// the full /search page.
export default function SearchBox() {
  const router = useRouter();
  const [value, setValue] = useState(useSearchParams().get("q") ?? "");
  const [results, setResults] = useState<Results | null>(null);
  const [loading, setLoading] = useState(false);
  const [open, setOpen] = useState(false);
  const [active, setActive] = useState(-1);
  const boxRef = useRef<HTMLDivElement>(null);

  const q = value.trim();

  // Debounced fetch, cancelling any in-flight request on each keystroke.
  useEffect(() => {
    if (q.length < 2) {
      setResults(null);
      setLoading(false);
      return;
    }
    setLoading(true);
    const ctrl = new AbortController();
    const id = setTimeout(async () => {
      try {
        const res = await fetch(`/api/search?q=${encodeURIComponent(q)}`, { signal: ctrl.signal });
        setResults((await res.json()) as Results);
      } catch (e) {
        if ((e as Error).name !== "AbortError") setResults({ courses: [], lectures: [] });
      } finally {
        setLoading(false);
      }
    }, 250);
    return () => {
      clearTimeout(id);
      ctrl.abort();
    };
  }, [q]);

  // Close when clicking outside.
  useEffect(() => {
    function onDoc(e: MouseEvent) {
      if (boxRef.current && !boxRef.current.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onDoc);
    return () => document.removeEventListener("mousedown", onDoc);
  }, []);

  useEffect(() => setActive(-1), [results]);

  // Keep the keyboard-highlighted row scrolled into view.
  useEffect(() => {
    if (active >= 0) document.getElementById(`sr-opt-${active}`)?.scrollIntoView({ block: "nearest" });
  }, [active]);

  // Capped, displayed rows (and the parallel hrefs for keyboard nav).
  const courses = results?.courses.slice(0, COURSE_CAP) ?? [];
  const lectures = results?.lectures.slice(0, LECTURE_CAP) ?? [];
  const items = [...courses.map((c) => `/courses/${c.id}`), ...lectures.map(lectureHref)];
  const total = (results?.courses.length ?? 0) + (results?.lectures.length ?? 0);
  const empty = results != null && total === 0;

  function navigate(href: string) {
    setOpen(false);
    router.push(href);
  }

  function onKeyDown(e: React.KeyboardEvent) {
    if (e.key === "Escape") {
      setOpen(false);
      return;
    }
    if (e.key === "ArrowDown") {
      e.preventDefault();
      setOpen(true);
      setActive((a) => Math.min(a + 1, items.length - 1));
    } else if (e.key === "ArrowUp") {
      e.preventDefault();
      setActive((a) => Math.max(a - 1, -1));
    } else if (e.key === "Enter") {
      e.preventDefault();
      if (active >= 0 && items[active]) navigate(items[active]);
      else if (q) navigate(`/search?q=${encodeURIComponent(q)}`);
    }
  }

  const showDropdown = open && q.length >= 2;

  return (
    <div ref={boxRef} className="relative flex-1 min-w-0 max-w-xs sm:max-w-sm">
      <div className="relative">
        <svg
          aria-hidden="true"
          viewBox="0 0 20 20"
          fill="none"
          className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-parchment-dim"
        >
          <circle cx="9" cy="9" r="6" stroke="currentColor" strokeWidth="1.6" />
          <path d="M14 14l4 4" stroke="currentColor" strokeWidth="1.6" strokeLinecap="round" />
        </svg>
        <input
          type="search"
          value={value}
          onChange={(e) => {
            setValue(e.target.value);
            setOpen(true);
          }}
          onFocus={() => setOpen(true)}
          onKeyDown={onKeyDown}
          placeholder="Search lectures…"
          aria-label="Search the catalog"
          role="combobox"
          aria-expanded={showDropdown}
          aria-controls="search-results"
          aria-autocomplete="list"
          aria-activedescendant={active >= 0 ? `sr-opt-${active}` : undefined}
          className="w-full rounded-lg border border-crimson-700 bg-crimson-950/60 pl-9 pr-9 py-2 text-sm text-parchment placeholder:text-parchment-dim focus:border-gold-500 focus:outline-none"
        />
        {loading && (
          <span
            aria-hidden="true"
            className="absolute right-3 top-1/2 -translate-y-1/2 h-4 w-4 animate-spin rounded-full border-2 border-crimson-600 border-t-gold-400"
          />
        )}
      </div>

      {showDropdown && (
        <div
          id="search-results"
          role="listbox"
          className="absolute right-0 z-50 mt-2 w-[min(28rem,90vw)] max-h-[70vh] overflow-y-auto rounded-xl border border-crimson-700 bg-crimson-900 shadow-2xl"
        >
          {loading && !results && <p className="px-4 py-3 text-sm text-parchment-dim">Searching…</p>}

          {empty && <p className="px-4 py-3 text-sm text-parchment-dim">No matches for &ldquo;{q}&rdquo;.</p>}

          {results?.fuzzy && !empty && (
            <p className="border-b border-crimson-800 px-4 py-2 text-xs text-parchment-dim">
              No exact matches — did you mean:
            </p>
          )}

          {courses.length > 0 && (
            <div className="border-b border-crimson-800 py-1">
              <p className="px-4 pt-1 pb-0.5 font-display text-[0.65rem] uppercase tracking-[0.15em] text-gold-300/80">
                Courses
              </p>
              {courses.map((c, i) => (
                <Link
                  key={c.id}
                  id={`sr-opt-${i}`}
                  href={`/courses/${c.id}`}
                  onClick={() => setOpen(false)}
                  onMouseEnter={() => setActive(i)}
                  role="option"
                  aria-selected={active === i}
                  className={`block px-4 py-2 text-sm text-parchment ${active === i ? "bg-crimson-800" : ""}`}
                >
                  {c.title}
                </Link>
              ))}
            </div>
          )}

          {lectures.length > 0 && (
            <div className="py-1">
              <p className="px-4 pt-1 pb-0.5 font-display text-[0.65rem] uppercase tracking-[0.15em] text-gold-300/80">
                Lectures
              </p>
              {lectures.map((l, j) => {
                const idx = courses.length + j;
                return (
                  <Link
                    key={l.videoId}
                    id={`sr-opt-${idx}`}
                    href={lectureHref(l)}
                    onClick={() => setOpen(false)}
                    onMouseEnter={() => setActive(idx)}
                    role="option"
                    aria-selected={active === idx}
                    className={`block px-4 py-2 ${active === idx ? "bg-crimson-800" : ""}`}
                  >
                    <span className="flex items-baseline justify-between gap-2">
                      <span className="truncate text-sm text-parchment">{l.title}</span>
                      {l.startSeconds != null && (
                        <span className="shrink-0 text-xs text-gold-300">{formatTime(l.startSeconds)}</span>
                      )}
                    </span>
                    <span className="block truncate text-xs text-parchment-dim">{l.courseTitle}</span>
                  </Link>
                );
              })}
            </div>
          )}

          {results && !empty && (
            <Link
              href={`/search?q=${encodeURIComponent(q)}`}
              onClick={() => setOpen(false)}
              className="block border-t border-crimson-800 px-4 py-2 text-center text-xs font-medium text-gold-300 hover:bg-crimson-800"
            >
              See all {total} result{total === 1 ? "" : "s"} →
            </Link>
          )}
        </div>
      )}
    </div>
  );
}
