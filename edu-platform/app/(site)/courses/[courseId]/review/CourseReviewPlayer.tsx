"use client";

import { useRef, useState } from "react";
import { useRouter } from "next/navigation";
import { useToast, type ToastBadge } from "@/components/Toast";

type ReviewQuestion = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  source: string; // lecture title, or "Course Test"
};

// How many slots ahead a missed question is re-inserted, so it returns soon
// (but not immediately) and must eventually be answered correctly.
const REINSERT = 3;

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

export default function CourseReviewPlayer({
  questions,
  onCleared,
}: {
  questions: ReviewQuestion[];
  // Fires once, the first time every question has been mastered. `perfect` = no
  // question was ever missed. Returns freshly-unlocked badges for the toast.
  onCleared?: (perfect: boolean) => Promise<ToastBadge[]> | void;
}) {
  const total = questions.length;
  const allIndices = () => questions.map((_, i) => i);

  const [phase, setPhase] = useState<"intro" | "playing" | "cleared">("intro");
  const [endless, setEndless] = useState(false);
  const [queue, setQueue] = useState<number[]>([]);
  const [selected, setSelected] = useState<number | null>(null);
  const [mastered, setMastered] = useState<Set<number>>(new Set());
  const [everMissed, setEverMissed] = useState<Set<number>>(new Set());
  const [answersGiven, setAnswersGiven] = useState(0);
  const [stumbles, setStumbles] = useState(0);
  const [streak, setStreak] = useState(0);

  const savedRef = useRef(false);
  const toast = useToast();
  const router = useRouter();

  function start(endlessMode: boolean) {
    setEndless(endlessMode);
    setQueue(shuffle(allIndices()));
    setSelected(null);
    setMastered(new Set());
    setEverMissed(new Set());
    setAnswersGiven(0);
    setStumbles(0);
    setStreak(0);
    savedRef.current = false;
    setPhase("playing");
  }

  // From the "Cleared!" screen: keep cycling forever without resetting the record.
  function continueEndless() {
    setEndless(true);
    setQueue(shuffle(allIndices()));
    setSelected(null);
    setPhase("playing");
  }

  function fireClearOnce(perfect: boolean) {
    if (savedRef.current) return;
    savedRef.current = true;
    if (!onCleared) return;
    Promise.resolve(onCleared(perfect)).then((earned) => {
      if (earned && earned.length && toast) toast.celebrate(earned);
      router.refresh();
    });
  }

  const cur = queue[0];
  const q = phase === "playing" ? questions[cur] : null;
  const answered = selected !== null;
  const correct = q ? selected === q.correctIndex : false;
  // After answering, `mastered` already reflects this question (set in choose).
  const willClear = !endless && correct && mastered.size === total;

  function choose(idx: number) {
    if (answered) return;
    setSelected(idx);
    setAnswersGiven((n) => n + 1);
    if (idx === questions[cur].correctIndex) {
      setMastered((m) => new Set(m).add(cur));
      setStreak((s) => s + 1);
    } else {
      setEverMissed((m) => new Set(m).add(cur));
      setStumbles((n) => n + 1);
      setStreak(0);
    }
  }

  function advance() {
    const isCorrect = selected === questions[cur].correctIndex;
    const allMastered = mastered.size === total; // includes cur if just answered correctly

    if (allMastered) fireClearOnce(everMissed.size === 0);

    if (!endless && allMastered) {
      setSelected(null);
      setPhase("cleared");
      return;
    }

    const rest = queue.slice(1);
    let next: number[];
    if (isCorrect) {
      next = endless ? [...rest, cur] : rest; // endless: recycle to back; mastery: drop
    } else {
      const at = Math.min(REINSERT, rest.length);
      next = [...rest.slice(0, at), cur, ...rest.slice(at)];
    }
    if (next.length === 0) next = shuffle(allIndices()); // endless safety net

    setQueue(next);
    setSelected(null);
  }

  // ---- Intro ----------------------------------------------------------------
  if (phase === "intro") {
    return (
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-5">
        <div className="space-y-2">
          <h2 className="text-lg font-bold text-parchment">Review the whole course</h2>
          <p className="text-sm text-parchment-dim leading-relaxed">
            All {total} question{total === 1 ? "" : "s"} from every lecture and the course test,
            shuffled together. Miss one and it comes back around — the review clears once you&apos;ve
            answered every question correctly.
          </p>
        </div>
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => start(false)}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            Start review
          </button>
          <button
            onClick={() => start(true)}
            className="px-4 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
          >
            ∞ Endless mode
          </button>
        </div>
      </section>
    );
  }

  // ---- Cleared (mastery finish) ---------------------------------------------
  if (phase === "cleared") {
    const perfect = everMissed.size === 0;
    return (
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-bold text-parchment">Cleared!</h2>
        <p className="text-4xl font-bold text-gold-400">
          {answersGiven}
          <span className="text-xl text-parchment-dim ml-2">
            answer{answersGiven === 1 ? "" : "s"}
          </span>
        </p>
        {perfect ? (
          <div className="rounded-lg border border-gold-500 bg-crimson-800 px-4 py-3">
            <p className="font-display text-sm uppercase tracking-[0.15em] text-gold-300">
              ✦ Flawless — every question right on the first try
            </p>
          </div>
        ) : (
          <p className="text-parchment-dim">
            {stumbles} stumble{stumbles === 1 ? "" : "s"} along the way — all mastered in the end.
          </p>
        )}
        <div className="flex flex-wrap gap-3">
          <button
            onClick={() => start(false)}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            Review again
          </button>
          <button
            onClick={continueEndless}
            className="px-4 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
          >
            ∞ Endless mode
          </button>
        </div>
      </section>
    );
  }

  // ---- Playing --------------------------------------------------------------
  if (!q) return null;
  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-5">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-lg font-bold text-parchment">Course Review</h2>
        <span className="text-sm text-parchment-dim">
          {endless ? (
            <>∞ Endless · streak {streak}</>
          ) : (
            <>
              {mastered.size} / {total} mastered · {queue.length} to review
            </>
          )}
        </span>
      </div>

      <p className="text-xs uppercase tracking-wider text-parchment-dim">{q.source}</p>
      <p className="text-parchment font-medium">{q.prompt}</p>

      <ol className="space-y-2">
        {q.options.map((opt, idx) => {
          let style = "w-full text-left px-4 py-3 rounded-lg border text-sm transition-colors ";
          if (!answered) {
            style += "border-crimson-700 bg-crimson-800 hover:border-gold-400 text-parchment";
          } else if (idx === q.correctIndex) {
            style += "border-green-500 bg-green-900/30 text-green-300";
          } else if (idx === selected) {
            style += "border-red-500 bg-red-900/30 text-red-300";
          } else {
            style += "border-crimson-700 bg-crimson-800 text-parchment-dim";
          }

          return (
            <li key={idx}>
              <button className={style} onClick={() => choose(idx)}>
                <span className="font-medium mr-2">{String.fromCharCode(65 + idx)}.</span>
                {opt}
              </button>
            </li>
          );
        })}
      </ol>

      {answered && (
        <div className="space-y-3">
          <p className={`font-semibold ${correct ? "text-green-400" : "text-red-400"}`}>
            {correct ? "Correct!" : "Incorrect — you'll see this one again"}
          </p>
          {q.explanation && <p className="text-sm text-parchment-dim">{q.explanation}</p>}
          <button
            onClick={advance}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            {willClear ? "Finish review" : "Next →"}
          </button>
        </div>
      )}
    </section>
  );
}
