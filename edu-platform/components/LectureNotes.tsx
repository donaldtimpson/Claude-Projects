"use client";

import { useState } from "react";
import MarkdownNotes from "./MarkdownNotes";

export default function LectureNotes({ content }: { content: string }) {
  const [open, setOpen] = useState(false);

  return (
    <section className="border border-crimson-700 rounded-xl overflow-hidden">
      <button
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className="w-full flex items-center gap-2 px-5 py-4 text-left hover:bg-crimson-800/40 transition-colors"
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
      {open && (
        <div className="px-5 pb-5 pt-1">
          <MarkdownNotes content={content} />
        </div>
      )}
    </section>
  );
}
