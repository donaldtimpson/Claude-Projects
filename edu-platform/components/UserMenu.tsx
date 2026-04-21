"use client";

import { useSession, signOut } from "next-auth/react";
import Link from "next/link";

export default function UserMenu() {
  const { data: session, status } = useSession();

  if (status === "loading") return null;

  if (session?.user) {
    return (
      <div className="flex items-center gap-4">
        <Link href="/dashboard" className="hover:text-gold-300 transition-colors hidden sm:block text-parchment-300 text-xs tracking-widest uppercase font-display">
          {session.user.name}
        </Link>
        <Link href="/dashboard" className="hover:text-gold-300 transition-colors sm:hidden">
          Progress
        </Link>
        <button
          onClick={() => signOut({ callbackUrl: "/" })}
          className="hover:text-gold-300 transition-colors"
        >
          Sign Out
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-4">
      <Link href="/auth/signin" className="hover:text-gold-300 transition-colors">
        Sign In
      </Link>
      <Link
        href="/auth/signup"
        className="bg-gold-600 hover:bg-gold-500 text-crimson-950 px-3 py-1 rounded text-xs font-semibold transition-colors"
      >
        Sign Up
      </Link>
    </div>
  );
}
