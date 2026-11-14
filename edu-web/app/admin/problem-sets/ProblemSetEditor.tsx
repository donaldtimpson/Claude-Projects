"use client";

import { useCallback, useEffect, useLayoutEffect, useMemo, useRef, useState, useSyncExternalStore } from "react";
import { useRouter } from "next/navigation";
import MarkdownNotes from "@/components/MarkdownNotes";
import ProblemSetView from "@/components/ProblemSetView";
import {
  updateProblemSet,
  setProblemSetDraft,
  deleteProblemSet,
  toggleSolutionsPublic,
  setProblemSetVideos,
} from "@/lib/assignments";
import {
  insertChunk,
  pairProblemSet,
  replaceChunk,
  reviewProblemSet,
  type ReviewRow,
} from "@/lib/problem-sets";

// The problem-set editor. Its default view is Review: every problem beside its
// worked solution, one row each, because the job here is checking that each
// answer is right, and that's a side-by-side comparison. A row edits in place.
// Source is the raw Markdown for structural edits; Student view is exactly what
// a student will get.

type PS = {
  id: string;
  title: string;
  body: string;
  solution: string;
  attachmentUrl: string | null;
  isDraft: boolean;
  points: number;
  extraCreditPoints: number;
  solutionsPublic: boolean;
  videoIds: string[];
};

export type LectureOption = { id: string; title: string; position: number };
export type SiblingSet = { id: string; title: string } | null;
export type EditorMode = "review" | "source" | "student";

const MODES: { id: EditorMode; label: string }[] = [
  { id: "review", label: "Review" },
  { id: "source", label: "Source" },
  { id: "student", label: "Student view" },
];

// ── "Checked" marks ───────────────────────────────────────────────────────────
// Per device (localStorage). Each mark stores a hash of the row's problem and
// solution, so editing either one quietly clears it.

const CHECKED_EVENT = "ps-checked-change";
const checkedKey = (psId: string) => `ps-checked:${psId}`;

function hash(s: string): string {
  let h = 5381;
  for (let i = 0; i < s.length; i++) h = ((h << 5) + h + s.charCodeAt(i)) | 0;
  return (h >>> 0).toString(36);
}

const rowHash = (row: ReviewRow) => hash(`${row.problem?.content ?? ""}\u0000${row.solution?.content ?? ""}`);
const rowKey = (row: ReviewRow) => (row.problem ? row.problem.key : `orphan:${row.solution?.key}`);

function readChecked(psId: string): string | null {
  try {
    return localStorage.getItem(checkedKey(psId));
  } catch {
    return null;
  }
}

function useCheckedMarks(psId: string) {
  const raw = useSyncExternalStore(
    (cb) => {
      window.addEventListener("storage", cb);
      window.addEventListener(CHECKED_EVENT, cb);
      return () => {
        window.removeEventListener("storage", cb);
        window.removeEventListener(CHECKED_EVENT, cb);
      };
    },
    () => readChecked(psId),
    () => null,
  );
  const marks = useMemo<Record<string, string>>(() => {
    try {
      return raw ? JSON.parse(raw) : {};
    } catch {
      return {};
    }
  }, [raw]);
  const setMark = useCallback(
    (key: string, value: string | null) => {
      const next = { ...marks };
      if (value) next[key] = value;
      else delete next[key];
      try {
        localStorage.setItem(checkedKey(psId), JSON.stringify(next));
      } catch {}
      window.dispatchEvent(new Event(CHECKED_EVENT));
    },
    [marks, psId],
  );
  return { marks, setMark };
}

// ── Small pieces ──────────────────────────────────────────────────────────────

function AutoTextarea({
  value,
  onChange,
  placeholder,
  autoFocus,
  minRows = 4,
}: {
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  autoFocus?: boolean;
  minRows?: number;
}) {
  const ref = useRef<HTMLTextAreaElement>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    el.style.height = "auto";
    el.style.height = `${el.scrollHeight + 2}px`;
  }, [value]);
  return (
    <textarea
      ref={ref}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      placeholder={placeholder}
      autoFocus={autoFocus}
      rows={minRows}
      spellCheck={false}
      className="w-full px-3 py-2 bg-field border border-crimson-700 rounded-lg text-parchment text-sm font-mono leading-relaxed focus:outline-none focus:border-gold-500 resize-none overflow-hidden"
    />
  );
}

function Flag({ tone, children }: { tone: "warn" | "muted"; children: React.ReactNode }) {
  return (
    <span
      className={`text-xs font-medium rounded px-2 py-0.5 border ${
        tone === "warn"
          ? "bg-amber-900/40 border-amber-700 text-amber-300"
          : "bg-crimson-800 border-crimson-700 text-parchment-dim"
      }`}
    >
      {children}
    </span>
  );
}

function Rendered({ md, empty }: { md: string; empty: string }) {
  return md.trim() ? (
    <MarkdownNotes content={md} />
  ) : (
    <p className="py-4 text-sm italic text-parchment-dim">{empty}</p>
  );
}

// ── One problem + solution row ────────────────────────────────────────────────

type Draft = { rowId: string; problem: string; solution: string };

function ReviewRowCard({
  row,
  checked,
  onToggleChecked,
  draft,
  onStartEdit,
  onDraftChange,
  onApply,
  onCancel,
}: {
  row: ReviewRow;
  checked: boolean;
  onToggleChecked: () => void;
  draft: Draft | null;
  onStartEdit: () => void;
  onDraftChange: (d: Draft) => void;
  onApply: () => void;
  onCancel: () => void;
}) {
  const editing = draft !== null;
  const problemLabel = row.problem ? (row.problem.kind === "item" ? `Problem ${row.label}` : row.label) : `Solution ${row.label}`;

  return (
    <li
      id={`row-${row.id}`}
      data-row-id={row.id}
      onKeyDown={(e) => {
        if (!editing) return;
        if (e.key === "Escape") onCancel();
        if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
          e.preventDefault();
          onApply();
        }
      }}
      className={`scroll-mt-4 bg-crimson-900 border rounded-xl shadow-card ${
        editing ? "border-gold-500 ring-1 ring-gold-500" : checked ? "border-green-700" : "border-crimson-700"
      }`}
    >
      {/* Stays at the top of the screen while the row scrolls, so the check
          button is at hand when you reach the end of a long solution. */}
      <div className="sticky top-0 z-[5] flex items-center gap-3 flex-wrap px-5 py-1.5 border-b border-crimson-700 bg-crimson-800 rounded-t-xl">
        <span className="font-ui font-semibold text-sm text-parchment">{problemLabel}</span>
        {!row.problem && <Flag tone="warn">No problem with this number</Flag>}
        {row.problem && !row.solution && <Flag tone="muted">No solution</Flag>}
        {row.duplicate && <Flag tone="warn">Number used twice</Flag>}
        <div className="ml-auto flex items-center gap-4">
          {editing ? (
            <>
              <button
                type="button"
                onClick={onCancel}
                title="Esc"
                className="font-ui font-semibold text-sm text-parchment-dim hover:text-parchment transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={onApply}
                title="⌘Enter"
                className="font-ui font-semibold px-3 py-1 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm rounded-lg transition-colors"
              >
                Save
              </button>
            </>
          ) : (
            <>
              <button
                type="button"
                onClick={onStartEdit}
                className="font-ui font-semibold text-sm text-gold-400 hover:text-gold-300 transition-colors"
              >
                Edit
              </button>
              <button
                type="button"
                onClick={onToggleChecked}
                aria-pressed={checked}
                className={`font-ui font-semibold text-sm rounded-lg px-3 py-1 border transition-colors ${
                  checked
                    ? "bg-green-900 border-green-700 text-green-300"
                    : "bg-transparent border-crimson-600 text-parchment-dim hover:border-green-600 hover:text-parchment"
                }`}
              >
                {checked ? "✓ Checked" : "Mark checked"}
              </button>
            </>
          )}
        </div>
      </div>

      <div className="grid lg:grid-cols-2">
        {/* The problem stays in view while a long solution scrolls past it. */}
        <div className="min-w-0 px-5 py-2 lg:border-r border-crimson-700">
          <div className={editing ? "" : "lg:sticky lg:top-14 lg:max-h-[calc(100vh-8rem)] lg:overflow-y-auto"}>
            {editing && draft && row.problem ? (
              <div className="py-3 space-y-3">
                <AutoTextarea value={draft.problem} onChange={(v) => onDraftChange({ ...draft, problem: v })} autoFocus />
                <div className="border-t border-dashed border-crimson-700">
                  <Rendered md={draft.problem} empty="Empty. Saving will remove this problem." />
                </div>
              </div>
            ) : row.problem ? (
              <MarkdownNotes content={row.problem.content} />
            ) : (
              <p className="py-4 text-sm text-parchment-dim">
                No problem is numbered {row.label}. Check this solution&apos;s number. Until it matches a
                problem, students see all the solutions as one block below the problems.
              </p>
            )}
          </div>
        </div>

        <div className="min-w-0 px-5 py-2 border-t lg:border-t-0 border-crimson-700">
          <p className="eyebrow text-parchment-dim pt-3 lg:hidden">Solution</p>
          {editing && draft ? (
            <div className="py-3 space-y-3">
              <AutoTextarea
                value={draft.solution}
                onChange={(v) => onDraftChange({ ...draft, solution: v })}
                autoFocus={!row.problem}
                placeholder="Worked solution. Markdown + $…$ math."
              />
              <div className="border-t border-dashed border-crimson-700">
                <Rendered md={draft.solution} empty="No solution yet." />
              </div>
            </div>
          ) : row.solution ? (
            <MarkdownNotes content={row.solution.content} />
          ) : (
            <p className="py-4 text-sm italic text-parchment-dim">
              No solution yet.{" "}
              <button
                type="button"
                onClick={onStartEdit}
                className="not-italic font-ui font-semibold text-gold-400 hover:text-gold-300"
              >
                Write one
              </button>
            </p>
          )}
        </div>
      </div>
    </li>
  );
}

// A solution's leading tag, so a new one attaches to its problem.
function solutionStub(row: ReviewRow): string {
  if (!row.problem) return "";
  return row.problem.kind === "item" ? `**${row.problem.n}.** ` : `### ${row.label}\n\n`;
}

// ── The editor ────────────────────────────────────────────────────────────────

export default function ProblemSetEditor({
  ps,
  courseId,
  lectures,
  initialMode = "review",
  prev,
  next,
}: {
  ps: PS;
  courseId: string;
  lectures: LectureOption[];
  initialMode?: EditorMode;
  prev: SiblingSet;
  next: SiblingSet;
}) {
  const router = useRouter();
  const [mode, setModeState] = useState<EditorMode>(initialMode);
  const [title, setTitle] = useState(ps.title);
  const [body, setBody] = useState(ps.body);
  const [solution, setSolution] = useState(ps.solution);
  const [attachmentUrl, setAttachmentUrl] = useState(ps.attachmentUrl ?? "");
  const [points, setPoints] = useState(ps.points);
  const [extraCredit, setExtraCredit] = useState(ps.extraCreditPoints);
  const [isDraft, setIsDraft] = useState(ps.isDraft);
  const [solutionsPublic, setSolutionsPublic] = useState(ps.solutionsPublic);
  const [videoIds, setVideoIds] = useState<string[]>(ps.videoIds);
  const [draft, setDraft] = useState<Draft | null>(null);
  const [saving, setSaving] = useState(false);
  const [justSaved, setJustSaved] = useState(false);
  const [saveError, setSaveError] = useState(false);

  // What's on the server, to tell whether anything is unsaved.
  const [savedState, setSavedState] = useState({
    title: ps.title,
    body: ps.body,
    solution: ps.solution,
    attachmentUrl: ps.attachmentUrl ?? "",
    points: ps.points,
    extraCredit: ps.extraCreditPoints,
  });
  const review = useMemo(() => reviewProblemSet(body, solution), [body, solution]);
  const draftRow = draft ? review.rows.find((r) => r.id === draft.rowId) : undefined;
  const draftChanged =
    !!draft &&
    !!draftRow &&
    (draft.problem !== (draftRow.problem?.content ?? "") ||
      draft.solution !== (draftRow.solution?.content ?? solutionStub(draftRow)));
  const dirty =
    draftChanged ||
    title !== savedState.title ||
    body !== savedState.body ||
    solution !== savedState.solution ||
    attachmentUrl !== savedState.attachmentUrl ||
    points !== savedState.points ||
    extraCredit !== savedState.extraCredit;

  const { marks, setMark } = useCheckedMarks(ps.id);
  const isChecked = (row: ReviewRow) => marks[rowKey(row)] === rowHash(row);
  const checkedCount = review.rows.filter(isChecked).length;
  const mismatched = review.rows.filter((r) => !r.problem || r.duplicate);
  const unsolved = review.rows.filter((r) => r.problem && !r.solution);

  function setMode(m: EditorMode) {
    applyDraft();
    setModeState(m);
    const url = new URL(window.location.href);
    if (m === "review") url.searchParams.delete("mode");
    else url.searchParams.set("mode", m);
    window.history.replaceState(null, "", url);
  }

  // Splice a row's edited text back into the two documents.
  function applyDraft(): { body: string; solution: string } {
    if (!draft) return { body, solution };
    const row = review.rows.find((r) => r.id === draft.rowId);
    let nextBody = body;
    let nextSolution = solution;
    if (row) {
      if (row.problem && draft.problem !== row.problem.content) {
        nextBody = replaceChunk(body, row.problem, draft.problem);
      }
      if (row.solution) {
        if (draft.solution !== row.solution.content) {
          nextSolution = replaceChunk(solution, row.solution, draft.solution);
        }
      } else if (draft.solution.trim() && draft.solution.trim() !== solutionStub(row).trim()) {
        // A new solution goes before the next problem's solution, in problem order.
        const idx = review.rows.indexOf(row);
        const before = review.rows.slice(idx + 1).find((r) => r.problem && r.solution)?.solution ?? null;
        nextSolution = insertChunk(solution, before, draft.solution);
      }
    }
    setBody(nextBody);
    setSolution(nextSolution);
    setDraft(null);
    return { body: nextBody, solution: nextSolution };
  }

  async function save(): Promise<boolean> {
    if (saving) return false;
    const docs = applyDraft();
    setSaving(true);
    setSaveError(false);
    const fd = new FormData();
    fd.set("id", ps.id);
    fd.set("title", title);
    fd.set("body", docs.body);
    fd.set("solution", docs.solution);
    fd.set("attachmentUrl", attachmentUrl);
    fd.set("points", String(points));
    fd.set("extraCreditPoints", String(extraCredit));
    try {
      await updateProblemSet(fd);
    } catch {
      setSaving(false);
      setSaveError(true);
      return false;
    }
    setSavedState({ title, body: docs.body, solution: docs.solution, attachmentUrl, points, extraCredit });
    setSaving(false);
    setJustSaved(true);
    router.refresh();
    return true;
  }

  function discard() {
    if (!confirm("Discard your unsaved changes?")) return;
    setDraft(null);
    setTitle(savedState.title);
    setBody(savedState.body);
    setSolution(savedState.solution);
    setAttachmentUrl(savedState.attachmentUrl);
    setPoints(savedState.points);
    setExtraCredit(savedState.extraCredit);
  }

  // ⌘S / Ctrl+S saves; leaving with unsaved work asks first.
  const saveRef = useRef(save);
  useEffect(() => {
    saveRef.current = save;
  });
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "s") {
        e.preventDefault();
        void saveRef.current();
      }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);
  useEffect(() => {
    if (!dirty) return;
    const onLeave = (e: BeforeUnloadEvent) => e.preventDefault();
    window.addEventListener("beforeunload", onLeave);
    return () => window.removeEventListener("beforeunload", onLeave);
  }, [dirty]);

  // Paging to another set saves first (after asking), so a fix is never lost
  // to a quick press of "next".
  async function go(target: SiblingSet) {
    if (!target) return;
    if (dirty) {
      if (!confirm(`Save your changes and go to ${target.title}?`)) return;
      if (!(await save())) return;
    }
    router.push(`/admin/problem-sets/${target.id}${mode === "review" ? "" : `?mode=${mode}`}`);
  }

  // C checks the row at the top of the screen and scrolls to the next unchecked
  // one; [ and ] page between sets. Ignored while typing.
  const keysRef = useRef<(e: KeyboardEvent) => void>(() => {});
  useEffect(() => {
    keysRef.current = (e: KeyboardEvent) => {
      const t = e.target as HTMLElement;
      if (e.metaKey || e.ctrlKey || e.altKey || t.closest("input, textarea, select, [contenteditable]")) return;
      if (e.key === "[") void go(prev);
      else if (e.key === "]") void go(next);
      else if (e.key.toLowerCase() === "c" && mode === "review") {
        const els = [...document.querySelectorAll<HTMLElement>("[data-row-id]")];
        const current = els.find((el) => el.getBoundingClientRect().bottom > 120);
        const row = review.rows.find((r) => r.id === current?.dataset.rowId);
        if (!row || !current) return;
        if (!isChecked(row)) setMark(rowKey(row), rowHash(row));
        const after = review.rows.slice(review.rows.indexOf(row) + 1).find((r) => !isChecked(r));
        if (after) document.getElementById(`row-${after.id}`)?.scrollIntoView({ behavior: "smooth", block: "start" });
      }
    };
  });
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => keysRef.current(e);
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, []);

  async function toggleSolutions() {
    const nextVal = !solutionsPublic;
    setSolutionsPublic(nextVal);
    const fd = new FormData();
    fd.set("id", ps.id);
    await toggleSolutionsPublic(fd);
    router.refresh();
  }

  async function toggleLecture(videoId: string) {
    const nextIds = videoIds.includes(videoId) ? videoIds.filter((v) => v !== videoId) : [...videoIds, videoId];
    setVideoIds(nextIds);
    const fd = new FormData();
    fd.set("id", ps.id);
    for (const v of nextIds) fd.append("videoId", v);
    await setProblemSetVideos(fd);
    router.refresh();
  }

  async function togglePublish() {
    const nextVal = !isDraft;
    if (dirty && !(await save())) return;
    const fd = new FormData();
    fd.set("id", ps.id);
    fd.set("isDraft", String(nextVal));
    await setProblemSetDraft(fd);
    setIsDraft(nextVal);
    router.refresh();
  }

  async function remove() {
    if (!confirm("Delete this problem set? Any assignments using it are removed too.")) return;
    const fd = new FormData();
    fd.set("id", ps.id);
    await deleteProblemSet(fd);
    router.push(`/admin/courses/${courseId}/problem-sets`);
  }

  const navBtn =
    "font-ui font-semibold text-sm text-parchment-dim hover:text-parchment rounded-lg px-2 py-1.5 transition-colors truncate max-w-[14rem]";

  const numberInput =
    "w-20 bg-field border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-2 py-1.5 text-parchment transition-colors";

  return (
    <div className="space-y-6">

      {/* Title + status */}
      <div className="flex items-center gap-3 flex-wrap">
        <input
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          aria-label="Title"
          className="flex-1 min-w-[16rem] -ml-3 bg-transparent border border-transparent hover:border-crimson-700 focus:bg-field focus:border-gold-500 outline-none rounded-lg px-3 py-1.5 text-parchment text-2xl font-bold transition-colors"
        />
        <span
          className={`font-ui font-semibold text-xs uppercase tracking-[0.06em] px-2 py-1 rounded border ${
            isDraft ? "bg-amber-900/40 border-amber-700 text-amber-300" : "bg-green-900/30 border-green-700 text-green-300"
          }`}
        >
          {isDraft ? "Draft" : "Published"}
        </span>
        <button
          type="button"
          onClick={togglePublish}
          className={`font-ui font-semibold px-4 py-2 text-sm rounded-lg transition-colors ${
            isDraft
              ? "bg-gold-500 hover:bg-gold-400 text-crimson-950"
              : "bg-btn hover:bg-btn-hover border border-crimson-700 text-parchment"
          }`}
        >
          {isDraft ? "Publish" : "Unpublish"}
        </button>
        {!isDraft && (
          <a
            href={`/courses/${courseId}/problems/${ps.id}`}
            target="_blank"
            rel="noopener noreferrer"
            className="font-ui font-semibold text-sm text-gold-400 hover:text-gold-300"
          >
            Public page ↗
          </a>
        )}
      </div>

      {/* Mode tabs + review progress */}
      <div className="flex items-end justify-between gap-4 flex-wrap border-b border-crimson-700">
        <div role="tablist" className="flex gap-1">
          {MODES.map((m) => (
            <button
              key={m.id}
              type="button"
              role="tab"
              aria-selected={mode === m.id}
              onClick={() => setMode(m.id)}
              className={`font-ui font-semibold text-sm px-4 py-2 -mb-px border-b-2 transition-colors ${
                mode === m.id
                  ? "border-gold-500 text-parchment"
                  : "border-transparent text-parchment-dim hover:text-parchment"
              }`}
            >
              {m.label}
            </button>
          ))}
        </div>
        {mode === "review" && review.rows.length > 0 && (
          <div className="flex items-center gap-3 pb-2">
            <span className="hidden xl:inline text-xs text-parchment-dim">
              <kbd className="font-ui font-semibold">C</kbd> check &amp; next ·{" "}
              <kbd className="font-ui font-semibold">[ ]</kbd> sets
            </span>
            <span className="font-ui text-sm text-parchment-dim tabular-nums">
              {checkedCount} of {review.rows.length} checked
            </span>
            <div className="w-28 h-1.5 rounded-full bg-crimson-800 overflow-hidden" aria-hidden="true">
              <div
                className="h-full bg-green-500 transition-[width]"
                style={{ width: `${(checkedCount / review.rows.length) * 100}%` }}
              />
            </div>
          </div>
        )}
      </div>

      {mode === "review" && (
        <section className="space-y-5">
          {(mismatched.length > 0 || !review.pairsPublicly) && review.rows.length > 0 && (
            <div className="rounded-lg border border-amber-700 bg-amber-900/30 px-4 py-3 text-sm text-parchment">
              <p className="font-semibold text-amber-300">The solutions don&apos;t line up with the problems.</p>
              <p className="mt-1 text-parchment-dim">
                Students will see every solution in one block under the problems until each solution&apos;s number
                matches exactly one problem. The flagged rows below are the ones to fix.
              </p>
            </div>
          )}

          {review.rows.length === 0 ? (
            <div className="rounded-xl border border-crimson-700 bg-crimson-900 px-5 py-6 space-y-3">
              <p className="text-parchment">
                There are no numbered problems to pair yet. Number each one <code>**1.**</code>,{" "}
                <code>**2.**</code> … in{" "}
                <button type="button" onClick={() => setMode("source")} className="font-ui font-semibold text-gold-400 hover:text-gold-300">
                  Source
                </button>{" "}
                and its solution with the same number.
              </p>
              {(body.trim() || solution.trim()) && (
                <div className="grid lg:grid-cols-2 gap-6 pt-3 border-t border-crimson-700">
                  <Rendered md={body} empty="No problems yet." />
                  <Rendered md={solution} empty="No solutions yet." />
                </div>
              )}
            </div>
          ) : (
            <>
              {review.problemsPreamble && (
                <div className="px-5 text-parchment-dim">
                  <MarkdownNotes content={review.problemsPreamble} />
                </div>
              )}
              <ol className="space-y-5 list-none p-0 m-0">
                {review.rows.map((row) => (
                  <ReviewRowCard
                    key={row.id}
                    row={row}
                    checked={isChecked(row)}
                    onToggleChecked={() => setMark(rowKey(row), isChecked(row) ? null : rowHash(row))}
                    draft={draft?.rowId === row.id ? draft : null}
                    onStartEdit={() => {
                      if (draft && draft.rowId !== row.id) applyDraft();
                      setDraft({
                        rowId: row.id,
                        problem: row.problem?.content ?? "",
                        solution: row.solution?.content ?? solutionStub(row),
                      });
                    }}
                    onDraftChange={setDraft}
                    onApply={() => void save()}
                    onCancel={() => setDraft(null)}
                  />
                ))}
              </ol>
              {unsolved.length > 0 && (
                <p className="text-sm text-parchment-dim px-1">
                  {unsolved.length === 1 ? "One problem has" : `${unsolved.length} problems have`} no solution.
                  Students just won&apos;t get a reveal button for {unsolved.length === 1 ? "it" : "those"}.
                </p>
              )}
            </>
          )}
        </section>
      )}

      {mode === "source" && (
        <section className="grid lg:grid-cols-2 gap-5">
          {(
            [
              ["Problems", body, setBody, "**1.** (2 pts) …  Markdown + $…$ / $$…$$ math"],
              [
                "Solutions",
                solution,
                setSolution,
                "Number each solution **1.**, **2.** … to match its problem.",
              ],
            ] as const
          ).map(([label, value, set, placeholder]) => (
            <label key={label} className="space-y-2 block min-w-0">
              <span className="eyebrow text-parchment-dim">{label}</span>
              <textarea
                value={value}
                onChange={(e) => set(e.target.value)}
                placeholder={placeholder}
                spellCheck={false}
                className="w-full h-[70vh] px-3 py-2 bg-field border border-crimson-700 rounded-lg text-parchment text-sm font-mono leading-relaxed focus:outline-none focus:border-gold-500 resize-y"
              />
            </label>
          ))}
        </section>
      )}

      {mode === "student" && (
        <section className="max-w-3xl space-y-4">
          <p className="text-sm text-parchment-dim">
            {solutionsPublic
              ? "What a student sees on the set's page, with your unsaved edits."
              : "Solutions are withheld, so students see the problems only."}
          </p>
          <ProblemSetView data={pairProblemSet(body, solution, solutionsPublic)} />
        </section>
      )}

      {/* Set details */}
      <section className="space-y-5 pt-4">
        <h2 className="section-title">Set details</h2>

        <div className="flex items-center gap-4 flex-wrap text-sm">
          <label className="text-parchment-dim flex items-center gap-2">
            Points
            <input type="number" min={0} value={points} onChange={(e) => setPoints(parseInt(e.target.value, 10) || 0)} className={numberInput} />
          </label>
          <label className="text-parchment-dim flex items-center gap-2">
            Extra credit
            <input type="number" min={0} value={extraCredit} onChange={(e) => setExtraCredit(parseInt(e.target.value, 10) || 0)} className={numberInput} />
          </label>
          <span className="text-xs text-parchment-dim">
            Core points become the assignment total in the gradebook; extra credit is bonus on top.
          </span>
        </div>

        <label className="flex items-start gap-3 text-sm text-parchment cursor-pointer">
          <input type="checkbox" checked={solutionsPublic} onChange={toggleSolutions} className="mt-1" />
          <span>
            Solutions public
            <span className="block text-xs text-parchment-dim">
              On by default. Turn off to withhold this set&apos;s answers; a class can still be given them from its
              assignment.
            </span>
          </span>
        </label>

        {/* Many-to-many: a set usually spans several lectures. Tagging makes it
            show up under "Practice" on each of those lecture pages. */}
        <div className="space-y-2">
          <span className="eyebrow text-parchment-dim">Covers lectures</span>
          {lectures.length === 0 ? (
            <p className="text-xs text-parchment-dim">This course has no lectures synced yet.</p>
          ) : (
            <div className="flex flex-wrap gap-2">
              {lectures.map((v) => {
                const on = videoIds.includes(v.id);
                return (
                  <button
                    key={v.id}
                    type="button"
                    onClick={() => toggleLecture(v.id)}
                    aria-pressed={on}
                    className={`text-xs rounded-full px-3 py-1.5 border transition-colors ${
                      on
                        ? "border-gold-500 text-gold-300 bg-gold-500/10 font-semibold"
                        : "bg-field border-crimson-700 text-parchment-dim hover:border-gold-500 hover:text-parchment"
                    }`}
                  >
                    {on ? "✓ " : ""}
                    {v.title}
                  </button>
                );
              })}
            </div>
          )}
        </div>

        <label className="space-y-2 block">
          <span className="eyebrow text-parchment-dim">Attachment URL</span>
          <input
            value={attachmentUrl}
            onChange={(e) => setAttachmentUrl(e.target.value)}
            placeholder="Optional, e.g. a hosted PDF"
            className="w-full bg-field border border-crimson-700 focus:border-gold-500 outline-none rounded-lg px-4 py-2 text-parchment text-sm placeholder:text-parchment-dim/60 transition-colors"
          />
        </label>

        <div className="pt-2">
          <button type="button" onClick={remove} className="font-ui font-semibold text-sm text-red-400 hover:text-red-300">
            Delete this problem set
          </button>
        </div>
      </section>

      {/* Save + paging, always at hand. */}
      <div className="sticky bottom-0 z-10 -mx-6 px-6 py-2 border-t border-crimson-700 bg-crimson-950/95 backdrop-blur flex items-center gap-3">
        <button
          type="button"
          onClick={() => void save()}
          disabled={!dirty || saving}
          className="font-ui font-semibold px-4 py-1.5 bg-gold-500 hover:bg-gold-400 text-crimson-950 text-sm rounded-lg transition-colors disabled:bg-crimson-800 disabled:text-parchment-dim/70 disabled:cursor-not-allowed"
        >
          {saving ? "Saving…" : "Save"}
        </button>
        <span className="font-ui text-sm text-parchment-dim min-w-0 truncate">
          {saveError ? (
            <span className="text-red-400 font-semibold">Save failed. Your changes are still here; try again.</span>
          ) : dirty ? (
            <>
              <span className="text-amber-300 font-semibold">Unsaved changes</span>
              <span className="hidden sm:inline"> · ⌘S</span>
            </>
          ) : justSaved ? (
            <span className="text-green-400">Saved ✓</span>
          ) : (
            "All changes saved"
          )}
        </span>
        {dirty && (
          <button type="button" onClick={discard} className="font-ui font-semibold text-sm text-parchment-dim hover:text-parchment">
            Discard
          </button>
        )}
        <div className="ml-auto flex items-center gap-1 min-w-0">
          {prev && (
            <button type="button" onClick={() => void go(prev)} title="[" className={navBtn}>
              ← {prev.title}
            </button>
          )}
          {prev && next && <span className="text-crimson-600" aria-hidden="true">|</span>}
          {next && (
            <button type="button" onClick={() => void go(next)} title="]" className={navBtn}>
              {next.title} →
            </button>
          )}
        </div>
      </div>
    </div>
  );
}
