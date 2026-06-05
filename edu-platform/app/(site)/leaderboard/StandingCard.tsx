import { type Scholar } from "@/lib/gamification/mock";

const fmt = (n: number) => n.toLocaleString("en-US");

// Standing summary + stacked score breakdown. Shared by the leaderboard's
// "Your Standing" card and each scholar's detail page.
export default function StandingCard({
  scholar,
  rank,
  totalScholars,
  highlight = true,
}: {
  scholar: Scholar;
  rank: number;
  totalScholars: number;
  highlight?: boolean;
}) {
  const total = scholar.standing || 1;
  const segments = [
    { label: "Lectures", value: scholar.lectures, className: "bg-gold-500" },
    { label: "Quizzes", value: scholar.quizPts, className: "bg-gold-400" },
    { label: "Completion", value: scholar.completions, className: "bg-green-500" },
    { label: "Badges", value: scholar.badgePts, className: "bg-crimson-600" },
  ];

  return (
    <div className={`bg-crimson-900 border rounded-xl p-5 ${highlight ? "border-gold-500" : "border-crimson-700"}`}>
      <div className="flex items-center justify-between mb-4">
        <div>
          <p className="font-display text-lg text-gold-300">{scholar.handle}</p>
          <p className="text-xs text-parchment-dim mt-0.5">
            Rank #{rank} of {totalScholars}
          </p>
        </div>
        <div className="text-right">
          <p className="text-2xl font-bold text-parchment">{fmt(scholar.standing)}</p>
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
