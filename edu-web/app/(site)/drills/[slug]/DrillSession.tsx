"use client";

import { useState } from "react";
import { drillBySlug } from "@/lib/drills/registry";
import DrillPlayer from "@/components/drills/DrillPlayer";
import { recordDrillSession } from "@/lib/actions";
import type { DrillMode, Level } from "@/lib/drills/types";

const COUNT_OPTIONS = [10, 20, 50];
const TIMED_OPTIONS = [60, 120];

// `persist` (default true) records the session for badges/streak via the server
// action. The admin tester passes persist={false} to play without writing to the
// DB or needing a student session.
export default function DrillSession({ slug, persist = true }: { slug: string; persist?: boolean }) {
  const def = drillBySlug(slug);
  // Grammar lessons run as homework: a flawless random-30 run earns the ✦ (and
  // full credit if the lesson is assigned). No difficulty tiers, no timed sprint.
  const isLesson = def?.subject === "Grammar Lessons";
  const [level, setLevel] = useState<Level>(1);
  const [mode, setMode] = useState<DrillMode>({ type: "count", n: isLesson ? 30 : 10 });
  const [playing, setPlaying] = useState(false);
  // Bump to force a fresh DrillPlayer mount on each "start".
  const [sessionKey, setSessionKey] = useState(0);

  if (!def) return null;

  if (playing) {
    return (
      <DrillPlayer
        key={sessionKey}
        def={def}
        level={level}
        mode={mode}
        onSessionComplete={persist ? recordDrillSession : undefined}
        onExit={() => setPlaying(false)}
      />
    );
  }

  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-6">
      {isLesson ? (
        <div className="space-y-3">
          <h2 className="font-display text-sm tracking-[0.15em] uppercase text-gold-400">Session</h2>
          <div className="flex flex-wrap gap-2">
            <Chip active={mode.type === "count" && mode.n === 30} onClick={() => setMode({ type: "count", n: 30 })}>
              Homework · 30 questions
            </Chip>
            <Chip active={mode.type === "count" && mode.n === 10} onClick={() => setMode({ type: "count", n: 10 })}>
              Quick practice · 10
            </Chip>
          </div>
          <p className="text-xs text-parchment-dim">
            Homework is a random 30 from the pool. Get every one right to earn the ✦ — full credit if this
            lesson is assigned in your class.
          </p>
        </div>
      ) : (
        <>
          <div className="space-y-3">
            <h2 className="font-display text-sm tracking-[0.15em] uppercase text-gold-400">Difficulty</h2>
            <div className="flex flex-wrap gap-2">
              {def.levels.map((l) => (
                <Chip key={l.value} active={level === l.value} onClick={() => setLevel(l.value)}>
                  {l.label}
                </Chip>
              ))}
            </div>
          </div>

          <div className="space-y-3">
            <h2 className="font-display text-sm tracking-[0.15em] uppercase text-gold-400">Session</h2>
            <div className="flex flex-wrap gap-2">
              {COUNT_OPTIONS.map((n) => (
                <Chip
                  key={`c${n}`}
                  active={mode.type === "count" && mode.n === n}
                  onClick={() => setMode({ type: "count", n })}
                >
                  {n} problems
                </Chip>
              ))}
              {TIMED_OPTIONS.map((s) => (
                <Chip
                  key={`t${s}`}
                  active={mode.type === "timed" && mode.seconds === s}
                  onClick={() => setMode({ type: "timed", seconds: s })}
                >
                  {s}s sprint
                </Chip>
              ))}
            </div>
          </div>
        </>
      )}

      <button
        onClick={() => {
          setSessionKey((k) => k + 1);
          setPlaying(true);
        }}
        className="px-5 py-2.5 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
      >
        Start drill →
      </button>
    </section>
  );
}

function Chip({
  active,
  onClick,
  children,
}: {
  active: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      onClick={onClick}
      className={`px-3 py-1.5 rounded-lg border text-sm transition-colors ${
        active
          ? "border-gold-500 bg-crimson-800 text-gold-300"
          : "border-crimson-700 bg-crimson-800 text-parchment-dim hover:border-gold-400 hover:text-parchment"
      }`}
    >
      {children}
    </button>
  );
}
