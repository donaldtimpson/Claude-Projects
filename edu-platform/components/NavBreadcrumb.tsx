"use client";

import { usePathname } from "next/navigation";

// Longest-prefix match wins, so /auth/signup beats /auth.
const TITLES: { prefix: string; label: string }[] = [
  { prefix: "/leaderboard", label: "Hall of Scholars" },
  { prefix: "/dashboard", label: "My Progress" },
  { prefix: "/courses", label: "Courses" },
  { prefix: "/categories", label: "Browse" },
  { prefix: "/auth/signup", label: "Sign Up" },
  { prefix: "/auth/signin", label: "Sign In" },
];

function pageTitle(pathname: string): string | null {
  if (pathname === "/") return null;
  const match = [...TITLES]
    .sort((a, b) => b.prefix.length - a.prefix.length)
    .find((t) => pathname === t.prefix || pathname.startsWith(`${t.prefix}/`) || pathname.startsWith(t.prefix));
  return match?.label ?? null;
}

export default function NavBreadcrumb() {
  const pathname = usePathname();
  const title = pageTitle(pathname);
  if (!title) return null;

  return (
    <span className="flex items-center gap-2 min-w-0 font-display text-xs tracking-[0.15em] uppercase text-parchment-dim">
      <span className="text-gold-500/50">/</span>
      <span className="truncate">{title}</span>
    </span>
  );
}
