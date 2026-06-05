import Link from "next/link";
import {
  SCORING,
  TIERS,
  MOCK_SCHOLARS,
  MOCK_ME,
  MOCK_BADGES,
  rankMedal,
  type Scholar,
} from "@/lib/gamification/mock";
import AchievementsGrid from "./AchievementsGrid";
import StandingCard from "./StandingCard";

export const dynamic = "force-dynamic";

const fmt = (n: number) => n.toLocaleString("en-US");

export default function LeaderboardPage() {
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
          <StandingCard scholar={MOCK_ME} rank={MOCK_ME.rank} totalScholars={MOCK_SCHOLARS.length} />
        </section>

        {/* 2. The board */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            The Hall
          </h2>
          <ul className="space-y-2">
            {MOCK_SCHOLARS.map((s, i) => (
              <li key={s.handle}>
                <ScholarRow scholar={s} rank={i + 1} isMe={s.handle === MOCK_ME.handle} />
              </li>
            ))}
          </ul>
        </section>

        {/* 3. Achievements */}
        <section className="space-y-4">
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700">
            Achievements
          </h2>
          <AchievementsGrid badges={MOCK_BADGES} />
        </section>

        {/* 4. Explainer */}
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
              <ScoreRule points={`+${fmt(SCORING.completion)}`} label="for finishing a course (all lectures watched + test passed)" />
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

function ScholarRow({ scholar, rank, isMe }: { scholar: Scholar; rank: number; isMe: boolean }) {
  const { color, medal } = rankMedal(rank);
  return (
    <Link
      href={`/leaderboard/${scholar.handle.toLowerCase()}`}
      className={`group rounded-xl p-4 flex items-center gap-4 border transition-colors ${
        isMe
          ? "bg-crimson-800 border-gold-500"
          : "bg-crimson-900 border-crimson-700 hover:border-gold-500"
      }`}
    >
      <span className={`font-display text-lg w-10 shrink-0 text-center ${color}`}>
        {medal || rank}
      </span>
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
      <span className="font-bold text-gold-300 tabular-nums shrink-0 w-14 text-right">{points}</span>
      <span>{label}</span>
    </li>
  );
}
