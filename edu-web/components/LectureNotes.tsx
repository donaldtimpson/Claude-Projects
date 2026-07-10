"use client";

import { useState, useEffect } from "react";
import MarkdownNotes from "./MarkdownNotes";

export default function LectureNotes({ content, printHref }: { content: string; printHref: string }) {
  const [open, setOpen] = useState(false);

  // Auto-expand when the page targets the notes (the lecture "Notes" jump link, or
  // landing on the page with #notes) — otherwise jumping to an already-visible
  // collapsed header feels like nothing happened.
  useEffect(() => {
    const openIfTargeted = () => {
      if (window.location.hash === "#notes") setOpen(true);
    };
    openIfTargeted();
    window.addEventListener("hashchange", openIfTargeted);
    return () => window.removeEventListener("hashchange", openIfTargeted);
  }, []);

  return (
    <section className="border border-crimson-700 rounded-xl overflow-hidden">
      <div className="flex items-center justify-between pr-4 hover:bg-crimson-800/40 transition-colors">
        <button
          onClick={() => setOpen((o) => !o)}
          aria-expanded={open}
          className="flex-1 flex items-center gap-2 px-5 py-4 text-left"
        >
          <svg
            className={`w-3.5 h-3.5 shrink-0 text-gold-400 transition-transform ${open ? "rotate-90" : ""}`}
            fill="currentColor"
            viewBox="0 0 20 20"
            aria-hidden="true"
          >
            <path d="M6 6l8 4-8 4V6z" />
          </svg>
          <span className="font-display text-sm tracking-[0.15em] uppercase text-parchment">Lecture Notes</span>
        </button>
        <a
          href={printHref}
          target="_blank"
          rel="noopener noreferrer"
          className="shrink-0 flex items-center gap-1.5 text-xs text-parchment-dim hover:text-gold-300 transition-colors"
        >
          <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 16v2a2 2 0 002 2h12a2 2 0 002-2v-2M7 10l5 5 5-5M12 15V3" />
          </svg>
          PDF
        </a>
      </div>
      {open && (
        <div className="px-5 pb-5 pt-1">
          <MarkdownNotes content={content} />
        </div>
      )}
    </section>
  );
}
