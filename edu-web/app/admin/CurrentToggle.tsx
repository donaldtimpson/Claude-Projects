"use client";

import { useState, useTransition } from "react";
import { useRouter } from "next/navigation";

export default function CurrentToggle({
  courseId,
  initial,
}: {
  courseId: string;
  initial: boolean;
}) {
  const router = useRouter();
  const [isCurrent, setIsCurrent] = useState(initial);
  const [pending, startTransition] = useTransition();

  async function toggle() {
    const next = !isCurrent;
    setIsCurrent(next);
    const res = await fetch(`/api/courses/${courseId}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isCurrent: next }),
    });
    if (!res.ok) {
      setIsCurrent(!next);
      return;
    }
    startTransition(() => router.refresh());
  }

  return (
    <button
      type="button"
      onClick={toggle}
      disabled={pending}
      aria-pressed={isCurrent}
      className={`font-ui font-semibold text-sm px-2.5 py-1 rounded border transition-colors ${ isCurrent ? "bg-gold-500 text-crimson-950 border-gold-500 hover:bg-gold-400" : "bg-transparent text-parchment-dim border-crimson-700 hover:border-gold-500 hover:text-gold-300" } disabled:bg-crimson-800 disabled:text-parchment-dim/70 disabled:cursor-not-allowed`}
    >
      {isCurrent ? "★ Current" : "Mark Current"}
    </button>
  );
}
