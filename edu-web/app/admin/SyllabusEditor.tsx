"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import MarkdownNotes from "@/components/MarkdownNotes";

// Course-level syllabus editor for the admin course hub. Mirrors NotesEditor's
// edit/preview pattern, but the syllabus is a plain string on Course (no draft
// gate): it shows on the course page whenever it's non-empty.
export default function SyllabusEditor({
  courseId,
  initialSyllabus,
}: {
  courseId: string;
  initialSyllabus: string;
}) {
  const router = useRouter();
  const [saved, setSaved] = useState(initialSyllabus);
  const [content, setContent] = useState(initialSyllabus);
  const [open, setOpen] = useState(false);
  const [mode, setMode] = useState<"edit" | "preview">("edit");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  const dirty = content !== saved;
  const status = saved.trim() ? "Set" : "None";

  async function save() {
    setSaving(true);
    setError("");
    try {
      const res = await fetch(`/api/courses/${courseId}/syllabus`, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ syllabus: content }),
      });
      if (!res.ok) throw new Error();
      const data = await res.json();
      setSaved(data.syllabus ?? content);
      router.refresh();
    } catch {
      setError("Save failed. Try again.");
    } finally {
      setSaving(false);
    }
  }

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
          <span className="text-sm font-medium text-parchment">Syllabus</span>
        </span>
        <span
          className={`text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border ${
            status === "Set"
              ? "bg-green-900/30 border-green-700 text-green-300"
              : "border-crimson-700 text-parchment-dim"
          }`}
        >
          {status}
        </span>
      </button>

      {open && (
        <div className="px-4 pb-4 space-y-3">
          <div className="flex gap-1 text-xs">
            {(["edit", "preview"] as const).map((m) => (
              <button
                key={m}
                onClick={() => setMode(m)}
                className={`px-3 py-1.5 rounded-t-lg border-b-2 transition-colors capitalize ${
                  mode === m
                    ? "border-gold-500 text-parchment"
                    : "border-transparent text-parchment-dim hover:text-parchment"
                }`}
              >
                {m}
              </button>
            ))}
          </div>

          {mode === "edit" ? (
            <textarea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              rows={18}
              placeholder="## Course Syllabus&#10;&#10;### Grading&#10;| Category | Weight |&#10;| :--- | ---: |&#10;| … | … |&#10;&#10;### Schedule&#10;…"
              className="w-full px-3 py-2 bg-crimson-800 border border-crimson-700 rounded-lg text-parchment text-sm font-mono leading-relaxed focus:outline-none focus:border-gold-500 resize-y"
            />
          ) : (
            <div className="px-4 py-3 bg-crimson-900 border border-crimson-700 rounded-lg min-h-[8rem]">
              {content.trim() ? (
                <MarkdownNotes content={content} />
              ) : (
                <p className="text-parchment-dim text-sm">Nothing to preview yet.</p>
              )}
            </div>
          )}
          {error && <p className="text-red-400 text-sm">{error}</p>}
          <div className="flex flex-wrap gap-3 items-center">
            <button
              onClick={save}
              disabled={saving || !dirty}
              className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors disabled:opacity-50"
            >
              {saving ? "Saving…" : "Save Syllabus"}
            </button>
            {saved.trim() && (
              <a
                href={`/courses/${courseId}/syllabus`}
                target="_blank"
                rel="noopener noreferrer"
                className="text-parchment-dim hover:text-gold-300 text-sm ml-auto"
              >
                PDF view ↗
              </a>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
