import Link from "next/link";
import { db } from "@/lib/db";
import { BADGE_CATALOG } from "@/lib/gamification/mock";
import { generateHandle } from "@/lib/gamification/engine";
import GrantPanel from "./GrantPanel";

export const dynamic = "force-dynamic";

export default async function AdminAchievementsPage() {
  const users = await db.user.findMany({
    select: {
      id: true,
      name: true,
      email: true,
      handle: true,
      achievements: { select: { key: true, grantedBy: true } },
    },
    orderBy: { createdAt: "asc" },
  });

  const usersView = users.map((u) => ({
    id: u.id,
    handle: u.handle ?? generateHandle(u.id),
    name: u.name,
    email: u.email,
    granted: u.achievements.filter((a) => a.grantedBy).map((a) => a.key),
  }));

  const catalog = BADGE_CATALOG.map((b) => ({ key: b.key, name: b.name, tier: b.tier, category: b.category }));

  return (
    <main className="flex-1">
      <div className="max-w-3xl mx-auto px-6 py-10 space-y-6">
        <div>
          <Link href="/admin" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← Admin
          </Link>
          <h1 className="font-display text-2xl text-parchment mt-2 mb-1">Grant Achievements</h1>
          <p className="text-parchment-dim text-sm">
            Hand-award special badges (contest wins, events, recognition). Auto-earned badges aren't shown
            here — only instructor grants, which you can revoke.
          </p>
        </div>
        <GrantPanel users={usersView} catalog={catalog} />
      </div>
    </main>
  );
}
