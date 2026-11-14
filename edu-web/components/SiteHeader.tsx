import { Suspense } from "react";
import Link from "next/link";
import Image from "next/image";
import { cookies } from "next/headers";
import UserMenu from "@/components/UserMenu";
import SiteNav from "@/components/SiteNav";
import NavBreadcrumb from "@/components/NavBreadcrumb";
import SearchBox from "@/components/SearchBox";
import StreakBadge from "@/components/StreakBadge";
import ThemeToggle from "@/components/ThemeToggle";

export default async function SiteHeader() {
  const cookieStore = await cookies();
  const isAdmin = cookieStore.get("admin_auth")?.value === process.env.ADMIN_PASSWORD;

  return (
    // data-theme="dark": the header stays a crimson-and-gold band in both themes.
    <header data-theme="dark" className="bg-crimson-900 border-b border-crimson-700 px-6">
      <div className="max-w-6xl mx-auto flex items-center justify-between gap-4 h-16">
        <div className="flex items-center gap-3 min-w-0">
          <SiteNav isAdmin={isAdmin} />
          <Link href="/" className="flex items-center gap-3 shrink-0">
            <Image
              src="/logo.png"
              alt="The Timpson Lyceum seal"
              width={120}
              height={80}
              className="h-10 w-auto sm:h-12"
            />
            <span className="hidden md:inline font-display text-sm tracking-[0.2em] uppercase text-gold-300">
              The Timpson Lyceum
            </span>
          </Link>
          <NavBreadcrumb />
        </div>
        {/* Type-ahead search from sm up; on phones it would be a sliver, so an
            icon opens the full search page instead. */}
        <div className="hidden sm:flex flex-1 min-w-0 justify-center">
          <Suspense fallback={<div className="flex-1 max-w-sm" />}>
            <SearchBox />
          </Suspense>
        </div>
        <div className="flex items-center gap-3 shrink-0">
          <Link
            href="/search"
            aria-label="Search"
            className="sm:hidden w-9 h-9 inline-flex items-center justify-center rounded-lg text-parchment-dim hover:text-gold-300 hover:bg-crimson-800 transition-colors"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" aria-hidden="true">
              <circle cx="11" cy="11" r="7" />
              <path d="M20 20l-3.5-3.5" />
            </svg>
          </Link>
          <Suspense fallback={null}>
            <StreakBadge />
          </Suspense>
          <ThemeToggle />
          <UserMenu />
        </div>
      </div>
    </header>
  );
}
