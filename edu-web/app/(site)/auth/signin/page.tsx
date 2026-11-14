"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function SignInPage() {
  const router = useRouter();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    setLoading(true);
    const result = await signIn("credentials", { email, password, redirect: false });
    setLoading(false);
    if (result?.error) {
      setError("Invalid email or password.");
    } else {
      router.push("/");
      router.refresh();
    }
  }

  return (
    <div className="min-h-screen bg-crimson-950 flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-crimson-900 rounded-xl border border-crimson-700 p-8">
        <h1 className="font-bold text-2xl text-parchment text-center mb-6">Sign In</h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm text-parchment-300 mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              className="w-full bg-field border border-crimson-600 rounded-lg px-4 py-2 text-parchment-100 placeholder-parchment-500 focus:outline-none focus:border-gold-400"
              placeholder="you@example.com"
            />
          </div>
          <div>
            <label className="block text-sm text-parchment-300 mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              required
              className="w-full bg-field border border-crimson-600 rounded-lg px-4 py-2 text-parchment-100 placeholder-parchment-500 focus:outline-none focus:border-gold-400"
              placeholder="••••••••"
            />
          </div>

          {error && <p className="text-red-400 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="font-ui font-semibold w-full bg-gold-500 hover:bg-gold-400 text-crimson-950 py-2 rounded-lg transition-colors disabled:bg-crimson-800 disabled:text-parchment-dim/70 disabled:cursor-not-allowed"
          >
            {loading ? "Signing in…" : "Sign In"}
          </button>
        </form>

        <p className="text-center text-parchment-400 text-sm mt-6">
          Don&apos;t have an account?{" "}
          <Link href="/auth/signup" className="text-gold-400 hover:text-gold-300">
            Sign up
          </Link>
        </p>
      </div>
    </div>
  );
}
