"use client";

// Printable arithmetic drill generator — a teacher's "mad minute" worksheet maker.
// Fully client-side: pick operations and a number range, get a fresh printable sheet
// with an optional answer key. No ads, no site chrome, no backend.
//
// Correctness (mirrors lib/drills/generators/arithmetic.ts):
//   ÷ is the inverse of × — dividend = divisor × quotient — so quotients are always
//     whole numbers. The divisor and quotient come from the chosen range.
//   − is presented as (larger − smaller) so differences are never negative.
// Both operands of + and − stay inside the range; for × both factors do; for ÷ the
// divisor and quotient do (the dividend is their product, as any division drill needs).
//
// Reproducibility: the whole sheet is derived from a numeric seed shown on the page
// ("Set #1234"). Same seed → identical sheet, so an absent student can get the exact
// same one; "New sheet" rerolls the seed for fresh problems.

import Link from "next/link";
import { useMemo, useState, useEffect } from "react";

type Op = "+" | "−" | "×" | "÷";
const ALL_OPS: Op[] = ["+", "−", "×", "÷"];

type Problem = { a: number; op: Op; b: number; answer: number };

// mulberry32 — tiny deterministic PRNG so a seed reproduces a sheet exactly.
function mulberry32(seed: number) {
  let t = seed >>> 0;
  return () => {
    t += 0x6d2b79f5;
    let x = t;
    x = Math.imul(x ^ (x >>> 15), x | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  };
}

function buildProblems(ops: Op[], min: number, max: number, count: number, seed: number): Problem[] {
  const rnd = mulberry32(seed);
  const randInt = (lo: number, hi: number) => Math.floor(rnd() * (hi - lo + 1)) + lo;
  const out: Problem[] = [];
  const active = ops.length ? ops : (["+"] as Op[]);
  for (let i = 0; i < count; i++) {
    const op = active[Math.floor(rnd() * active.length)];
    if (op === "+") {
      const a = randInt(min, max), b = randInt(min, max);
      out.push({ a, op, b, answer: a + b });
    } else if (op === "−") {
      const x = randInt(min, max), y = randInt(min, max);
      const a = Math.max(x, y), b = Math.min(x, y);
      out.push({ a, op, b, answer: a - b });
    } else if (op === "×") {
      const a = randInt(min, max), b = randInt(min, max);
      out.push({ a, op, b, answer: a * b });
    } else {
      // ÷ : divisor and quotient in range; dividend is their product → clean.
      const b = randInt(min, max), q = randInt(min, max);
      out.push({ a: b * q, op, b, answer: q });
    }
  }
  return out;
}

// The operator glyph. Everything renders as plain text EXCEPT ÷ — Arial's division
// sign sits its dots too close to the bar, so we draw our own with roomier spacing.
// Sized in em so it tracks the surrounding font; nothing else is affected.
function OpGlyph({ op }: { op: Op }) {
  if (op !== "÷") return <>{op}</>;
  return (
    <svg
      viewBox="0 0 24 24"
      aria-hidden
      className="inline-block"
      style={{ width: "0.7em", height: "1em", verticalAlign: "-0.11em" }}
    >
      <circle cx="12" cy="5" r="2" fill="currentColor" />
      <rect x="3" y="11" width="18" height="2" rx="1" fill="currentColor" />
      <circle cx="12" cy="19" r="2" fill="currentColor" />
    </svg>
  );
}

// A small toggle button styled for on-brand accents but legible on the white print page.
function Toggle({ on, onClick, children }: { on: boolean; onClick: () => void; children: React.ReactNode }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={
        "min-w-11 rounded-md border px-3 py-2 text-lg font-semibold transition-colors " +
        (on
          ? "border-crimson-700 bg-crimson-700 text-white"
          : "border-zinc-300 bg-white text-zinc-500 hover:border-zinc-400")
      }
      aria-pressed={on}
    >
      {children}
    </button>
  );
}

export default function ArithmeticWorksheet() {
  const [ops, setOps] = useState<Set<Op>>(new Set<Op>(["+", "−", "×", "÷"]));
  const [min, setMin] = useState(3);
  const [max, setMax] = useState(15);
  const [count, setCount] = useState(60);
  const [cols, setCols] = useState(6);
  const [showKey, setShowKey] = useState(false);
  const [seed, setSeed] = useState(1000);

  // Seed only rolls in the browser (avoids hydration mismatch from a random initial value).
  useEffect(() => setSeed(Math.floor(Math.random() * 9000) + 1000), []);

  const opList = useMemo(() => ALL_OPS.filter((o) => ops.has(o)), [ops]);
  const safeMin = Math.min(min, max);
  const safeMax = Math.max(min, max);
  const safeCount = Math.max(1, Math.min(200, count || 0));

  const problems = useMemo(
    () => buildProblems(opList, safeMin, safeMax, safeCount, seed),
    [opList, safeMin, safeMax, safeCount, seed]
  );

  function toggleOp(o: Op) {
    setOps((prev) => {
      const next = new Set(prev);
      if (next.has(o)) { if (next.size > 1) next.delete(o); } // keep at least one
      else next.add(o);
      return next;
    });
  }

  return (
    <div className="mx-auto max-w-3xl px-6 py-6 print:px-[0.5in] print:py-[0.4in]">
      {/* Print sizing: the site sets html{font-size:112.5%} for on-screen readability,
          which inflates the printed sheet enough to spill 60 problems onto a 2nd page.
          Reset to 16px for print. @page margin:0 removes the browser-drawn header/footer
          (date, page title, URL, page number) — those render in the page margin box, so
          zeroing it leaves nowhere to draw them; the real margins come from the padding above. */}
      <style>{`@page{margin:0} @media print{html{font-size:16px}}`}</style>
      {/* ---- Controls (never printed) ---- */}
      <div className="print:hidden">
        <h1 className="font-display text-2xl mb-1">Arithmetic Worksheet Generator</h1>
        <p className="text-sm text-zinc-600 mb-5">
          Pick operations and a range, then print. Every sheet is fresh; the set number reprints the same one.
        </p>

        <div className="flex flex-wrap items-end gap-x-6 gap-y-4 rounded-lg border border-zinc-200 bg-zinc-50 p-4">
          <div>
            <div className="mb-1 text-xs font-medium uppercase tracking-wide text-zinc-500">Operations</div>
            <div className="flex gap-2">
              {ALL_OPS.map((o) => (
                <Toggle key={o} on={ops.has(o)} onClick={() => toggleOp(o)}>{o}</Toggle>
              ))}
            </div>
          </div>

          <label className="block">
            <div className="mb-1 text-xs font-medium uppercase tracking-wide text-zinc-500">Range</div>
            <div className="flex items-center gap-2">
              <input type="number" value={min} onChange={(e) => setMin(+e.target.value)}
                className="w-16 rounded-md border border-zinc-300 px-2 py-2 text-center" />
              <span className="text-zinc-400">to</span>
              <input type="number" value={max} onChange={(e) => setMax(+e.target.value)}
                className="w-16 rounded-md border border-zinc-300 px-2 py-2 text-center" />
            </div>
          </label>

          <label className="block">
            <div className="mb-1 text-xs font-medium uppercase tracking-wide text-zinc-500">Problems</div>
            <input type="number" value={count} onChange={(e) => setCount(+e.target.value)}
              className="w-20 rounded-md border border-zinc-300 px-2 py-2 text-center" />
          </label>

          <label className="block">
            <div className="mb-1 text-xs font-medium uppercase tracking-wide text-zinc-500">Columns</div>
            <select value={cols} onChange={(e) => setCols(+e.target.value)}
              className="rounded-md border border-zinc-300 px-2 py-2">
              {[3, 4, 5, 6, 8].map((c) => <option key={c} value={c}>{c}</option>)}
            </select>
          </label>

          <label className="flex items-center gap-2 pb-2 text-sm">
            <input type="checkbox" checked={showKey} onChange={(e) => setShowKey(e.target.checked)} />
            Answer key
          </label>
        </div>

        <div className="mt-4 flex flex-wrap items-center gap-3">
          <button type="button" onClick={() => setSeed(Math.floor(Math.random() * 9000) + 1000)}
            className="rounded-md border border-zinc-300 bg-white px-4 py-2 text-sm font-medium hover:border-zinc-400">
            New sheet ↻
          </button>
          <button type="button" onClick={() => window.print()}
            className="rounded-md bg-crimson-700 px-5 py-2 text-sm font-semibold text-white hover:bg-crimson-600">
            Print / Save PDF
          </button>
          <Link href="/drills/arithmetic"
            className="ml-auto text-sm text-crimson-700 underline underline-offset-2 hover:text-crimson-600">
            Practice on screen instead →
          </Link>
        </div>

        <hr className="my-6 border-zinc-200" />
      </div>

      {/* ---- The worksheet (this is what prints) ---- */}
      <Sheet title="Arithmetic Drill" cols={cols} problems={problems} />

      {showKey && (
        <div className="mt-12 print:mt-0 print:break-before-page">
          <Sheet title="Answer Key" cols={cols} problems={problems} showAnswers />
        </div>
      )}
    </div>
  );
}

function Sheet({
  title, cols, problems, showAnswers = false,
}: {
  title: string; cols: number; problems: Problem[]; showAnswers?: boolean;
}) {
  return (
    <section>
      {/* Branded header — same seal + eyebrow + display title as the lecture-notes print page,
          laid out on one row so it doesn't cost a second page. */}
      <header className="mb-3 flex items-center gap-3 border-b-2 border-zinc-800 pb-2">
        {/* Plain <img> (not next/image) so the seal eager-loads before the print dialog fires. */}
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src="/logo.png" alt="The Timpson Lyceum seal" width={44} height={44} className="h-10 w-auto shrink-0" />
        <div>
          <p className="font-display text-[0.65rem] tracking-[0.2em] uppercase text-zinc-400 leading-none">
            The Timpson Lyceum
          </p>
          <h2 className="font-display text-xl font-bold text-zinc-900 leading-tight">{title}</h2>
        </div>
      </header>

      {!showAnswers && (
        <div className="mb-4 flex items-end gap-6 text-sm text-zinc-700">
          {/* Name and Date stretch to fill the row; Score stays compact. */}
          <div className="flex flex-1 items-end gap-2">
            <span>Name:</span>
            <span className="h-5 flex-1 border-b border-zinc-400" />
          </div>
          <div className="flex flex-1 items-end gap-2">
            <span>Date:</span>
            <span className="h-5 flex-1 border-b border-zinc-400" />
          </div>
          <div className="flex shrink-0 items-end gap-2 whitespace-nowrap">
            <span>Score:</span>
            <span className="inline-block h-5 w-16 border-b border-zinc-400" />
            <span>/ {problems.length}</span>
          </div>
        </div>
      )}

      <ol
        className="grid gap-x-4 gap-y-2 font-medium"
        style={{
          gridTemplateColumns: `repeat(${cols}, minmax(0, 1fr))`,
          // Plain, bold sans-serif for the problems — legible at a glance, unlike the
          // site's Garamond. (The header keeps the house font.)
          fontFamily: "Arial, Helvetica, ui-sans-serif, system-ui, sans-serif",
        }}
      >
        {problems.map((p, i) => (
          <li key={i} className="flex justify-center">
            {/* Narrow block: both lines right-aligned so the units column lines up;
                operator hugs the operand (like a math-aids drill), not spread apart. */}
            <div className="w-12 tabular-nums text-xl leading-tight">
              <div className="text-right">{p.a}</div>
              <div className="flex justify-between">
                <span><OpGlyph op={p.op} /></span>
                <span>{p.b}</span>
              </div>
              <div className="mt-0.5 min-h-7 border-t-2 border-zinc-800 pt-0.5 text-right">
                {showAnswers && <span className="font-semibold text-crimson-700">{p.answer}</span>}
              </div>
            </div>
          </li>
        ))}
      </ol>
    </section>
  );
}
