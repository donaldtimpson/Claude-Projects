"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useToast, type ToastBadge } from "@/components/Toast";
import Tex from "@/components/drills/Tex";
import DrillDiagram from "@/components/drills/DrillDiagram";
import type { DrillDef, DrillMode, DrillSummary, Level, Problem, Renderable } from "@/lib/drills/types";

function blankTexts(p: Problem): string[] {
  if (p.input.kind === "numeric") return [""];
  if (p.input.kind === "fields") return p.input.fields.map(() => "");
  return [];
}

function gradeNumeric(raw: string, answer: number, tolerance?: number): boolean {
  const v = parseFloat(raw.trim().replace(",", "."));
  if (Number.isNaN(v)) return false;
  return Math.abs(v - answer) <= (tolerance ?? 0) + 1e-9;
}

export default function DrillPlayer({
  def,
  level,
  mode,
  onSessionComplete,
  onExit,
}: {
  def: DrillDef;
  level: Level;
  mode: DrillMode;
  onSessionComplete?: (s: DrillSummary) => Promise<ToastBadge[]> | void;
  onExit?: () => void;
}) {
  const [current, setCurrent] = useState<Problem>(() => def.generate(level));
  const [texts, setTexts] = useState<string[]>(() => blankTexts(current));
  const [selected, setSelected] = useState<number | null>(null);
  const [answered, setAnswered] = useState(false);
  const [wasCorrect, setWasCorrect] = useState(false);
  const [results, setResults] = useState<boolean[]>([]);
  const [streak, setStreak] = useState(0);
  const [bestStreak, setBestStreak] = useState(0);
  const [done, setDone] = useState(false);
  const [remaining, setRemaining] = useState(mode.type === "timed" ? mode.seconds : 0);

  const startedAt = useRef(Date.now());
  const savedRef = useRef(false);
  const toast = useToast();
  const router = useRouter();

  const total = results.length;
  const correctCount = results.filter(Boolean).length;
  const isLastOfCount = mode.type === "count" && total >= mode.n;

  // Countdown for timed mode.
  useEffect(() => {
    if (mode.type !== "timed" || done) return;
    if (remaining <= 0) {
      setDone(true);
      return;
    }
    const t = setTimeout(() => setRemaining((s) => s - 1), 1000);
    return () => clearTimeout(t);
  }, [remaining, done, mode]);

  // Fire the completion callback exactly once.
  useEffect(() => {
    if (!done || savedRef.current) return;
    savedRef.current = true;
    const summary: DrillSummary = {
      slug: def.slug,
      level,
      total: results.length,
      correct: results.filter(Boolean).length,
      bestStreak,
      mode: mode.type,
      durationSec:
        mode.type === "timed" ? mode.seconds : Math.round((Date.now() - startedAt.current) / 1000),
    };
    if (onSessionComplete) {
      Promise.resolve(onSessionComplete(summary)).then((earned) => {
        if (earned && earned.length && toast) toast.celebrate(earned);
        router.refresh();
      });
    } else {
      router.refresh();
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [done]);

  function commit(correct: boolean) {
    if (answered) return;
    setAnswered(true);
    setWasCorrect(correct);
    setResults((r) => [...r, correct]);
    setStreak((s) => {
      const ns = correct ? s + 1 : 0;
      setBestStreak((b) => Math.max(b, ns));
      return ns;
    });
  }

  function choose(idx: number) {
    if (answered || current.input.kind !== "choice") return;
    setSelected(idx);
    commit(idx === current.input.correctIndex);
  }

  function submitTyped(e: React.FormEvent) {
    e.preventDefault();
    if (answered) return;
    const input = current.input;
    if (input.kind === "numeric") {
      commit(gradeNumeric(texts[0] ?? "", input.answer, input.tolerance));
    } else if (input.kind === "fields") {
      const allOk = input.fields.every((f, i) => gradeNumeric(texts[i] ?? "", f.answer, f.tolerance));
      commit(allOk);
    }
  }

  function next() {
    if (isLastOfCount) {
      setDone(true);
      return;
    }
    const p = def.generate(level);
    setCurrent(p);
    setTexts(blankTexts(p));
    setSelected(null);
    setAnswered(false);
    setWasCorrect(false);
  }

  function restart() {
    savedRef.current = false;
    const p = def.generate(level);
    setCurrent(p);
    setTexts(blankTexts(p));
    setSelected(null);
    setAnswered(false);
    setWasCorrect(false);
    setResults([]);
    setStreak(0);
    setBestStreak(0);
    setRemaining(mode.type === "timed" ? mode.seconds : 0);
    startedAt.current = Date.now();
    // done goes true→false here; the fire-once effect guards on `!done` so it
    // won't re-fire, and savedRef (reset above) lets the NEXT completion fire.
    setDone(false);
  }

  // ---- Results screen -------------------------------------------------------
  if (done) {
    const pct = total > 0 ? Math.round((correctCount / total) * 100) : 0;
    const durationSec =
      mode.type === "timed" ? mode.seconds : Math.round((Date.now() - startedAt.current) / 1000);
    const perMin = durationSec > 0 ? Math.round((total / durationSec) * 600) / 10 : 0;
    return (
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-bold text-parchment">Session complete</h2>
        <p className="text-4xl font-bold text-gold-400">
          {correctCount}/{total}
          <span className="text-xl text-parchment-dim ml-2">({pct}%)</span>
        </p>
        <dl className="flex flex-wrap gap-x-8 gap-y-1 text-sm text-parchment-dim">
          <div>
            <dt className="inline">Best streak: </dt>
            <dd className="inline text-parchment">{bestStreak}</dd>
          </div>
          {mode.type === "timed" && (
            <div>
              <dt className="inline">Pace: </dt>
              <dd className="inline text-parchment">{perMin}/min</dd>
            </div>
          )}
        </dl>
        <div className="flex gap-3 pt-1">
          <button
            onClick={restart}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            Practice again
          </button>
          {onExit && (
            <button
              onClick={onExit}
              className="px-4 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
            >
              Change settings
            </button>
          )}
        </div>
      </section>
    );
  }

  // ---- Active problem -------------------------------------------------------
  const input = current.input;
  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-5">
      <div className="flex items-center justify-between gap-3 text-sm">
        <h2 className="text-lg font-bold text-parchment">{def.title}</h2>
        <div className="flex items-center gap-4 text-parchment-dim">
          <span>
            <span className="text-parchment">{correctCount}</span>/{total}
          </span>
          <span title="current streak">🔥 {streak}</span>
          {mode.type === "timed" ? (
            <span className={remaining <= 10 ? "text-red-400" : "text-gold-300"}>⏱ {remaining}s</span>
          ) : (
            <span>{Math.max(0, mode.n - total)} left</span>
          )}
        </div>
      </div>

      <div className="text-xl text-parchment text-center py-2">
        <Tex value={current.prompt} block />
      </div>

      {current.diagram && <DrillDiagram spec={current.diagram} />}

      {input.kind === "choice" ? (
        <ol className="grid grid-cols-2 gap-2">
          {input.options.map((opt, idx) => {
            let style = "w-full px-4 py-3 rounded-lg border text-base transition-colors ";
            if (!answered) {
              style += "border-crimson-700 bg-crimson-800 hover:border-gold-400 text-parchment";
            } else if (idx === input.correctIndex) {
              style += "border-green-500 bg-green-900/30 text-green-300";
            } else if (idx === selected) {
              style += "border-red-500 bg-red-900/30 text-red-300";
            } else {
              style += "border-crimson-700 bg-crimson-800 text-parchment-dim";
            }
            return (
              <li key={idx}>
                <button className={style} onClick={() => choose(idx)} disabled={answered}>
                  <Tex value={opt} />
                </button>
              </li>
            );
          })}
        </ol>
      ) : (
        <form onSubmit={submitTyped} className="flex flex-wrap items-end gap-4">
          {(input.kind === "numeric"
            ? [{ label: undefined as Renderable | undefined, unit: input.unit }]
            : input.fields.map((f) => ({ label: f.label as Renderable | undefined, unit: f.unit }))
          ).map((f, i) => (
            <label key={i} className="flex items-center gap-2">
              {f.label && (
                <span className="text-parchment">
                  <Tex value={f.label} /> =
                </span>
              )}
              <input
                type="text"
                inputMode="decimal"
                autoFocus={i === 0}
                value={texts[i] ?? ""}
                disabled={answered}
                onChange={(e) =>
                  setTexts((t) => {
                    const n = [...t];
                    n[i] = e.target.value;
                    return n;
                  })
                }
                className="w-28 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment placeholder:text-parchment-dim/60 transition-colors disabled:opacity-60"
                placeholder="?"
              />
              {f.unit && <span className="text-parchment-dim text-sm">{f.unit}</span>}
            </label>
          ))}
          {!answered && (
            <button
              type="submit"
              className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
            >
              Submit
            </button>
          )}
        </form>
      )}

      {answered && (
        <div className="space-y-3">
          <p className={`font-semibold ${wasCorrect ? "text-green-400" : "text-red-400"}`}>
            {wasCorrect ? "Correct!" : "Incorrect"}
          </p>
          {current.explanation && (
            <p className="text-sm text-parchment-dim">
              <Tex value={current.explanation} />
            </p>
          )}
          <button
            onClick={next}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            {isLastOfCount ? "See results" : "Next →"}
          </button>
        </div>
      )}
    </section>
  );
}
