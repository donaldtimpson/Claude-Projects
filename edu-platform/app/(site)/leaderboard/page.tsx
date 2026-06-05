import Link from "next/link";
import {
  SCORING,
  MOCK_SCHOLARS,
  MOCK_ME,
  MOCK_BADGES,
  rankMedal,
  type Scholar,
  type Badge,
} from "@/lib/gamification/mock";

export const dynamic = "force-dynamic";

const fmt = (n: number) => n.toLocaleString("en-US");

export default function LeaderboardPage() {
  const unlocked = MOCK_BADGES.filter((b) => b.unlocked).length;

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
          <YourStanding />
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
          <h2 className="font-display text-sm tracking-[0.2em] uppercase text-gold-400 pb-2 border-b border-crimson-700 flex items-center justify-between">
            <span>Achievements</span>
            <span className="text-parchment-dim normal-case tracking-normal text-xs">
              {unlocked} / {MOCK_BADGES.length} earned
            </span>
          </h2>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
            {MOCK_BADGES.map((b) => (
              <BadgeCard key={b.key} badge={b} />
            ))}
          </div>
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
              <ScoreRule points={`+${SCORING.badgeMinor}–${SCORING.badgeMajor}`} label="for each achievement you unlock" />
            </ul>
            <p className="text-xs text-parchment-dim pt-2 border-t border-crimson-800">
              Because quizzes count your <span className="text-parchment">best</span> attempt, there's no reason
              to look up answers — you're rewarded for mastering the material, not for guessing fast.
            </p>
          </div>
        </section>
      </div>
    </main>
  );
}

function YourStanding() {
  const me = MOCK_ME;
  const total = me.standing || 1;
  const segments = [
    { label: "Lectures", value: me.lectures, className: "bg-gold-500" },
    { label: "Quizzes", value: me.quizPts, className: "bg-gold-400" },
    { label: "Completion", value: me.completions, className: "bg-green-500" },
    { label: "Badges", value: me.badgePts, className: "bg-crimson-600" },
  ];

  return (
    <div className="bg-crimson-900 border border-gold-500 rounded-xl p-5">
      <div className="flex items-center justify-between mb-4">
        <div>
          <p className="font-display text-lg text-gold-300">{me.handle}</p>
          <p className="text-xs text-parchment-dim mt-0.5">Rank #{me.rank} of {MOCK_SCHOLARS.length}</p>
        </div>
        <div className="text-right">
          <p className="text-2xl font-bold text-parchment">{fmt(me.standing)}</p>
          <p className="text-xs text-parchment-dim">standing</p>
        </div>
      </div>

      {/* Stacked breakdown bar */}
      <div className="h-2 bg-crimson-800 rounded-full overflow-hidden flex">
        {segments.map((seg) => (
          <div
            key={seg.label}
            className={`h-full ${seg.className}`}
            style={{ width: `${(seg.value / total) * 100}%` }}
          />
        ))}
      </div>
      <div className="flex flex-wrap gap-x-4 gap-y-1 mt-3">
        {segments.map((seg) => (
          <span key={seg.label} className="flex items-center gap-1.5 text-xs text-parchment-dim">
            <span className={`inline-block h-2 w-2 rounded-sm ${seg.className}`} />
            {seg.label} <span className="text-parchment">{fmt(seg.value)}</span>
          </span>
        ))}
      </div>
    </div>
  );
}

function ScholarRow({ scholar, rank, isMe }: { scholar: Scholar; rank: number; isMe: boolean }) {
  const { color, medal } = rankMedal(rank);
  return (
    <div
      className={`rounded-xl p-4 flex items-center gap-4 border transition-colors ${
        isMe
          ? "bg-crimson-800 border-gold-500"
          : "bg-crimson-900 border-crimson-700 hover:border-gold-500"
      }`}
    >
      <span className={`font-display text-lg w-10 shrink-0 text-center ${color}`}>
        {medal || rank}
      </span>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-medium text-parchment truncate">
          {scholar.handle}
          {isMe && <span className="text-gold-400 text-xs ml-2">you</span>}
        </p>
      </div>
      <p className="text-lg font-bold text-gold-300 shrink-0 tabular-nums">{fmt(scholar.standing)}</p>
    </div>
  );
}

function BadgeCard({ badge }: { badge: Badge }) {
  return (
    <div
      className={`rounded-xl p-4 border text-center ${
        badge.unlocked
          ? "bg-crimson-900 border-gold-500"
          : "bg-crimson-950 border-crimson-800 opacity-60"
      }`}
    >
      <span
        className={`inline-block text-[10px] uppercase tracking-widest rounded px-2 py-0.5 mb-2 font-display ${
          badge.unlocked ? "bg-gold-500 text-crimson-950" : "bg-crimson-800 text-parchment-dim"
        }`}
      >
        {badge.unlocked ? "Earned" : "Locked"}
      </span>
      <p className={`text-sm font-medium ${badge.unlocked ? "text-gold-300" : "text-parchment-dim"}`}>
        {badge.name}
      </p>
      <p className="text-xs text-parchment-dim mt-1 leading-snug">{badge.blurb}</p>
    </div>
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
