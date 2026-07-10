"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type CourseOption = { id: string; title: string };

export default function AnnouncementCreateForm({ courses }: { courses: CourseOption[] }) {
  const router = useRouter();
  const [title, setTitle] = useState("");
  const [body, setBody] = useState("");
  const [courseId, setCourseId] = useState("");
  const [pinned, setPinned] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSaving(true);
    setError("");
    const res = await fetch("/api/announcements", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title, body, courseId: courseId || null, pinned }),
    });
    setSaving(false);
    if (!res.ok) {
      const data = await res.json();
      setError(data.error ?? "Failed to create announcement");
      return;
    }
    setTitle("");
    setBody("");
    setCourseId("");
    setPinned(false);
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
            placeholder="e.g. Class canceled tonight"
            className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500"
            required
          />
        </div>
        <div className="space-y-1">
          <label className="text-xs text-parchment-dim">Scope</label>
          <select
            value={courseId}
            onChange={(e) => setCourseId(e.target.value)}
            className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment focus:outline-none focus:border-gold-500"
          >
            <option value="">Site-wide</option>
            {courses.map((c) => (
              <option key={c.id} value={c.id}>{c.title}</option>
            ))}
          </select>
        </div>
      </div>
      <div className="space-y-1">
        <label className="text-xs text-parchment-dim">Message (optional)</label>
        <textarea
          value={body}
          onChange={(e) => setBody(e.target.value)}
          rows={3}
          placeholder="Optional details shown below the title"
          className="w-full bg-crimson-800 border border-crimson-700 rounded-lg px-3 py-2 text-sm text-parchment placeholder:text-parchment-dim/50 focus:outline-none focus:border-gold-500 resize-y"
        />
      </div>
      <label className="flex items-center gap-2 text-sm text-parchment-dim cursor-pointer select-none">
        <input
          type="checkbox"
          checked={pinned}
          onChange={(e) => setPinned(e.target.checked)}
          className="accent-gold-500"
        />
        Pin to top
      </label>
      {error && <p className="text-red-400 text-sm">{error}</p>}
      <button
        type="submit"
        disabled={saving || !title.trim()}
        className="px-4 py-2 bg-gold-500 hover:bg-gold-400 disabled:opacity-50 text-crimson-950 text-sm font-medium rounded-lg transition-colors"
      >
        {saving ? "Posting…" : "Post Announcement"}
      </button>
    </form>
  );
}
