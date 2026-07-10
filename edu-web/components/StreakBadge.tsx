import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getStreak } from "@/lib/gamification/engine";

// Small 🔥 indicator in the site header. Server component — shows only for a
// signed-in student with a live streak; otherwise renders nothing.
export default async function StreakBadge() {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return null;
  const { count } = await getStreak(session.user.id);
  if (count <= 0) return null;
  return (
    <Link
      href="/review"
      title={`${count}-day study streak — keep it going`}
      className="shrink-0 flex items-center gap-1 text-sm text-gold-300 hover:text-gold-200 transition-colors"
    >
      <span aria-hidden>🔥</span>
      <span className="font-medium">{count}</span>
    </Link>
  );
}
