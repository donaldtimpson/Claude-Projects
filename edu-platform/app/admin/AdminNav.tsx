"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

// Global admin section nav. "Courses" covers the dashboard plus the
// course-scoped editors (hub / test / connections) reached from it.
const ITEMS: { label: string; href: string; match: (p: string) => boolean }[] = [
  {
    label: "Courses",
    href: "/admin",
    match: (p) =>
      p === "/admin" ||
      p.startsWith("/admin/courses") ||
      p.startsWith("/admin/test") ||
      p.startsWith("/admin/links"),
  },
  { label: "Comments", href: "/admin/comments", match: (p) => p.startsWith("/admin/comments") },
  { label: "Announcements", href: "/admin/announcements", match: (p) => p.startsWith("/admin/announcements") },
  { label: "Categories", href: "/admin/categories", match: (p) => p.startsWith("/admin/categories") },
  { label: "Resources", href: "/admin/resources", match: (p) => p.startsWith("/admin/resources") },
  { label: "Drills", href: "/admin/drills", match: (p) => p.startsWith("/admin/drills") },
  { label: "Achievements", href: "/admin/achievements", match: (p) => p.startsWith("/admin/achievements") },
];

export default function AdminNav() {
  const pathname = usePathname() ?? "";

  return (
    <nav className="flex items-center gap-1 flex-wrap">
      {ITEMS.map((item) => {
        const active = item.match(pathname);
        return (
          <Link
            key={item.href}
            href={item.href}
            aria-current={active ? "page" : undefined}
            className={`text-sm px-3 py-1.5 rounded-lg transition-colors ${
              active
                ? "bg-crimson-800 text-gold-300"
                : "text-parchment-dim hover:text-parchment hover:bg-crimson-800/50"
            }`}
          >
            {item.label}
          </Link>
        );
      })}
    </nav>
  );
}
