"use client";

import Link from "next/link";
import { useSyncExternalStore } from "react";
import { usePathname, useRouter } from "next/navigation";
import SyncButton from "./SyncButton";
import ThemeToggle from "@/components/ThemeToggle";

// Grouped admin nav. Course-scoped editors (test / connections / problem sets)
// are no longer top-level — they live as tabs inside the course hub, so
// "Courses" also owns /admin/courses/* and the /admin/problem-sets/[id] editor.
const GROUPS: { title: string; items: { label: string; href: string; match: (p: string) => boolean }[] }[] = [
  {
    title: "Content",
    items: [
      {
        label: "Courses",
        href: "/admin",
        match: (p) =>
          p === "/admin" || p.startsWith("/admin/courses") || p.startsWith("/admin/problem-sets"),
      },
      { label: "Categories", href: "/admin/categories", match: (p) => p.startsWith("/admin/categories") },
      { label: "Resources", href: "/admin/resources", match: (p) => p.startsWith("/admin/resources") },
    ],
  },
  {
    title: "Classroom",
    items: [{ label: "Classes", href: "/admin/classes", match: (p) => p.startsWith("/admin/classes") }],
  },
  {
    title: "Community",
    items: [
      { label: "Announcements", href: "/admin/announcements", match: (p) => p.startsWith("/admin/announcements") },
      { label: "Comments", href: "/admin/comments", match: (p) => p.startsWith("/admin/comments") },
    ],
  },
  {
    title: "Tools",
    items: [
      { label: "Achievements", href: "/admin/achievements", match: (p) => p.startsWith("/admin/achievements") },
      { label: "Drill tester", href: "/admin/drills", match: (p) => p.startsWith("/admin/drills") },
    ],
  },
];

// Collapsed state is a per-device preference in localStorage, read through
// useSyncExternalStore so the server render (expanded) and client agree.
const COLLAPSED_KEY = "admin-sidebar-collapsed";
const CHANGE_EVENT = "admin-sidebar-change";

function subscribe(onChange: () => void) {
  window.addEventListener("storage", onChange);
  window.addEventListener(CHANGE_EVENT, onChange);
  return () => {
    window.removeEventListener("storage", onChange);
    window.removeEventListener(CHANGE_EVENT, onChange);
  };
}

function readCollapsed() {
  try {
    return localStorage.getItem(COLLAPSED_KEY) === "1";
  } catch {
    return false;
  }
}

function setCollapsed(value: boolean) {
  try {
    localStorage.setItem(COLLAPSED_KEY, value ? "1" : "0");
  } catch {
    // Storage blocked — the toggle still works until the next reload.
  }
  window.dispatchEvent(new Event(CHANGE_EVENT));
}

export default function AdminSidebar() {
  const pathname = usePathname() ?? "";
  const router = useRouter();
  const collapsed = useSyncExternalStore(subscribe, readCollapsed, () => false);

  // The login screen has no session — keep it chrome-free.
  if (pathname === "/admin/login") return null;

  async function logout() {
    await fetch("/api/admin/login", { method: "DELETE" });
    router.push("/admin/login");
    router.refresh();
  }

  if (collapsed) {
    return (
      <aside data-theme="dark" className="bg-crimson-900 md:w-10 md:shrink-0 md:min-h-screen border-b md:border-b-0 md:border-r border-crimson-700 flex md:flex-col items-center px-2 py-2 md:px-0 md:py-4 gap-3">
        <button
          type="button"
          onClick={() => setCollapsed(false)}
          title="Show sidebar"
          aria-label="Show sidebar"
          className="w-7 h-7 rounded-md text-parchment-dim hover:text-gold-300 hover:bg-crimson-800 transition-colors"
        >
          »
        </button>
        <ThemeToggle className="w-7 h-7" />
        <span className="font-ui font-semibold text-[11px] tracking-[0.06em] uppercase text-parchment-dim/60 md:[writing-mode:vertical-rl]">
          Admin
        </span>
      </aside>
    );
  }

  return (
    // data-theme="dark": the sidebar stays a crimson band in both themes.
    <aside data-theme="dark" className="bg-crimson-900 md:w-56 md:shrink-0 md:min-h-screen border-b md:border-b-0 md:border-r border-crimson-700 flex flex-col">
      <div className="px-4 py-4 flex items-center justify-between md:block gap-3">
        <div className="flex items-center justify-between gap-3">
          <span className="font-ui font-semibold text-sm tracking-[0.06em] uppercase text-gold-300">Admin</span>
          <button
            type="button"
            onClick={() => setCollapsed(true)}
            title="Hide sidebar"
            aria-label="Hide sidebar"
            className="w-7 h-7 rounded-md text-parchment-dim hover:text-gold-300 hover:bg-crimson-800 transition-colors"
          >
            «
          </button>
        </div>
        <Link
          href="/"
          className="text-parchment-dim hover:text-parchment text-xs transition-colors md:block md:mt-1"
        >
          ← Site
        </Link>
      </div>

      <nav className="flex-1 px-2 pb-4 flex flex-row flex-wrap md:flex-col gap-y-4 gap-x-6">
        {GROUPS.map((group) => (
          <div key={group.title} className="space-y-1 md:w-full">
            <p className="px-2 text-[11px] font-ui font-semibold tracking-[0.06em] uppercase text-parchment-dim/60">
              {group.title}
            </p>
            {group.items.map((item) => {
              const active = item.match(pathname);
              return (
                <Link
                  key={item.href}
                  href={item.href}
                  aria-current={active ? "page" : undefined}
                  className={`block text-sm px-2 py-1.5 rounded-lg transition-colors ${
                    active
                      ? "bg-crimson-800 text-gold-300"
                      : "text-parchment-dim hover:text-parchment hover:bg-crimson-800/50"
                  }`}
                >
                  {item.label}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      <div className="px-4 py-4 border-t border-crimson-700 space-y-3">
        <SyncButton />
        <div className="flex items-center justify-between gap-3">
          <ThemeToggle />
          <button
            type="button"
            onClick={logout}
            className="font-ui text-sm text-parchment-dim hover:text-red-400 transition-colors"
          >
            Logout
          </button>
        </div>
      </div>
    </aside>
  );
}
