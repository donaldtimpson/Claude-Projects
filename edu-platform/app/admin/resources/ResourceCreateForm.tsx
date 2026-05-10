"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { ResourceKind } from "@prisma/client";
import { RESOURCE_KIND_OPTIONS } from "@/lib/resource-kinds";

export default function ResourceCreateForm() {
  const router = useRouter();
  const [title, setTitle] = useState("");
  const [url, setUrl] = useState("");
  const [kind, setKind] = useState<ResourceKind>("TEXTBOOK");
  const [description, setDescription] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");
    const res = await fetch("/api/resources", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, url, kind, description }),
    });
    setSaving(false);
    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "Failed to create resource");
      return;
    }
    setTitle("");
    setUrl("");
    setKind("TEXTBOOK");
    setDescription("");
    router.refresh();
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3">
      <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div className="space-y-1">
          <label className="text-xs text-parchment-dim">Title</label>
          <input
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            placeholder="e.g. Stewart Calculus 8th ed."
            className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500"
            required
          />
        </div>
        <div className="space-y-1">
          <label className="text-xs text-parchment-dim">Kind</label>
          <select
            value={kind}
            onChange={(e) => setKind(e.target.value as ResourceKind)}
            className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment focus:outline-none focus:border-gold-500"
          >
            {RESOURCE_KIND_OPTIONS.map((opt) => (
              <option key={opt.value} value={opt.value}>{opt.label}</option>
            ))}
          </select>
        </div>
      </div>
      <div className="space-y-1">
        <label className="text-xs text-parchment-dim">URL</label>
        <input
          value={url}
          onChange={(e) => setUrl(e.target.value)}
          placeholder="https://github.com/.../releases/download/textbooks-v1/calculus.pdf"
          className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment font-mono placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500"
          required
        />
      </div>
      <div className="space-y-1">
        <label className="text-xs text-parchment-dim">Description (optional)</label>
        <input
          value={description}
          onChange={(e) => setDescription(e.target.value)}
          placeholder="Short note shown under the title"
          className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500"
        />
      </div>
      {error && <p className="text-red-400 text-sm">{error}</p>}
      <button
        type="submit"
        disabled={saving || !title.trim() || !url.trim()}
        className="px-4 py-2 bg-gold-500 hover:bg-gold-400 disabled:opacity-50 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
      >
        {saving ? "Creating…" : "Create Resource"}
      </button>
    </form>
  );
}
