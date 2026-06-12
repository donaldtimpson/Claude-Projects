"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type Note = {
  id: string;
  content: string;
  isDraft: boolean;
};

export default function NotesEditor({
  videoId,
  initialNote,
}: {
  videoId: string;
  initialNote: Note | null;
}) {
  const router = useRouter();
  const [note, setNote] = useState<Note | null>(initialNote);
  const [content, setContent] = useState(initialNote?.content ?? "");
  const [open, setOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const dirty = content !== (note?.content ?? "");

  async function save() {
    if (!content.trim()) {
      setError("Notes are empty.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      const res = await fetch("/api/notes", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ videoId, content }),
      });
      if (!res.ok) throw new Error();
      setNote(await res.json());
      router.refresh();
    } catch {
      setError("Save failed. Try again.");
    } finally {
      setSaving(false);
    }
  }

  async function togglePublish() {
    if (!note) return;
    const res = await fetch(`/api/notes/${note.id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ isDraft: !note.isDraft }),
    });
    setNote(await res.json());
    router.refresh();
  }

  async function remove() {
    if (!note || !confirm("Delete these lecture notes?")) return;
    await fetch(`/api/notes/${note.id}`, { method: "DELETE" });
    setNote(null);
    setContent("");
    router.refresh();
  }

  const status = !note ? "None" : note.isDraft ? "Draft" : "Published";

  return (
    <div className="border border-crimson-700 rounded-xl overflow-hidden">
      <button
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className="w-full flex items-center justify-between gap-3 px-4 py-3 text-left hover:bg-crimson-800/40 transition-colors"
      >
        <span className="flex items-center gap-2">
          <svg
            className={`w-3 h-3 shrink-0 text-gold-400 transition-transform ${open ? "rotate-90" : ""}`}
            fill="currentColor"
            viewBox="0 0 20 20"
            aria-hidden="true"
          >
            <path d="M6 6l8 4-8 4V6z" />
          </svg>
          <span className="text-sm font-medium text-parchment">Lecture Notes</span>
        </span>
        <span
          className={`text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border ${
            status === "Published"
              ? "bg-green-900/30 border-green-700 text-green-300"
              : status === "Draft"
                ? "bg-amber-900/40 border-amber-700 text-amber-300"
                : "border-crimson-700 text-parchment-dim"
          }`}
        >
          {status}
        </span>
      </button>

      {open && (
        <div className="px-4 pb-4 space-y-3">
          <textarea
            value={content}
            onChange={(e) => setContent(e.target.value)}
            rows={14}
            placeholder="## Overview&#10;…&#10;&#10;## Key Concepts&#10;- **Term** — definition&#10;&#10;## Worked Example&#10;1. step&#10;&#10;## Summary&#10;- takeaway"
            className="w-full px-3 py-2 bg-crimson-800 border border-crimson-700 rounded-lg text-parchment text-sm font-mono leading-relaxed focus:outline-none focus:border-gold-500 resize-y"
          />
          {error && <p className="text-red-400 text-sm">{error}</p>}
          <div className="flex flex-wrap gap-3 items-center">
            <button
              onClick={save}
              disabled={saving || !dirty}
              className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors disabled:opacity-50"
            >
              {saving ? "Saving…" : note ? "Save Changes" : "Save Draft"}
            </button>
            {note && (
              <button
                onClick={togglePublish}
                className={note.isDraft ? "text-green-400 hover:text-green-300 text-sm" : "text-amber-400 hover:text-amber-300 text-sm"}
              >
                {note.isDraft ? "Publish" : "Unpublish"}
              </button>
            )}
            {note && (
              <button onClick={remove} className="text-red-400 hover:text-red-300 text-sm">
                Delete
              </button>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
