"use client";

import { useActionState } from "react";
import { registerForClass, type RegisterState } from "@/lib/classes";

export default function RegisterForm() {
  const [state, action, pending] = useActionState<RegisterState, FormData>(registerForClass, {});

  if (state.success) {
    return <p className="text-green-400 text-sm">{state.success}</p>;
  }

  return (
    <form action={action} className="space-y-3">
      <div className="flex flex-col sm:flex-row gap-2">
        <input
          name="joinCode"
          placeholder="Class code"
          autoComplete="off"
          autoCapitalize="characters"
          maxLength={12}
          className="flex-1 bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 uppercase tracking-widest transition-colors"
        />
        <button
          type="submit"
          disabled={pending}
          className="shrink-0 font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 disabled:opacity-50 text-crimson-950 rounded px-4 py-2.5 font-semibold transition-colors"
        >
          {pending ? "Registering…" : "Register"}
        </button>
      </div>
      {state.error && <p className="text-red-400 text-sm">{state.error}</p>}
    </form>
  );
}
