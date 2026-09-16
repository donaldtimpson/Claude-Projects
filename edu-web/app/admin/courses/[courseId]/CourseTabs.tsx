"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

// Tabs across the course hub. Everything course-scoped (lectures, test,
// connections, problem sets) lives under /admin/courses/[courseId]/*.
export default function CourseTabs({ courseId }: { courseId: string }) {
  const pathname = usePathname() ?? "";
  const base = `/admin/courses/${courseId}`;

  const tabs: { label: string; href: string; active: boolean }[] = [
    { label: "Lectures", href: base, active: pathname === base },
    { label: "Test", href: `${base}/test`, active: pathname.startsWith(`${base}/test`) },
    {
      label: "Connections",
      href: `${base}/connections`,
      active: pathname.startsWith(`${base}/connections`),
    },
    {
      label: "Problem Sets",
      href: `${base}/problem-sets`,
      active: pathname.startsWith(`${base}/problem-sets`),
    },
  ];

  return (
    <nav className="flex items-center gap-1 flex-wrap border-b border-crimson-700 pb-3">
      {tabs.map((t) => (
        <Link
          key={t.href}
          href={t.href}
          aria-current={t.active ? "page" : undefined}
          className={`text-sm px-3 py-1.5 rounded-lg transition-colors ${
            t.active
              ? "bg-crimson-800 text-gold-300"
              : "text-parchment-dim hover:text-parchment hover:bg-crimson-800/50"
          }`}
        >
          {t.label}
        </Link>
      ))}
    </nav>
  );
}
