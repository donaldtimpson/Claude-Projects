"use client";

import { useState } from "react";

export default function AdminLogin() {
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError("");
    const res = await fetch("/api/admin/login", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ password }),
    });
    if (res.ok) {
      window.location.href = "/admin";
    } else {
      setLoading(false);
      setError("Incorrect password.");
    }
  }

  return (
    <main className="flex-1 flex items-center justify-center px-4">
      <form onSubmit={submit} className="w-full max-w-sm space-y-4">
        <h1 className="text-2xl font-bold text-parchment">Admin Login</h1>
        <input
          type="password"
          value={password}
          onChange={(e) => setPassword(e.target.value)}
          placeholder="Password"
          required
          className="w-full px-4 py-2 bg-crimson-800 border border-crimson-700 rounded-lg text-parchment placeholder-parchment-dim focus:outline-none focus:border-gold-500"
        />
        {error && <p className="text-red-400 text-sm">{error}</p>}
        <button
          type="submit"
          disabled={loading}
          className="w-full py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 font-medium rounded-lg transition-colors disabled:opacity-50"
        >
          {loading ? "Checking…" : "Login"}
        </button>
      </form>
    </main>
  );
}
