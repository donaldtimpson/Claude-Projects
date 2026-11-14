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
          className="flex-1 bg-field border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment placeholder:text-parchment-dim/60 uppercase tracking-widest transition-colors"
        />
        <button
          type="submit"
          disabled={pending}
          className="font-ui font-semibold shrink-0 text-sm bg-gold-500 hover:bg-gold-400 disabled:bg-crimson-800 disabled:text-parchment-dim/70 disabled:cursor-not-allowed text-crimson-950 rounded px-4 py-2.5 transition-colors"
        >
          {pending ? "Registering…" : "Register"}
        </button>
      </div>
      {state.error && <p className="text-red-400 text-sm">{state.error}</p>}
    </form>
  );
}
