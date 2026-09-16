"use client";

import { setVideoProblemSets } from "@/lib/assignments";

// Per-lecture control: which of this course's problem sets cover this lecture.
// The lecture-side mirror of the problem-set editor's "Covers lectures" — same
// ProblemSetVideo join, editable from either end.
export default function ProblemSetLinkEditor({
  videoId,
  problemSets,
  linked,
}: {
  videoId: string;
  problemSets: { id: string; title: string; isDraft: boolean }[];
  linked: string[];
}) {
  const linkedSet = new Set(linked);
  return (
    <form action={setVideoProblemSets} className="space-y-2">
      <input type="hidden" name="videoId" value={videoId} />
      <p className="font-display text-xs tracking-[0.15em] uppercase text-gold-400">Problem sets covering this lecture</p>
      <div className="flex flex-wrap gap-x-4 gap-y-1">
        {problemSets.map((ps) => (
          <label key={ps.id} className="flex items-center gap-2 text-sm text-parchment-dim">
            <input type="checkbox" name="problemSetId" value={ps.id} defaultChecked={linkedSet.has(ps.id)} />
            <span>
              {ps.title}
              {ps.isDraft && <span className="ml-1.5 text-[10px] uppercase tracking-wider text-amber-300">draft</span>}
            </span>
          </label>
        ))}
      </div>
      <button
        type="submit"
        className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
      >
        Save sets
      </button>
    </form>
  );
}
