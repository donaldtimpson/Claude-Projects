import Link from "next/link";
import { notFound } from "next/navigation";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { getScholarByHandle } from "@/lib/gamification/engine";
import StandingCard from "../StandingCard";
import AchievementsGrid from "../AchievementsGrid";

export const dynamic = "force-dynamic";

export default async function ScholarPage({ params }: { params: Promise<{ handle: string }> }) {
  const { handle } = await params;
  const entry = await getScholarByHandle(decodeURIComponent(handle));
  if (!entry) notFound();

  const session = await getServerSession(authOptions);
  const isMe = !!session?.user?.id && entry.scholar.userId === session.user.id;
  const { scholar, badges, house, note, rank, total } = entry;

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/leaderboard" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← The Hall
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10 space-y-12">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">
            {scholar.handle}
            {isMe && <span className="text-gold-400 text-sm ml-3 align-middle">you</span>}
          </h1>
          <p className="text-parchment-dim text-sm">Rank #{rank} in the Hall of Scholars</p>
        </div>

        {house && (
          <div className="bg-crimson-800/40 border border-gold-500/40 rounded-xl p-4">
            <p className="font-display text-[10px] uppercase tracking-[0.2em] text-gold-300 mb-1">
              ✦ House Scholar — not a real student
            </p>
            <p className="text-sm text-parchment-dim">
              {note ??
                "A legendary figure placed in the Hall to give new scholars someone to chase. Climb past them and the rank is yours."}
            </p>
          </div>
        )}

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Standing
          </h2>
          <StandingCard scholar={scholar} rank={rank} totalScholars={total} highlight={isMe || house} />
        </section>

        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Achievements
          </h2>
          <AchievementsGrid badges={badges} />
        </section>
      </div>
    </main>
  );
}
