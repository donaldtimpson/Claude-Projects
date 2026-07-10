"use client";

import { useState } from "react";

export default function VideoDescription({ text }: { text: string }) {
  const [open, setOpen] = useState(false);

  return (
    <div className="mt-3">
      <button
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className="flex items-center gap-1.5 text-sm text-parchment-dim hover:text-parchment transition-colors"
      >
        <svg
          className={`w-3 h-3 shrink-0 transition-transform ${open ? "rotate-90" : ""}`}
          fill="currentColor"
          viewBox="0 0 20 20"
          aria-hidden="true"
        >
          <path d="M6 6l8 4-8 4V6z" />
        </svg>
        Description
      </button>
      {open && (
        <p className="mt-3 text-sm text-parchment-dim leading-relaxed whitespace-pre-line">
          {text}
        </p>
      )}
    </div>
  );
}
