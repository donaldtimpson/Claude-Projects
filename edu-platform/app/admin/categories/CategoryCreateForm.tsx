"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

function toSlug(s: string) {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "");
}

export default function CategoryCreateForm() {
  const router = useRouter();
  const [name, setName] = useState("");
  const [slug, setSlug] = useState("");
  const [slugEdited, setSlugEdited] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  function handleNameChange(v: string) {
    setName(v);
    if (!slugEdited) setSlug(toSlug(v));
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");
    const res = await fetch("/api/categories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ name, slug }),
    });
    setSaving(false);
    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "Failed to create category");
      return;
    }
    setName("");
    setSlug("");
    setSlugEdited(false);
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="grid grid-cols-2 gap-3">
        <div className="space-y-1">
          <label className="text-xs text-parchment-dim">Name</label>
          <input
            value={name}
            onChange={(e) => handleNameChange(e.target.value)}
            placeholder="e.g. Mathematics"
            className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500"
            required
          />
        </div>
        <div className="space-y-1">
          <label className="text-xs text-parchment-dim">Slug (used in URL)</label>
          <input
            value={slug}
            onChange={(e) => { setSlug(e.target.value); setSlugEdited(true); }}
            placeholder="e.g. mathematics"
            className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment font-mono placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500"
            required
          />
        </div>
      </div>
      {error && <p className="text-red-400 text-sm">{error}</p>}
      <button
        type="submit"
        disabled={saving || !name.trim() || !slug.trim()}
        className="px-4 py-2 bg-gold-500 hover:bg-gold-400 disabled:opacity-50 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
      >
        {saving ? "Creating…" : "Create Category"}
      </button>
    </form>
  );
}
