"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { renameSection } from "@/lib/classes";

// Inline rename for a class section — click "edit" on the title, type, Save.
export default function SectionNameEditor({ sectionId, initialName }: { sectionId: string; initialName: string }) {
  const router = useRouter();
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(initialName);
  const [saving, setSaving] = useState(false);

  async function save() {
    const trimmed = name.trim();
    if (!trimmed || trimmed === initialName) {
      setEditing(false);
      setName(initialName);
      return;
    }
    setSaving(true);
    const fd = new FormData();
    fd.set("sectionId", sectionId);
    fd.set("name", trimmed);
    try {
      await renameSection(fd);
      setEditing(false);
      router.refresh();
    } catch {
      setName(initialName);
    } finally {
      setSaving(false);
    }
  }

  if (!editing) {
    return (
      <div className="flex items-center gap-3 mt-2">
        <h1 className="text-2xl font-bold text-parchment">{initialName}</h1>
        <button
          onClick={() => {
            setName(initialName);
            setEditing(true);
          }}
          className="text-xs text-parchment-dim hover:text-gold-300 transition-colors"
          title="Rename class"
        >
          ✎ edit
        </button>
      </div>
    );
  }

  return (
    <div className="flex items-center gap-2 mt-2">
      <input
        autoFocus
        value={name}
        onChange={(e) => setName(e.target.value)}
        onKeyDown={(e) => {
          if (e.key === "Enter") save();
          if (e.key === "Escape") {
            setEditing(false);
            setName(initialName);
          }
        }}
        className="text-xl font-bold bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-3 py-1.5 text-parchment"
      />
      <button
        onClick={save}
        disabled={saving}
        className="font-display text-xs tracking-[0.15em] uppercase bg-gold-600 hover:bg-gold-500 text-crimson-950 rounded px-3 py-1.5 font-semibold transition-colors disabled:opacity-50"
      >
        {saving ? "Saving…" : "Save"}
      </button>
      <button
        onClick={() => {
          setEditing(false);
          setName(initialName);
        }}
        className="text-xs text-parchment-dim hover:text-parchment transition-colors"
      >
        cancel
      </button>
    </div>
  );
}
