import Link from "next/link";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { SCORING, TIERS, rankMedal } from "@/lib/gamification/mock";
import { getLeaderboard, type ScholarEntry } from "@/lib/gamification/engine";
import StandingCard from "./StandingCard";

export const dynamic = "force-dynamic";

const fmt = (n: number) => n.toLocaleString("en-US");

export default async function LeaderboardPage() {
  const session = await getServerSession(authOptions);
  const myId = session?.user?.id;

  const entries = await getLeaderboard();
  const total = entries.length;
  const meIndex = myId ? entries.findIndex((e) => e.scholar.userId === myId) : -1;
  const me = meIndex >= 0 ? entries[meIndex] : null;

  return (
    <main className="flex-1">
      <header className="border-b border-crimson-700 px-6 py-4">
        <div className="max-w-4xl mx-auto">
          <Link href="/" className="text-sm text-parchment-dim hover:text-parchment transition-colors">
            ← All Courses
          </Link>
        </div>
      </header>

      <div className="max-w-4xl mx-auto px-6 py-10 space-y-12">
        <div>
          <h1 className="font-display text-2xl text-parchment mb-1">Hall of Scholars</h1>
          <p className="text-parchment-dim text-sm">
            Every scholar is ranked by their <span className="text-parchment">standing</span> — shown only by
            their chosen handle.
          </p>
        </div>

        {/* 1. Your Standing */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Your Standing
          </h2>
          {me ? (
            <div className="space-y-2">
              <StandingCard scholar={me.scholar} rank={meIndex + 1} totalScholars={total} />
              <div className="text-right">
                <Link href="/dashboard" className="text-xs text-parchment-dim hover:text-gold-300 transition-colors">
                  Change your handle →
                </Link>
              </div>
            </div>
          ) : myId ? (
            <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 text-sm text-parchment-dim">
              You're not on the board yet. Watch a lecture or take a quiz and you'll claim your place in the Hall.
            </div>
          ) : (
            <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 flex items-center justify-between gap-4">
              <p className="text-sm text-parchment-dim">Sign in to earn a place in the Hall of Scholars.</p>
              <Link
                href="/auth/signin"
                className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
              >
                Sign In
              </Link>
            </div>
          )}
        </section>

        {/* 2. The board */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            The Hall
          </h2>
          <ul className="space-y-2">
            {entries.map((e, i) => (
              <li key={e.scholar.userId ?? e.scholar.handle}>
                <ScholarRow entry={e} rank={i + 1} isMe={!!myId && e.scholar.userId === myId} />
              </li>
            ))}
          </ul>
        </section>

        {/* 3. Explainer */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            How Standing Is Earned
          </h2>
          <div className="bg-crimson-900 border border-crimson-700 rounded-xl p-5 space-y-3">
            <ul className="space-y-2 text-sm text-parchment-dim">
              <ScoreRule points={`+${SCORING.lecture}`} label="for every lecture you watch" />
              <ScoreRule
                points={`+${SCORING.quizPerCorrect}`}
                label="per correct answer on a quiz — your best attempt counts, so retrying to learn only helps"
              />
              <ScoreRule points={`+${SCORING.testPerCorrect}`} label="per correct answer on a playlist test (best attempt)" />
              <ScoreRule points={`+${fmt(SCORING.completion)}`} label="for finishing a course (all lectures watched, every quiz passed, and the test passed)" />
              <ScoreRule points={`+${TIERS.bronze.points}–${TIERS.platinum.points}`} label="for each achievement you unlock, by tier (Bronze → Platinum)" />
            </ul>
            <p className="text-xs text-parchment-dim pt-2 border-t border-crimson-800">
              Because quizzes count your <span className="text-parchment">best</span> attempt, there's no reason
              to look up answers — you're rewarded for mastering the material, not for guessing fast. And the
              legendary <span className="text-gold-300">Omniscient</span> badge is worth{" "}
              {TIERS.omniscient.points.toLocaleString()} — but you'd have to do absolutely everything,
              perfectly, to claim it.
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}

function ScholarRow({ entry, rank, isMe }: { entry: ScholarEntry; rank: number; isMe: boolean }) {
  const { color, medal } = rankMedal(rank);
  const { scholar } = entry;
  return (
    <Link
      href={`/leaderboard/${scholar.handle.toLowerCase()}`}
      className={`group rounded-xl p-4 flex items-center gap-4 border transition-colors ${
        isMe
          ? "bg-crimson-800 border-gold-500"
          : "bg-crimson-900 border-crimson-700 hover:border-gold-500"
      }`}
    >
      <span className={`font-display text-lg w-10 shrink-0 text-center ${color}`}>{medal || rank}</span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-parchment group-hover:text-gold-300 transition-colors truncate">
          {scholar.handle}
          {isMe && <span className="text-gold-400 text-xs ml-2">you</span>}
        </p>
      </div>
      <p className="text-lg font-bold text-gold-300 shrink-0 tabular-nums">{fmt(scholar.standing)}</p>
      <span className="text-parchment-dim group-hover:text-gold-300 transition-colors shrink-0">→</span>
    </Link>
  );
}

function ScoreRule({ points, label }: { points: string; label: string }) {
  return (
    <li className="flex gap-3">
      <span className="font-bold text-gold-300 tabular-nums shrink-0 w-20 text-right whitespace-nowrap">{points}</span>
      <span>{label}</span>
    </li>
  );
}
