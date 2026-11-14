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
          className="flex-1 bg-field border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 transition-colors"
        />
        <button
          type="submit"
          disabled={pending}
          className="font-ui font-semibold shrink-0 text-sm bg-gold-500 hover:bg-gold-400 disabled:bg-crimson-800 disabled:text-parchment-dim/70 disabled:cursor-not-allowed text-crimson-950 rounded px-4 py-2.5 transition-colors"
        >
          {pending ? "Saving…" : "Save"}
        </button>
      </div>
      {state.error && <p className="text-red-400 text-sm">{state.error}</p>}
      {state.success && <p className="text-green-400 text-sm">Saved — your handle is live in the Hall.</p>}
    </form>
  );
}
