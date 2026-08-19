"use client";

import { useEffect, useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useToast, type ToastBadge } from "@/components/Toast";
import Tex from "@/components/drills/Tex";
import DrillDiagram from "@/components/drills/DrillDiagram";
import GeoMap from "@/components/drills/GeoMap";
import type { DrillDef, DrillMode, DrillSummary, Level, Problem, Renderable } from "@/lib/drills/types";

// How long the feedback toast lingers. The next problem appears immediately on
// answer (the toast is just an overlay), so these only control toast visibility —
// short for correct, longer for wrong so the correct answer can register.
const CORRECT_MS = 700;
const WRONG_MS = 2400;

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

type Feedback = { correct: boolean; answer: Renderable | null; seq: number };

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
  // def.generate() is NOT pure — bank and map drills draw from a shuffle bag, so each
  // call consumes an item. A lazy useState initializer is the wrong home for it: React
  // deliberately double-invokes those under StrictMode, which burned an extra item and
  // made a full-pool "All" run come up one short (and repeat). Draw the first problem
  // once per mount behind a ref guard instead.
  const firstRef = useRef<Problem | null>(null);
  if (firstRef.current === null) firstRef.current = def.generate(level);
  const [current, setCurrent] = useState<Problem>(firstRef.current);
  const [texts, setTexts] = useState<string[]>(() => blankTexts(firstRef.current!));
  const [results, setResults] = useState<boolean[]>([]);
  const [streak, setStreak] = useState(0);
  const [bestStreak, setBestStreak] = useState(0);
  const [score, setScore] = useState(0); // arcade points (timed mode) — matches the iOS Rapid Fire
  const [done, setDone] = useState(false);
  const [remaining, setRemaining] = useState(mode.type === "timed" ? mode.seconds : 0);
  const [feedback, setFeedback] = useState<Feedback | null>(null);

  const startedAt = useRef(Date.now());
  const savedRef = useRef(false);
  const firstInputRef = useRef<HTMLInputElement>(null);
  const seqRef = useRef(0); // bumps per answer so the toast remounts + re-animates
  const lockRef = useRef(false); // guards against a double-submit before the next problem renders
  const toast = useToast();
  const router = useRouter();

  const total = results.length;
  const correctCount = results.filter(Boolean).length;

  // Each new problem: release the submit lock and focus the answer box (typed
  // drills never need a click between problems).
  useEffect(() => {
    lockRef.current = false;
    firstInputRef.current?.focus();
  }, [current.id]);

  // Dismiss the feedback toast after a correctness-dependent delay. Keyed on the
  // feedback object so each answer restarts the timer.
  useEffect(() => {
    if (!feedback) return;
    const t = setTimeout(() => setFeedback(null), feedback.correct ? CORRECT_MS : WRONG_MS);
    return () => clearTimeout(t);
  }, [feedback]);

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
      ...(mode.type === "timed" ? { score } : {}),
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

  function loadNext() {
    const p = def.generate(level);
    setCurrent(p);
    setTexts(blankTexts(p));
  }

  // Grade an answer, show feedback, and immediately move on (or finish). The next
  // problem renders right away; the toast lingers as an overlay.
  function commit(correct: boolean, answer: Renderable | null) {
    if (lockRef.current) return;
    lockRef.current = true;
    const newResults = [...results, correct];
    setResults(newResults);
    const ns = correct ? streak + 1 : 0;
    setStreak(ns);
    setBestStreak((b) => Math.max(b, ns));
    // Arcade score (timed mode only): 10 + combo bonus, mirroring the iOS Rapid Fire.
    if (mode.type === "timed" && correct) setScore((sc) => sc + 10 + (ns - 1) * 2);
    setFeedback({ correct, answer: correct ? null : answer, seq: ++seqRef.current });
    if (mode.type === "count" && newResults.length >= mode.n) {
      setDone(true);
    } else {
      loadNext();
    }
  }

  function choose(idx: number) {
    if (current.input.kind !== "choice") return;
    commit(idx === current.input.correctIndex, current.explanation ?? null);
  }

  // Tap-to-locate: grade the click and advance immediately, same as choice — the
  // correctness toast lingers as an overlay while the next question's map flies in.
  function pickRegion(id: string) {
    if (current.input.kind !== "mapTap") return;
    commit(id === current.input.targetId, current.explanation ?? null);
  }

  function submitTyped(e: React.FormEvent) {
    e.preventDefault();
    const input = current.input;
    if (input.kind === "numeric") {
      commit(gradeNumeric(texts[0] ?? "", input.answer, input.tolerance), current.explanation ?? null);
    } else if (input.kind === "fields") {
      const allOk = input.fields.every((f, i) => gradeNumeric(texts[i] ?? "", f.answer, f.tolerance));
      commit(allOk, current.explanation ?? null);
    }
  }

  function restart() {
    savedRef.current = false;
    lockRef.current = false;
    setResults([]);
    setStreak(0);
    setBestStreak(0);
    setScore(0);
    setFeedback(null);
    setRemaining(mode.type === "timed" ? mode.seconds : 0);
    startedAt.current = Date.now();
    loadNext();
    // done goes true→false here; the fire-once effect guards on `!done` so it
    // won't re-fire, and savedRef (reset above) lets the NEXT completion fire.
    setDone(false);
  }

  // Feedback toast: a small fixed pill — ✓ on correct, ✗ with the correct answer
  // (the per-problem explanation) on wrong. Fixed-position + keyed on seq so it
  // never shifts layout and re-animates on each answer. Shown over the live
  // problem AND the results screen (for the final answer).
  const toastEl = feedback ? (
    <div className="fixed bottom-6 left-1/2 -translate-x-1/2 z-50 px-4 pointer-events-none">
      <div
        key={feedback.seq}
        className={`flex items-center gap-2 rounded-full border px-4 py-2 text-sm font-medium shadow-lg animate-[fadeIn_0.2s_ease-out] ${
          feedback.correct
            ? "border-green-500 bg-green-900/90 text-green-200"
            : "border-red-500 bg-red-900/90 text-red-100"
        }`}
      >
        <span aria-hidden>{feedback.correct ? "✓" : "✗"}</span>
        {feedback.correct ? (
          <span>Correct</span>
        ) : feedback.answer ? (
          <Tex value={feedback.answer} />
        ) : (
          <span>Incorrect</span>
        )}
      </div>
    </div>
  ) : null;

  // ---- Results screen -------------------------------------------------------
  if (done) {
    const pct = total > 0 ? Math.round((correctCount / total) * 100) : 0;
    const durationSec =
      mode.type === "timed" ? mode.seconds : Math.round((Date.now() - startedAt.current) / 1000);
    const perMin = durationSec > 0 ? Math.round((total / durationSec) * 600) / 10 : 0;
    return (
      <>
        <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-4">
          <h2 className="text-lg font-bold text-parchment">Session complete</h2>
          {mode.type === "timed" && (
            <p className="text-5xl font-bold text-gold-300">
              {score}
              <span className="text-lg text-parchment-dim ml-2 font-normal">points</span>
            </p>
          )}
          <p className={mode.type === "timed" ? "text-2xl font-bold text-gold-400" : "text-4xl font-bold text-gold-400"}>
            {correctCount}/{total}
            <span className="text-lg text-parchment-dim ml-2">({pct}%)</span>
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
        {toastEl}
      </>
    );
  }

  // ---- Active problem -------------------------------------------------------
  const input = current.input;

  const answerEl =
    input.kind === "choice" ? (
      <ol className="grid grid-cols-2 gap-2">
        {input.options.map((opt, idx) => {
          const img = input.kind === "choice" ? input.optionImages?.[idx] : null;
          return (
            <li key={idx}>
              <button
                className={`w-full px-4 py-3 rounded-lg border text-base transition-colors border-crimson-700 bg-crimson-800 hover:border-gold-400 text-parchment ${
                  img ? "flex flex-col items-center gap-2" : ""
                }`}
                onClick={() => choose(idx)}
              >
                {img && (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img src={img} alt="" className="h-8 w-auto rounded-sm ring-1 ring-crimson-700" />
                )}
                <Tex value={opt} />
              </button>
            </li>
          );
        })}
      </ol>
    ) : input.kind === "mapTap" ? null : (
      <form onSubmit={submitTyped} className="flex flex-wrap items-end gap-4">
        {(input.kind === "numeric"
          ? [{ label: undefined as Renderable | undefined, unit: input.unit }]
          : input.fields.map((f) => ({ label: f.label as Renderable | undefined, unit: f.unit }))
        ).map((f, i) => (
          // key includes the problem id so the input REMOUNTS on each new problem —
          // that re-fires autoFocus, which otherwise only runs on the very first mount.
          <label key={`${current.id}-${i}`} className="flex items-center gap-2">
            {f.label && (
              <span className="text-parchment">
                <Tex value={f.label} /> =
              </span>
            )}
            <input
              ref={i === 0 ? firstInputRef : undefined}
              type="text"
              inputMode="decimal"
              autoFocus={i === 0}
              value={texts[i] ?? ""}
              onChange={(e) =>
                setTexts((t) => {
                  const n = [...t];
                  n[i] = e.target.value;
                  return n;
                })
              }
              className="w-28 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment placeholder:text-parchment-dim/60 transition-colors"
              placeholder="?"
            />
            {f.unit && <span className="text-parchment-dim text-sm">{f.unit}</span>}
          </label>
        ))}
        <button
          type="submit"
          className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
        >
          Submit
        </button>
      </form>
    );

  return (
    <>
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-5">
        <div className="flex items-center justify-between gap-3 text-sm">
          <h2 className="text-lg font-bold text-parchment">{def.title}</h2>
          <div className="flex items-center gap-4 text-parchment-dim">
            <span>
              <span className="text-parchment">{correctCount}</span>/{total}
            </span>
            <span title="current streak">🔥 {streak}</span>
            {mode.type === "timed" && <span title="score" className="text-gold-300">★ {score}</span>}
            {mode.type === "timed" ? (
              <span className={remaining <= 10 ? "text-red-400" : "text-gold-300"}>⏱ {remaining}s</span>
            ) : (
              <span>{Math.max(0, mode.n - total)} left</span>
            )}
          </div>
        </div>

        {input.kind === "mapTap" ? (
          // Tap-to-locate: the map is the input. Big and prominent — click the named region.
          <div className="space-y-4">
            <div className="text-2xl text-parchment text-center whitespace-pre-line">
              <Tex value={current.prompt} />
            </div>
            <GeoMap
              map={input.map}
              interactive
              targetId={input.targetId}
              onPick={pickRegion}
              className="w-full max-w-3xl mx-auto"
            />
          </div>
        ) : current.diagram?.kind === "geoMap" ? (
          // Identify: highlighted map on top, flag options below.
          <div className="space-y-4">
            <div className="text-xl text-parchment text-center whitespace-pre-line">
              <Tex value={current.prompt} />
            </div>
            <GeoMap
              map={current.diagram.map}
              highlightId={current.diagram.highlightId}
              className="w-full max-w-3xl mx-auto"
            />
            <div className="max-w-xl mx-auto">{answerEl}</div>
          </div>
        ) : current.diagram ? (
          // Diagram drills (unit circle, vectors): prompt + answers on the left, the
          // diagram on the right — keeps the whole problem in one screenful.
          <div className="flex flex-col sm:flex-row sm:items-start gap-5">
            <div className="flex-1 min-w-0 space-y-5">
              <div className="text-2xl text-parchment whitespace-pre-line">
                <Tex value={current.prompt} />
              </div>
              {answerEl}
            </div>
            <div className="shrink-0 mx-auto sm:mx-0">
              <DrillDiagram spec={current.diagram} className="w-40 h-40 sm:w-44 sm:h-44" />
            </div>
          </div>
        ) : (
          <>
            <div className="text-xl text-parchment text-center py-2 whitespace-pre-line">
              <Tex value={current.prompt} block />
            </div>
            {answerEl}
          </>
        )}
      </section>
      {toastEl}
    </>
  );
}
