"use client";

import { useState } from "react";

type Question = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
};

export default function QuizPlayer({ questions }: { questions: Question[] }) {
  const [current, setCurrent] = useState(0);
  const [selected, setSelected] = useState<number | null>(null);
  const [answers, setAnswers] = useState<(number | null)[]>(Array(questions.length).fill(null));
  const [done, setDone] = useState(false);

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
  }

  if (done) {
    const score = answers.filter((a, i) => a === questions[i].correctIndex).length;
    const pct = Math.round((score / questions.length) * 100);
    return (
      <section className="bg-slate-900 border border-slate-800 rounded-xl p-6 space-y-4">
        <h2 className="text-lg font-bold text-white">Quiz Results</h2>
        <p className="text-4xl font-bold text-indigo-400">
          {score}/{questions.length}
          <span className="text-xl text-slate-400 ml-2">({pct}%)</span>
        </p>
        <p className="text-slate-400">
          {pct === 100
            ? "Perfect score!"
            : pct >= 70
            ? "Good work — review the ones you missed."
            : "Keep studying and try again."}
        </p>
        <button
          onClick={restart}
          className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium rounded-lg transition-colors"
        >
          Retake Quiz
        </button>
      </section>
    );
  }

  return (
    <section className="bg-slate-900 border border-slate-800 rounded-xl p-6 space-y-5">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-bold text-white">Quiz</h2>
        <span className="text-sm text-slate-500">
          {current + 1} / {questions.length}
        </span>
      </div>

      <p className="text-slate-100 font-medium">{q.prompt}</p>

      <ol className="space-y-2">
        {q.options.map((opt, idx) => {
          let style =
            "w-full text-left px-4 py-3 rounded-lg border text-sm transition-colors ";
          if (!answered) {
            style += "border-slate-700 bg-slate-800 hover:border-indigo-400 text-slate-200";
          } else if (idx === q.correctIndex) {
            style += "border-green-500 bg-green-900/30 text-green-300";
          } else if (idx === selected) {
            style += "border-red-500 bg-red-900/30 text-red-300";
          } else {
            style += "border-slate-700 bg-slate-800 text-slate-500";
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
          {q.explanation && <p className="text-sm text-slate-300">{q.explanation}</p>}
          <button
            onClick={advance}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium rounded-lg transition-colors"
          >
            {current < questions.length - 1 ? "Next Question →" : "See Results"}
          </button>
        </div>
      )}
    </section>
  );
}
