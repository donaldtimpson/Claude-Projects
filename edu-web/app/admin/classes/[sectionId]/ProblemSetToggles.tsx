"use client";

import { useTransition } from "react";
import { useRouter } from "next/navigation";
import { setProblemSetDraft, toggleSolutionsPublic } from "@/lib/assignments";

// Inline publish + solutions toggles for a problem-set assignment, so the common
// action doesn't require drilling into the problem-set editor. Refreshes the
// gradebook after each toggle (the shared actions revalidate other paths only).
export default function ProblemSetToggles({
  problemSetId,
  isDraft,
  solutionsPublic,
}: {
  problemSetId: string;
  isDraft: boolean;
  solutionsPublic: boolean;
}) {
  const router = useRouter();
  const [pending, start] = useTransition();

  function run(action: (fd: FormData) => Promise<void>, fields: Record<string, string>) {
    const fd = new FormData();
    for (const [k, v] of Object.entries(fields)) fd.set(k, v);
    start(async () => {
      await action(fd);
      router.refresh();
    });
  }

  const chip = "text-[11px] uppercase tracking-wider px-2 py-0.5 rounded border transition-colors disabled:opacity-50";
  const green = "bg-green-900/30 border-green-700 text-green-300 hover:bg-green-900/50";
  const amber = "bg-amber-900/40 border-amber-700 text-amber-300 hover:bg-amber-900/60";

  return (
    <>
      <button
        type="button"
        disabled={pending}
        onClick={() => run(setProblemSetDraft, { id: problemSetId, isDraft: String(!isDraft) })}
        title={isDraft ? "Draft — click to publish" : "Published — click to unpublish"}
        className={`${chip} ${isDraft ? amber : green}`}
      >
        {isDraft ? "Draft" : "Published"}
      </button>
      <button
        type="button"
        disabled={pending}
        onClick={() => run(toggleSolutionsPublic, { id: problemSetId })}
        title={solutionsPublic ? "Solutions shown — click to hide" : "Solutions hidden — click to show"}
        className={`${chip} ${solutionsPublic ? green : amber}`}
      >
        {solutionsPublic ? "Solutions: shown" : "Solutions: hidden"}
      </button>
    </>
  );
}
