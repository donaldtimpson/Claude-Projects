"use client";

import { useActionState } from "react";
import { setHandle, type HandleState } from "./actions";
import { HANDLE_MAX } from "@/lib/gamification/handle";

export default function HandleForm({ current, placeholder }: { current: string | null; placeholder: string }) {
  const [state, action, pending] = useActionState<HandleState, FormData>(setHandle, {});

  return (
    <form action={action} className="space-y-3">
      <div className="flex flex-col sm:flex-row gap-2">
        <input
          name="handle"
          defaultValue={current ?? ""}
          placeholder={placeholder}
          maxLength={HANDLE_MAX}
          autoComplete="off"
          className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
        />
        <button
          type="submit"
          disabled={pending}
          className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 disabled:opacity-50 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
        >
          {pending ? "Saving…" : "Save"}
        </button>
      </div>
      {state.error && <p className="text-red-400 text-sm">{state.error}</p>}
      {state.success && <p className="text-green-400 text-sm">Saved — your handle is live in the Hall.</p>}
    </form>
  );
}
