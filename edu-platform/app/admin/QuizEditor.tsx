"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";

type Question = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  position: number;
};

const EMPTY_FORM = {
  prompt: "",
  options: ["", "", "", ""],
  correctIndex: 0,
  explanation: "",
};

function getAdminPassword() {
  return document.cookie.match(/admin_auth=([^;]+)/)?.[1] ?? "";
}

export default function QuizEditor({
  initialQuestions,
  videoId,
  courseId,
}: {
  initialQuestions: Question[];
  videoId?: string;
  courseId?: string;
}) {
  const router = useRouter();
  const [questions, setQuestions] = useState<Question[]>(initialQuestions);
  const [form, setForm] = useState(EMPTY_FORM);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState("");

  function startEdit(q: Question) {
    setEditingId(q.id);
    setForm({
      prompt: q.prompt,
      options: q.options,
      correctIndex: q.correctIndex,
      explanation: q.explanation,
    });
  }

  function cancelEdit() {
    setEditingId(null);
    setForm(EMPTY_FORM);
    setError("");
  }

  async function save() {
    if (!form.prompt.trim() || form.options.some((o) => !o.trim())) {
      setError("Fill in the question and all 4 options.");
      return;
    }
    setSaving(true);
    setError("");
    try {
      const headers = {
        "Content-Type": "application/json",
        "x-admin-password": getAdminPassword(),
      };
      const body = { ...form, videoId, courseId, position: questions.length };

      if (editingId) {
        const res = await fetch(`/api/quiz/${editingId}`, {
          method: "PATCH",
          headers,
          body: JSON.stringify(form),
        });
        const updated = await res.json();
        setQuestions((qs) => qs.map((q) => (q.id === editingId ? updated : q)));
      } else {
        const res = await fetch("/api/quiz", { method: "POST", headers, body: JSON.stringify(body) });
        const created = await res.json();
        setQuestions((qs) => [...qs, created]);
      }
      cancelEdit();
      router.refresh();
    } catch {
      setError("Save failed. Try again.");
    } finally {
      setSaving(false);
    }
  }

  async function remove(id: string) {
    if (!confirm("Delete this question?")) return;
    await fetch(`/api/quiz/${id}`, {
      method: "DELETE",
      headers: { "x-admin-password": getAdminPassword() },
    });
    setQuestions((qs) => qs.filter((q) => q.id !== id));
    router.refresh();
  }

  return (
    <div className="space-y-6">
      {/* Question list */}
      {questions.length === 0 ? (
        <p className="text-slate-500 text-sm">No questions yet. Add one below.</p>
      ) : (
        <ol className="space-y-3">
          {questions.map((q, idx) => (
            <li key={q.id} className="bg-slate-800 border border-slate-700 rounded-xl p-4 space-y-2">
              <div className="flex justify-between gap-4">
                <p className="font-medium text-white">
                  <span className="text-slate-500 mr-2">{idx + 1}.</span>
                  {q.prompt}
                </p>
                <div className="flex gap-3 shrink-0 text-sm">
                  <button onClick={() => startEdit(q)} className="text-indigo-400 hover:text-indigo-300">
                    Edit
                  </button>
                  <button onClick={() => remove(q.id)} className="text-red-400 hover:text-red-300">
                    Delete
                  </button>
                </div>
              </div>
              <ol className="text-sm space-y-1 pl-4">
                {q.options.map((opt, i) => (
                  <li key={i} className={i === q.correctIndex ? "text-green-400" : "text-slate-400"}>
                    {String.fromCharCode(65 + i)}. {opt}
                    {i === q.correctIndex && " ✓"}
                  </li>
                ))}
              </ol>
              {q.explanation && <p className="text-xs text-slate-500 italic">{q.explanation}</p>}
            </li>
          ))}
        </ol>
      )}

      {/* Add / Edit form */}
      <div className="bg-slate-900 border border-slate-700 rounded-xl p-5 space-y-4">
        <h3 className="font-semibold text-white">{editingId ? "Edit Question" : "Add Question"}</h3>

        <div>
          <label className="text-xs text-slate-400 uppercase tracking-wider">Question</label>
          <textarea
            value={form.prompt}
            onChange={(e) => setForm((f) => ({ ...f, prompt: e.target.value }))}
            rows={2}
            className="mt-1 w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500 resize-none"
          />
        </div>

        <div className="space-y-2">
          <label className="text-xs text-slate-400 uppercase tracking-wider">Options</label>
          {form.options.map((opt, i) => (
            <div key={i} className="flex items-center gap-2">
              <input
                type="radio"
                name="correct"
                checked={form.correctIndex === i}
                onChange={() => setForm((f) => ({ ...f, correctIndex: i }))}
                className="accent-green-500"
              />
              <span className="text-slate-400 text-sm w-4">{String.fromCharCode(65 + i)}.</span>
              <input
                type="text"
                value={opt}
                placeholder={`Option ${String.fromCharCode(65 + i)}`}
                onChange={(e) => {
                  const opts = [...form.options];
                  opts[i] = e.target.value;
                  setForm((f) => ({ ...f, options: opts }));
                }}
                className="flex-1 px-3 py-1.5 bg-slate-800 border border-slate-700 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500"
              />
            </div>
          ))}
          <p className="text-xs text-slate-500">Select the radio button next to the correct answer.</p>
        </div>

        <div>
          <label className="text-xs text-slate-400 uppercase tracking-wider">Explanation (optional)</label>
          <textarea
            value={form.explanation}
            onChange={(e) => setForm((f) => ({ ...f, explanation: e.target.value }))}
            rows={2}
            placeholder="Shown after the student answers…"
            className="mt-1 w-full px-3 py-2 bg-slate-800 border border-slate-700 rounded-lg text-white text-sm focus:outline-none focus:border-indigo-500 resize-none"
          />
        </div>

        {error && <p className="text-red-400 text-sm">{error}</p>}

        <div className="flex gap-3">
          <button
            onClick={save}
            disabled={saving}
            className="px-4 py-2 bg-indigo-600 hover:bg-indigo-500 text-white text-sm font-medium rounded-lg transition-colors disabled:opacity-50"
          >
            {saving ? "Saving…" : editingId ? "Save Changes" : "Add Question"}
          </button>
          {editingId && (
            <button onClick={cancelEdit} className="px-4 py-2 text-slate-400 hover:text-white text-sm transition-colors">
              Cancel
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
