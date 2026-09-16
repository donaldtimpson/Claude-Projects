"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";

// Marks whether this course links its lectures to the bundled Grammar lesson
// drills. Off by default, so the 19-lesson grid only appears where it belongs
// (the Grammar course), not on every course's lectures.
export default function LessonBankToggle({
  courseId,
  initial,
}: {
  courseId: string;
  initial: string | null;
}) {
  const router = useRouter();
  const [on, setOn] = useState(initial === "grammar");
  const [pending, startTransition] = useTransition();

  async function toggle() {
    const next = !on;
    setOn(next);
    const res = await fetch(`/api/courses/${courseId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ lessonBank: next ? "grammar" : null }),
    });
    if (!res.ok) {
      setOn(!next);
      return;
    }
    startTransition(() => router.refresh());
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={pending}
      aria-pressed={on}
      className={`text-xs font-display tracking-wider uppercase px-2.5 py-1 rounded border transition-colors ${
        on
          ? "bg-gold-500 text-crimson-950 border-gold-500 hover:bg-gold-400"
          : "bg-transparent text-parchment-dim border-crimson-700 hover:border-gold-500 hover:text-gold-300"
      } disabled:opacity-50`}
    >
      {on ? "✓ Grammar lessons" : "Grammar lessons: off"}
    </button>
  );
}
