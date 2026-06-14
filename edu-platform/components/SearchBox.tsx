"use client";

import { useRouter, useSearchParams } from "next/navigation";
import { useState, useEffect } from "react";

// Header search box. Submits to /search?q=… (a plain navigation, no fetch).
// Prefills with the current query when already on the results page.
export default function SearchBox() {
  const router = useRouter();
  const params = useSearchParams();
  const [value, setValue] = useState("");

  // Keep in sync with the URL's q when on /search (e.g. back/forward nav).
  useEffect(() => {
    setValue(params.get("q") ?? "");
  }, [params]);

  function submit(e: React.FormEvent) {
    e.preventDefault();
    const q = value.trim();
    if (q) router.push(`/search?q=${encodeURIComponent(q)}`);
  }

  return (
    <form onSubmit={submit} role="search" className="flex-1 max-w-xs sm:max-w-sm">
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
          name="q"
          value={value}
          onChange={(e) => setValue(e.target.value)}
          placeholder="Search lectures…"
          aria-label="Search the catalog"
          className="w-full rounded-lg border border-crimson-700 bg-crimson-950/60 pl-9 pr-3 py-2 text-sm text-parchment placeholder:text-parchment-dim focus:border-gold-500 focus:outline-none"
        />
      </div>
    </form>
  );
}
