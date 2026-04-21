"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";
import Link from "next/link";

export default function SignUpPage() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError("");
    if (password.length < 8) {
      setError("Password must be at least 8 characters.");
      return;
    }
    setLoading(true);
    const res = await fetch("/api/auth/signup", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, email, password }),
    });
    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "Something went wrong.");
      setLoading(false);
      return;
    }
    await signIn("credentials", { email, password, redirect: false });
    router.push("/");
    router.refresh();
  }

  return (
    <div className="min-h-screen bg-crimson-950 flex items-center justify-center px-4">
      <div className="w-full max-w-md bg-crimson-900 rounded-xl border border-crimson-700 p-8">
        <h1 className="font-display text-2xl text-parchment-100 text-center mb-6">Create Account</h1>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm text-parchment-300 mb-1">Name</label>
            <input
              type="text"
              value={name}
              onChange={e => setName(e.target.value)}
              required
              className="w-full bg-crimson-800 border border-crimson-600 rounded-lg px-4 py-2 text-parchment-100 placeholder-parchment-500 focus:outline-none focus:border-gold-400"
              placeholder="Your name"
            />
          </div>
          <div>
            <label className="block text-sm text-parchment-300 mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              required
              className="w-full bg-crimson-800 border border-crimson-600 rounded-lg px-4 py-2 text-parchment-100 placeholder-parchment-500 focus:outline-none focus:border-gold-400"
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
              className="w-full bg-crimson-800 border border-crimson-600 rounded-lg px-4 py-2 text-parchment-100 placeholder-parchment-500 focus:outline-none focus:border-gold-400"
              placeholder="At least 8 characters"
            />
          </div>

          {error && <p className="text-red-400 text-sm">{error}</p>}

          <button
            type="submit"
            disabled={loading}
            className="w-full bg-gold-600 hover:bg-gold-500 text-crimson-950 font-semibold py-2 rounded-lg transition-colors disabled:opacity-50"
          >
            {loading ? "Creating account…" : "Create Account"}
          </button>
        </form>

        <p className="text-center text-parchment-400 text-sm mt-6">
          Already have an account?{" "}
          <Link href="/auth/signin" className="text-gold-400 hover:text-gold-300">
            Sign in
          </Link>
        </p>
      </div>
    </div>
  );
}
