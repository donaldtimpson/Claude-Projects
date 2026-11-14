"use client";

import { useSyncExternalStore } from "react";

// Light/dark switch. The theme lives on <html data-theme> (set before paint by
// THEME_INIT_SCRIPT in app/layout.tsx) and is remembered in localStorage.
// Dark is the default; light is for projecting onto a whiteboard.

export const THEME_KEY = "theme";
const CHANGE_EVENT = "theme-change";

// Runs in <head> before first paint so a saved light theme never flashes dark.
export const THEME_INIT_SCRIPT = `try{if(localStorage.getItem("${THEME_KEY}")==="light")document.documentElement.dataset.theme="light"}catch(e){}`;

type Theme = "light" | "dark";

function subscribe(onChange: () => void) {
  window.addEventListener(CHANGE_EVENT, onChange);
  window.addEventListener("storage", onChange);
  return () => {
    window.removeEventListener(CHANGE_EVENT, onChange);
    window.removeEventListener("storage", onChange);
  };
}

const read = (): Theme => (document.documentElement.dataset.theme === "light" ? "light" : "dark");

function apply(theme: Theme) {
  if (theme === "light") document.documentElement.dataset.theme = "light";
  else delete document.documentElement.dataset.theme;
  try {
    localStorage.setItem(THEME_KEY, theme);
  } catch {
    // Storage blocked — the switch still applies for this page view.
  }
  window.dispatchEvent(new Event(CHANGE_EVENT));
}

export default function ThemeToggle({ className = "" }: { className?: string }) {
  const theme = useSyncExternalStore(subscribe, read, () => "dark" as Theme);
  const next: Theme = theme === "light" ? "dark" : "light";
  return (
    <button
      type="button"
      onClick={() => apply(next)}
      title={next === "light" ? "Switch to light mode (for projectors)" : "Switch to dark mode"}
      aria-label={next === "light" ? "Switch to light mode" : "Switch to dark mode"}
      className={`w-9 h-9 inline-flex items-center justify-center rounded-lg text-parchment-dim hover:text-gold-300 hover:bg-crimson-800 transition-colors ${className}`}
    >
      {theme === "light" ? (
        // Moon: go dark
        <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
          <path d="M21 12.8A9 9 0 1 1 11.2 3a7 7 0 0 0 9.8 9.8z" />
        </svg>
      ) : (
        // Sun: go light
        <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden="true">
          <circle cx="12" cy="12" r="4" />
          <path d="M12 2v2M12 20v2M4.9 4.9l1.4 1.4M17.7 17.7l1.4 1.4M2 12h2M20 12h2M4.9 19.1l1.4-1.4M17.7 6.3l1.4-1.4" />
        </svg>
      )}
    </button>
  );
}
