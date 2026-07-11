"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";

type Lecture = { id: string; title: string };

export default function LectureOrderEditor({
  courseId,
  initialManualOrder,
  lectures,
}: {
  courseId: string;
  initialManualOrder: boolean;
  lectures: Lecture[];
}) {
  const router = useRouter();
  const [manual, setManual] = useState(initialManualOrder);
  const [items, setItems] = useState<Lecture[]>(lectures);
  const [dragIndex, setDragIndex] = useState<number | null>(null);
  const [overIndex, setOverIndex] = useState<number | null>(null);
  const [status, setStatus] = useState<"idle" | "saving" | "saved" | "error">("idle");
  const [, startTransition] = useTransition();

  async function toggleManual() {
    const next = !manual;
    setManual(next);
    const res = await fetch(`/api/courses/${courseId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ manualOrder: next }),
    });
    if (!res.ok) {
      setManual(!next);
      return;
    }
    startTransition(() => router.refresh());
  }

  async function persist(order: Lecture[]) {
    setStatus("saving");
    const res = await fetch(`/api/courses/${courseId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ videoOrder: order.map((l) => l.id) }),
    });
    if (res.ok) {
      setStatus("saved");
      startTransition(() => router.refresh());
    } else {
      setStatus("error");
    }
  }

  function move(from: number, to: number) {
    if (to < 0 || to >= items.length || from === to) return;
    const next = [...items];
    const [moved] = next.splice(from, 1);
    next.splice(to, 0, moved);
    setItems(next);
    persist(next);
  }

  function handleDrop(target: number) {
    const src = dragIndex;
    setDragIndex(null);
    setOverIndex(null);
    if (src === null || src === target) return;
    move(src, target);
  }

  return (
    <section className="border border-crimson-700 rounded-lg p-4 space-y-3">
      <div className="flex items-center justify-between gap-3">
        <div>
          <h2 className="font-display text-sm tracking-[0.15em] uppercase text-parchment-dim">
            Lecture order
          </h2>
          <p className="text-xs text-parchment-dim mt-1">
            {manual
              ? "Manual — drag to arrange. YouTube Sync won't reorder; new lectures append to the end."
              : "Chronological — follows the YouTube playlist and self-heals on every Sync."}
          </p>
        </div>
        <button
          type="button"
          onClick={toggleManual}
          aria-pressed={manual}
          className={`shrink-0 text-xs font-display tracking-wider uppercase px-2.5 py-1 rounded border transition-colors ${
            manual
              ? "bg-gold-500 text-crimson-950 border-gold-500 hover:bg-gold-400"
              : "bg-transparent text-parchment-dim border-crimson-700 hover:border-gold-500 hover:text-gold-300"
          }`}
        >
          {manual ? "✓ Manual order" : "Manual order"}
        </button>
      </div>

      {manual && (
        <>
          <ul className="space-y-1.5">
            {items.map((lec, idx) => (
              <li
                key={lec.id}
                draggable
                onDragStart={() => setDragIndex(idx)}
                onDragEnd={() => {
                  setDragIndex(null);
                  setOverIndex(null);
                }}
                onDragOver={(e) => {
                  e.preventDefault();
                  if (overIndex !== idx) setOverIndex(idx);
                }}
                onDrop={() => handleDrop(idx)}
                className={`flex items-center gap-3 rounded-md border px-3 py-2 bg-crimson-900 cursor-move select-none transition-colors ${
                  overIndex === idx && dragIndex !== null && dragIndex !== idx
                    ? "border-gold-500"
                    : "border-crimson-700"
                } ${dragIndex === idx ? "opacity-50" : ""}`}
              >
                <span className="text-parchment-dim" aria-hidden>
                  ⠿
                </span>
                <span className="text-gold-400 font-display text-sm tabular-nums w-6 shrink-0">
                  {idx + 1}
                </span>
                <span className="text-sm text-parchment flex-1 truncate">{lec.title}</span>
                <span className="flex gap-1 shrink-0">
                  <button
                    type="button"
                    onClick={() => move(idx, idx - 1)}
                    disabled={idx === 0}
                    aria-label="Move up"
                    className="text-parchment-dim hover:text-gold-300 disabled:opacity-30 px-1"
                  >
                    ↑
                  </button>
                  <button
                    type="button"
                    onClick={() => move(idx, idx + 1)}
                    disabled={idx === items.length - 1}
                    aria-label="Move down"
                    className="text-parchment-dim hover:text-gold-300 disabled:opacity-30 px-1"
                  >
                    ↓
                  </button>
                </span>
              </li>
            ))}
          </ul>
          <p className="text-xs h-4">
            {status === "saving" && <span className="text-parchment-dim">Saving order…</span>}
            {status === "saved" && <span className="text-green-400">Order saved</span>}
            {status === "error" && (
              <span className="text-red-400">Couldn&apos;t save order — try again.</span>
            )}
          </p>
        </>
      )}
    </section>
  );
}
