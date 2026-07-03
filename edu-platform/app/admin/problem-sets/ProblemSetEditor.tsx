"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import MarkdownNotes from "@/components/MarkdownNotes";
import { updateProblemSet, setProblemSetDraft, deleteProblemSet } from "@/lib/assignments";

type PS = {
  id: string;
  title: string;
  body: string;
  solution: string;
  attachmentUrl: string | null;
  isDraft: boolean;
};

function Pane({
  label,
  value,
  onChange,
  placeholder,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder: string;
}) {
  const [mode, setMode] = useState<"edit" | "preview">("edit");
  return (
    <div className="space-y-2">
      <div className="flex items-center justify-between">
        <span className="font-display text-xs tracking-[0.15em] uppercase text-gold-400">{label}</span>
        <div className="flex gap-1 text-xs">
          {(["edit", "preview"] as const).map((m) => (
            <button
              key={m}
              type="button"
              onClick={() => setMode(m)}
              className={`px-3 py-1 rounded-t-lg border-b-2 capitalize transition-colors ${
                mode === m ? "border-gold-500 text-parchment" : "border-transparent text-parchment-dim hover:text-parchment"
              }`}
            >
              {m}
            </button>
          ))}
        </div>
      </div>
      {mode === "edit" ? (
        <textarea
          value={value}
          onChange={(e) => onChange(e.target.value)}
          rows={14}
          placeholder={placeholder}
          className="w-full px-3 py-2 bg-crimson-950 border border-crimson-700 rounded-lg text-parchment text-sm font-mono leading-relaxed focus:outline-none focus:border-gold-500 resize-y"
        />
      ) : (
        <div className="px-4 py-3 bg-crimson-900 border border-crimson-700 rounded-lg min-h-[8rem]">
          {value.trim() ? <MarkdownNotes content={value} /> : <p className="text-parchment-dim text-sm">Nothing to preview yet.</p>}
        </div>
      )}
    </div>
  );
}

export default function ProblemSetEditor({ ps, courseId }: { ps: PS; courseId: string }) {
  const router = useRouter();
  const [title, setTitle] = useState(ps.title);
  const [body, setBody] = useState(ps.body);
  const [solution, setSolution] = useState(ps.solution);
  const [attachmentUrl, setAttachmentUrl] = useState(ps.attachmentUrl ?? "");
  const [isDraft, setIsDraft] = useState(ps.isDraft);
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  async function save() {
    setSaving(true);
    setSaved(false);
    const fd = new FormData();
    fd.set("id", ps.id);
    fd.set("title", title);
    fd.set("body", body);
    fd.set("solution", solution);
    fd.set("attachmentUrl", attachmentUrl);
    await updateProblemSet(fd);
    setSaving(false);
    setSaved(true);
    router.refresh();
  }

  async function togglePublish() {
    const next = !isDraft;
    const fd = new FormData();
    fd.set("id", ps.id);
    fd.set("isDraft", String(next));
    await setProblemSetDraft(fd);
    setIsDraft(next);
    router.refresh();
  }

  async function remove() {
    if (!confirm("Delete this problem set? Any assignments using it are removed too.")) return;
    const fd = new FormData();
    fd.set("id", ps.id);
    await deleteProblemSet(fd);
    router.push("/admin/problem-sets");
  }

  return (
    <div className="space-y-5">
      <div className="flex items-center gap-3 flex-wrap">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          className="flex-1 min-w-[16rem] bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2.5 text-parchment text-lg font-semibold transition-colors"
        />
        <span
          className={`text-[10px] uppercase tracking-wider px-2 py-1 rounded border ${
            isDraft ? "bg-amber-900/40 border-amber-700 text-amber-300" : "bg-green-900/30 border-green-700 text-green-300"
          }`}
        >
          {isDraft ? "Draft" : "Published"}
        </span>
      </div>

      <Pane
        label="Problems (public)"
        value={body}
        onChange={setBody}
        placeholder="**1.** (2 pts ••) …  — Markdown + $…$ / $$…$$ math"
      />

      <Pane
        label="Solutions (instructor / released per assignment)"
        value={solution}
        onChange={setSolution}
        placeholder="Worked solutions — Markdown + math. Students see these only when you release them for their class."
      />

      <input
        value={attachmentUrl}
        onChange={(e) => setAttachmentUrl(e.target.value)}
        placeholder="Optional attachment URL (e.g. a hosted PDF)"
        className="w-full bg-crimson-950 border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2 text-parchment text-sm placeholder:text-parchment-dim/60 transition-colors"
      />

      <div className="flex flex-wrap items-center gap-4 pt-2 border-t border-crimson-800">
        <button
          onClick={save}
          disabled={saving}
          className="px-4 py-2 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm font-medium rounded-lg transition-colors disabled:opacity-50"
        >
          {saving ? "Saving…" : "Save changes"}
        </button>
        {saved && !saving && <span className="text-green-400 text-sm">Saved ✓</span>}
        <button
          onClick={togglePublish}
          className={isDraft ? "text-green-400 hover:text-green-300 text-sm" : "text-amber-400 hover:text-amber-300 text-sm"}
        >
          {isDraft ? "Publish" : "Unpublish"}
        </button>
        <a
          href={`/courses/${courseId}/problems/${ps.id}`}
          target="_blank"
          rel="noopener noreferrer"
          className="text-parchment-dim hover:text-gold-300 text-sm"
        >
          View public page ↗
        </a>
        <button onClick={remove} className="text-red-400 hover:text-red-300 text-sm ml-auto">
          Delete
        </button>
      </div>
    </div>
  );
}
