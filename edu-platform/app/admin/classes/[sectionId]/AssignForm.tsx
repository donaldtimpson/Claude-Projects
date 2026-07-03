"use client";

import { useState } from "react";
import { createAssignment } from "@/lib/assignments";

// Create-assignment form. Selecting a problem set pre-fills the point total from
// the set (still editable), so totals flow to the gradebook without retyping.
export default function AssignForm({
  sectionId,
  problemSets,
  videos,
}: {
  sectionId: string;
  problemSets: { id: string; title: string; points: number }[];
  videos: { id: string; title: string }[];
}) {
  const [problemSetId, setProblemSetId] = useState("");
  const [points, setPoints] = useState(0);

  function onSelect(id: string) {
    setProblemSetId(id);
    const ps = problemSets.find((p) => p.id === id);
    setPoints(ps ? ps.points : 0);
  }

  const inputCls =
    "bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm transition-colors";

  return (
    <form action={createAssignment} className="bg-crimson-900 border border-crimson-700 rounded-xl p-4 space-y-3">
      <input type="hidden" name="sectionId" value={sectionId} />
      <div className="flex flex-col sm:flex-row gap-2">
        <select
          name="problemSetId"
          required
          value={problemSetId}
          onChange={(e) => onSelect(e.target.value)}
          className={`flex-[2] ${inputCls}`}
        >
          <option value="" disabled>
            Problem set…
          </option>
          {problemSets.map((ps) => (
            <option key={ps.id} value={ps.id}>
              {ps.title} ({ps.points} pts)
            </option>
          ))}
        </select>
        <select name="videoId" defaultValue="" className={`flex-1 ${inputCls}`}>
          <option value="">(optional) relates to lecture…</option>
          {videos.map((v) => (
            <option key={v.id} value={v.id}>
              {v.title}
            </option>
          ))}
        </select>
      </div>
      <div className="flex flex-col sm:flex-row gap-2 sm:items-center">
        <label className="text-sm text-parchment-dim flex items-center gap-2">
          Points
          <input
            name="points"
            type="number"
            min={0}
            value={points}
            onChange={(e) => setPoints(parseInt(e.target.value, 10) || 0)}
            className={`w-20 ${inputCls}`}
          />
        </label>
        <label className="text-sm text-parchment-dim flex items-center gap-2">
          Due
          <input name="dueAt" type="datetime-local" className={inputCls} />
        </label>
        <button
          type="submit"
          className="sm:ml-auto font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
        >
          Assign
        </button>
      </div>
    </form>
  );
}
