"use client";

import { useActionState } from "react";
import { submitAssignment, type SubmitState } from "@/lib/assignments";

export default function SubmitForm({
  assignmentId,
  currentUrl,
}: {
  assignmentId: string;
  currentUrl?: string | null;
}) {
  const [state, action, pending] = useActionState<SubmitState, FormData>(submitAssignment, {});

  return (
    <form action={action} className="space-y-2">
      <input type="hidden" name="assignmentId" value={assignmentId} />
      <div className="flex flex-col sm:flex-row gap-2">
        <input
          name="url"
          type="url"
          defaultValue={currentUrl ?? ""}
          placeholder="Link to your solution (Google Drive, etc.)"
          className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-2 text-parchment text-sm placeholder:text-parchment-dim/60 transition-colors"
        />
        <button
          type="submit"
          disabled={pending}
          className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 disabled:opacity-50 text-crimson-950 rounded px-4 py-2 font-semibold transition-colors"
        >
          {pending ? "Submitting…" : currentUrl ? "Resubmit" : "Submit"}
        </button>
      </div>
      {state.error && <p className="text-red-400 text-xs">{state.error}</p>}
      {state.success && <p className="text-green-400 text-xs">{state.success}</p>}
    </form>
  );
}
