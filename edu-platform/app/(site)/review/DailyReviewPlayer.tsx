"use client";

import { useEffect, useRef, useState } from "react";
import Link from "next/link";
import { useRouter } from "next/navigation";
import { useToast, type ToastBadge } from "@/components/Toast";

type Card = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  source: string;
};

export default function DailyReviewPlayer({
  cards,
  onGrade,
  onFinish,
}: {
  cards: Card[];
  // Persists one card's new schedule the moment it's answered (fire-and-forget).
  onGrade?: (questionId: string, correct: boolean) => Promise<void> | void;
  // Fires once at the end; returns any freshly-unlocked badges for the toast.
  onFinish?: () => Promise<ToastBadge[]> | void;
}) {
  const total = cards.length;
  const [index, setIndex] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [correctCount, setCorrectCount] = useState(0);
  const [missed, setMissed] = useState(0);
  const [done, setDone] = useState(false);

  const savedRef = useRef(false);
  const toast = useToast();
  const router = useRouter();

  const card = cards[index];
  const answered = selected !== null;
  const correct = card ? selected === card.correctIndex : false;

  useEffect(() => {
    if (done && !savedRef.current) {
      savedRef.current = true;
      if (onFinish) {
        Promise.resolve(onFinish()).then((earned) => {
          if (earned && earned.length && toast) toast.celebrate(earned);
          router.refresh();
        });
      } else {
        router.refresh();
      }
    }
  }, [done, onFinish, toast, router]);

  function choose(idx: number) {
    if (answered) return;
    setSelected(idx);
    const isCorrect = idx === card.correctIndex;
    if (isCorrect) setCorrectCount((n) => n + 1);
    else setMissed((n) => n + 1);
    // Persist this card's new Leitner schedule immediately.
    void Promise.resolve(onGrade?.(card.id, isCorrect));
  }

  function advance() {
    if (index < total - 1) {
      setIndex(index + 1);
      setSelected(null);
    } else {
      setDone(true);
    }
  }

  if (done) {
    return (
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-bold text-parchment">Review complete</h2>
        <p className="text-4xl font-bold text-gold-400">
          {correctCount}/{total}
          <span className="text-xl text-parchment-dim ml-2">correct</span>
        </p>
        <p className="text-parchment-dim">
          {missed === 0
            ? "Spotless — every card cleared. They'll resurface on a longer schedule."
            : `${missed} card${missed === 1 ? "" : "s"} reset to the start — you'll see ${missed === 1 ? "it" : "them"} again soon.`}
        </p>
        <Link
          href="/dashboard"
          className="inline-block px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
        >
          Back to dashboard
        </Link>
      </section>
    );
  }

  if (!card) return null;
  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-5">
      <div className="flex items-center justify-between gap-3">
        <h2 className="text-lg font-bold text-parchment">Daily Review</h2>
        <span className="text-sm text-parchment-dim">
          {index + 1} / {total}
        </span>
      </div>

      <p className="text-xs uppercase tracking-wider text-parchment-dim">{card.source}</p>
      <p className="text-parchment font-medium">{card.prompt}</p>

      <ol className="space-y-2">
        {card.options.map((opt, idx) => {
          let style = "w-full text-left px-4 py-3 rounded-lg border text-sm transition-colors ";
          if (!answered) {
            style += "border-crimson-700 bg-crimson-800 hover:border-gold-400 text-parchment";
          } else if (idx === card.correctIndex) {
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
            {correct ? "Correct!" : "Incorrect — back to the start for this one"}
          </p>
          {card.explanation && <p className="text-sm text-parchment-dim">{card.explanation}</p>}
          <button
            onClick={advance}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            {index < total - 1 ? "Next →" : "Finish"}
          </button>
        </div>
      )}
    </section>
  );
}
