"use client";

import { useState, useRef, useEffect } from "react";
import AttemptReview from "@/components/AttemptReview";
import { useToast, type ToastBadge } from "@/components/Toast";

type Question = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
};

export default function QuizPlayer({
  questions,
  onAttemptComplete,
}: {
  questions: Question[];
  onAttemptComplete?: (
    score: number,
    total: number,
    answers: (number | null)[],
  ) => Promise<ToastBadge[]> | void;
}) {
  const [current, setCurrent] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [answers, setAnswers] = useState<(number | null)[]>(Array(questions.length).fill(null));
  const [done, setDone] = useState(false);
  const [reviewing, setReviewing] = useState(false);
  const savedRef = useRef(false);
  const toast = useToast();

  const q = questions[current];
  const answered = selected !== null;
  const correct = selected === q.correctIndex;

  function choose(idx: number) {
    if (answered) return;
    setSelected(idx);
    const next = [...answers];
    next[current] = idx;
    setAnswers(next);
  }

  function advance() {
    if (current < questions.length - 1) {
      setCurrent(current + 1);
      setSelected(answers[current + 1]);
    } else {
      setDone(true);
    }
  }

  function restart() {
    setCurrent(0);
    setSelected(null);
    setAnswers(Array(questions.length).fill(null));
    setDone(false);
    setReviewing(false);
    savedRef.current = false;
  }

  const score = answers.filter((a, i) => a === questions[i].correctIndex).length;

  // Fire the callback exactly once when the quiz is completed; celebrate any
  // achievements the attempt unlocked.
  useEffect(() => {
    if (done && !savedRef.current && onAttemptComplete) {
      savedRef.current = true;
      Promise.resolve(onAttemptComplete(score, questions.length, answers)).then((earned) => {
        if (earned && earned.length && toast) toast.celebrate(earned);
      });
    }
  }, [done, score, questions.length, answers, onAttemptComplete, toast]);

  if (done && reviewing) {
    return (
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-6">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-bold text-parchment">Answer Review</h2>
          <button
            onClick={() => setReviewing(false)}
            className="text-sm text-parchment-dim hover:text-gold-300 transition-colors"
          >
            ← Back to Results
          </button>
        </div>
        <AttemptReview questions={questions} answers={answers} />
        <button
          onClick={restart}
          className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
        >
          Retake Quiz
        </button>
      </section>
    );
  }

  if (done) {
    const pct = Math.round((score / questions.length) * 100);
    return (
      <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-bold text-parchment">Quiz Results</h2>
        <p className="text-4xl font-bold text-gold-400">
          {score}/{questions.length}
          <span className="text-xl text-parchment-dim ml-2">({pct}%)</span>
        </p>
        <p className="text-parchment-dim">
          {pct === 100
            ? "Perfect score!"
            : pct >= 70
            ? "Good work — review the ones you missed."
            : "Keep studying and try again."}
        </p>
        <div className="flex gap-3">
          <button
            onClick={() => setReviewing(true)}
            className="px-4 py-2 bg-crimson-700 hover:bg-crimson-600 text-parchment text-sm font-medium rounded-lg transition-colors"
          >
            Review Answers
          </button>
          <button
            onClick={restart}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            Retake Quiz
          </button>
        </div>
      </section>
    );
  }

  return (
    <section className="bg-crimson-900 border border-crimson-700 rounded-xl p-6 space-y-5">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-parchment">Quiz</h2>
        <span className="text-sm text-parchment-dim">
          {current + 1} / {questions.length}
        </span>
      </div>

      <p className="text-parchment font-medium">{q.prompt}</p>

      <ol className="space-y-2">
        {q.options.map((opt, idx) => {
          let style =
            "w-full text-left px-4 py-3 rounded-lg border text-sm transition-colors ";
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
            {correct ? "Correct!" : "Incorrect"}
          </p>
          {q.explanation && <p className="text-sm text-parchment-dim">{q.explanation}</p>}
          <button
            onClick={advance}
            className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
          >
            {current < questions.length - 1 ? "Next Question →" : "See Results"}
          </button>
        </div>
      )}
    </section>
  );
}
