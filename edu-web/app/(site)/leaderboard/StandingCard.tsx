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
  // A small categorical palette: four distinct hues at similar lightness, each
  // legible on both themes and none mistakable for the empty track.
  const segments = [
    { label: "Lectures", value: scholar.lectures, className: "bg-[#b4443a]" },
    { label: "Quizzes", value: scholar.quizPts, className: "bg-[#c9962a]" },
    { label: "Completion", value: scholar.completions, className: "bg-[#5fa872]" },
    { label: "Badges", value: scholar.badgePts, className: "bg-[#7a6f9b]" },
  ];

  return (
    <div className={`bg-crimson-900 border rounded-xl p-5 ${highlight ? "border-gold-500" : "border-crimson-700"}`}>
      <div className="flex items-center justify-between mb-4">
        <div>
          <p className="text-lg font-semibold text-gold-300">{scholar.handle}</p>
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
      <div className="h-2.5 bg-crimson-800 rounded-full overflow-hidden flex gap-px">
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
            <span className={`inline-block h-2.5 w-2.5 rounded-sm ${seg.className}`} />
            {seg.label} <span className="font-semibold tabular-nums text-parchment">{fmt(seg.value)}</span>
          </span>
        ))}
      </div>
    </div>
  );
}
