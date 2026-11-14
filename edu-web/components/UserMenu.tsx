"use client";

import { useSession } from "next-auth/react";
import Link from "next/link";

// Slim top-bar auth cluster. Sign-out and dashboard navigation now live in the
// slide-in menu (SiteNav); this keeps the header uncrowded.
export default function UserMenu() {
  const { data: session, status } = useSession();

  if (status === "loading") return null;

  if (session?.user) {
    return (
      <Link
        href="/dashboard"
        className="shrink-0 hover:text-gold-300 transition-colors text-parchment-dim text-xs tracking-[0.06em] uppercase font-ui font-semibold max-w-[8rem] truncate"
      >
        {session.user.name}
      </Link>
    );
  }

  return (
    <div className="flex items-center gap-4 shrink-0 font-ui font-semibold text-xs tracking-[0.06em] uppercase text-parchment-dim">
      <Link href="/auth/signin" className="hidden sm:inline hover:text-gold-300 transition-colors">
        Sign In
      </Link>
      <Link
        href="/auth/signup"
        className="font-ui font-semibold bg-gold-500 hover:bg-gold-400 text-crimson-950 px-3 py-1.5 rounded text-sm normal-case tracking-normal transition-colors"
      >
        Sign Up
      </Link>
    </div>
  );
}
