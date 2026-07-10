"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { useSession, signOut } from "next-auth/react";
import { useEffect, useState } from "react";

export default function SiteNav({ isAdmin }: { isAdmin: boolean }) {
  const [open, setOpen] = useState(false);
  const pathname = usePathname();
  const { data: session } = useSession();

  // Close the drawer whenever we navigate to a new page.
  useEffect(() => {
    setOpen(false);
  }, [pathname]);

  // Close on Escape, and lock background scroll while open.
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === "Escape") setOpen(false);
    };
    window.addEventListener("keydown", onKey);
    const prevOverflow = document.body.style.overflow;
    document.body.style.overflow = "hidden";
    return () => {
      window.removeEventListener("keydown", onKey);
      document.body.style.overflow = prevOverflow;
    };
  }, [open]);

  const isActive = (href: string) =>
    href === "/" ? pathname === "/" : pathname.startsWith(href);

  return (
    <>
      <button
        onClick={() => setOpen(true)}
        aria-label="Open menu"
        aria-expanded={open}
        className="text-parchment-dim hover:text-gold-300 transition-colors p-1 -ml-1 shrink-0"
      >
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
          <line x1="3" y1="6" x2="21" y2="6" />
          <line x1="3" y1="12" x2="21" y2="12" />
          <line x1="3" y1="18" x2="21" y2="18" />
        </svg>
      </button>

      {/* Overlay + sliding panel. Always mounted so the slide transition runs both ways. */}
      <div className={`fixed inset-0 z-50 ${open ? "" : "pointer-events-none"}`} aria-hidden={!open}>
        <div
          onClick={() => setOpen(false)}
          className={`absolute inset-0 bg-black/60 transition-opacity duration-200 ${open ? "opacity-100" : "opacity-0"}`}
        />
        <nav
          className={`absolute left-0 top-0 h-full w-72 max-w-[80vw] bg-crimson-900 border-r border-crimson-700 shadow-2xl flex flex-col transition-transform duration-200 ease-out ${open ? "translate-x-0" : "-translate-x-full"}`}
        >
          <div className="flex items-center justify-between px-5 h-16 border-b border-crimson-700 shrink-0">
            <span className="font-display text-sm tracking-[0.2em] uppercase text-gold-300">Menu</span>
            <button
              onClick={() => setOpen(false)}
              aria-label="Close menu"
              className="text-parchment-dim hover:text-gold-300 transition-colors p-1 -mr-1"
            >
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round">
                <line x1="6" y1="6" x2="18" y2="18" />
                <line x1="18" y1="6" x2="6" y2="18" />
              </svg>
            </button>
          </div>

          <div className="flex-1 overflow-y-auto py-4 font-display text-xs tracking-[0.15em] uppercase">
            <DrawerLink href="/" label="Courses" active={isActive("/")} />
            <DrawerLink href="/map" label="Course Map" active={isActive("/map")} />
            <DrawerLink href="/drills" label="Practice Drills" active={isActive("/drills")} />
            <DrawerLink href="/leaderboard" label="Hall of Scholars" active={isActive("/leaderboard")} />
            {session?.user && (
              <DrawerLink href="/dashboard" label="My Progress" active={isActive("/dashboard")} />
            )}
            <a
              href="https://www.youtube.com/@donaldDtimpson"
              target="_blank"
              rel="noopener noreferrer"
              className="block px-5 py-3 text-parchment-dim hover:text-gold-300 hover:bg-crimson-800/50 transition-colors"
            >
              YouTube ↗
            </a>
            {isAdmin && <DrawerLink href="/admin" label="Admin" active={isActive("/admin")} accent />}
          </div>

          <div className="border-t border-crimson-700 p-4 shrink-0">
            {session?.user ? (
              <>
                <p className="text-sm text-parchment-dim mb-3 px-1">
                  Signed in as <span className="text-parchment">{session.user.name}</span>
                </p>
                <button
                  onClick={() => signOut({ callbackUrl: "/" })}
                  className="w-full text-left font-display text-xs tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 transition-colors px-1 py-1"
                >
                  Sign Out
                </button>
              </>
            ) : (
              <div className="space-y-2 font-display text-xs tracking-[0.15em] uppercase">
                <Link
                  href="/auth/signin"
                  className="block text-center text-parchment-dim hover:text-gold-300 transition-colors py-2"
                >
                  Sign In
                </Link>
                <Link
                  href="/auth/signup"
                  className="block text-center bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded py-2 font-semibold transition-colors"
                >
                  Sign Up
                </Link>
              </div>
            )}
          </div>
        </nav>
      </div>
    </>
  );
}

function DrawerLink({
  href,
  label,
  active,
  accent,
}: {
  href: string;
  label: string;
  active: boolean;
  accent?: boolean;
}) {
  const base = "block px-5 py-3 transition-colors";
  const tone = active
    ? "text-gold-300 bg-crimson-800"
    : accent
      ? "text-gold-400 hover:text-gold-300 hover:bg-crimson-800/50"
      : "text-parchment-dim hover:text-gold-300 hover:bg-crimson-800/50";
  return (
    <Link href={href} className={`${base} ${tone}`}>
      {label}
    </Link>
  );
}
