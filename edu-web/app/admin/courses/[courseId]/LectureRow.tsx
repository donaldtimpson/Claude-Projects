"use client";

import { useState } from "react";
import NotesEditor from "../../NotesEditor";
import QuizEditor from "../../QuizEditor";
import LessonLinkEditor from "./LessonLinkEditor";
import ProblemSetLinkEditor from "./ProblemSetLinkEditor";

type Question = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  position: number;
  isDraft: boolean;
};

type Note = { id: string; content: string; isDraft: boolean };

function quizSummary(questions: Question[]): { text: string; tone: "ok" | "draft" | "none" } {
  if (questions.length === 0) return { text: "quiz: —", tone: "none" };
  const drafts = questions.filter((q) => q.isDraft).length;
  const published = questions.length - drafts;
  if (drafts === 0) return { text: `quiz: ${published} published`, tone: "ok" };
  if (published === 0) return { text: `quiz: ${drafts} draft`, tone: "draft" };
  return { text: `quiz: ${published} published · ${drafts} draft`, tone: "draft" };
}

function noteSummary(note: Note | null): { text: string; tone: "ok" | "draft" | "none" } {
  if (!note) return { text: "notes: —", tone: "none" };
  return note.isDraft ? { text: "notes: draft", tone: "draft" } : { text: "notes: published", tone: "ok" };
}

// Short status for the Quiz Questions section pill (no "quiz:" prefix — the
// section label already says it), mirroring the Lecture Notes pill.
function quizPill(questions: Question[]): { text: string; tone: "ok" | "draft" | "none" } {
  if (questions.length === 0) return { text: "None", tone: "none" };
  const drafts = questions.filter((q) => q.isDraft).length;
  const published = questions.length - drafts;
  if (drafts === 0) return { text: `${published} published`, tone: "ok" };
  if (published === 0) return { text: `${drafts} draft`, tone: "draft" };
  return { text: `${published} pub · ${drafts} draft`, tone: "draft" };
}

// What a lecture is linked to: problem sets and/or grammar lessons. Returns the
// human parts once so both the row summary and the section pill stay in sync.
function linkParts(nSets: number, nLessons: number): string[] {
  const parts: string[] = [];
  if (nSets > 0) parts.push(`${nSets} set${nSets === 1 ? "" : "s"}`);
  if (nLessons > 0) parts.push(`${nLessons} lesson${nLessons === 1 ? "" : "s"}`);
  return parts;
}

const TONE: Record<"ok" | "draft" | "none", string> = {
  ok: "text-green-400",
  draft: "text-amber-300",
  none: "text-parchment-dim",
};

const PILL: Record<"ok" | "draft" | "none", string> = {
  ok: "bg-green-900/30 border-green-700 text-green-300",
  draft: "bg-amber-900/40 border-amber-700 text-amber-300",
  none: "border-crimson-700 text-parchment-dim",
};

export default function LectureRow({
  index,
  title,
  videoId,
  printHref,
  initialNote,
  initialQuestions,
  lessons,
  linkedLessons,
  grammarEnabled,
  problemSets,
  linkedProblemSets,
}: {
  index: number;
  title: string;
  videoId: string;
  printHref: string;
  initialNote: Note | null;
  initialQuestions: Question[];
  lessons: { slug: string; title: string }[];
  linkedLessons: string[];
  grammarEnabled: boolean;
  problemSets: { id: string; title: string; isDraft: boolean }[];
  linkedProblemSets: string[];
}) {
  const [open, setOpen] = useState(false);
  const [quizOpen, setQuizOpen] = useState(false);
  const [linksOpen, setLinksOpen] = useState(false);
  const quiz = quizSummary(initialQuestions);
  const quizStatus = quizPill(initialQuestions);
  const note = noteSummary(initialNote);

  // Grammar lessons only belong on grammar-type courses, but still surface any
  // stray links that already exist so they can be cleared.
  const showGrammar = grammarEnabled || linkedLessons.length > 0;
  const parts = linkParts(linkedProblemSets.length, showGrammar ? linkedLessons.length : 0);
  const linksTone: "ok" | "none" = parts.length > 0 ? "ok" : "none";
  const hasLinkTargets = problemSets.length > 0 || showGrammar;

  return (
    <div className="bg-crimson-900 border border-crimson-700 rounded-xl overflow-hidden">
      <button
        onClick={() => setOpen((o) => !o)}
        aria-expanded={open}
        className="w-full flex items-center gap-3 px-5 py-4 text-left hover:bg-crimson-800/40 transition-colors"
      >
        <svg
          className={`w-3.5 h-3.5 shrink-0 text-gold-400 transition-transform ${open ? "rotate-90" : ""}`}
          fill="currentColor"
          viewBox="0 0 20 20"
          aria-hidden="true"
        >
          <path d="M6 6l8 4-8 4V6z" />
        </svg>
        <span className="min-w-0 flex-1">
          <span className="block font-medium text-parchment truncate">
            <span className="text-parchment-dim mr-2">{index}.</span>
            {title}
          </span>
          <span className="block text-xs mt-1 space-x-3">
            <span className={TONE[quiz.tone]}>{quiz.text}</span>
            <span className={TONE[note.tone]}>{note.text}</span>
            <span className={TONE[linksTone]}>links: {parts.length > 0 ? parts.join(" · ") : "—"}</span>
          </span>
        </span>
      </button>

      {open && (
        <div className="px-5 pb-5 pt-1 space-y-4 border-t border-crimson-700/60">
          <NotesEditor videoId={videoId} initialNote={initialNote} printHref={printHref} />

          <div className="border border-crimson-700 rounded-xl overflow-hidden">
            <button
              onClick={() => setQuizOpen((o) => !o)}
              aria-expanded={quizOpen}
              className="w-full flex items-center justify-between gap-3 px-4 py-3 text-left hover:bg-crimson-800/40 transition-colors"
            >
              <span className="flex items-center gap-2">
                <svg
                  className={`w-3 h-3 shrink-0 text-gold-400 transition-transform ${quizOpen ? "rotate-90" : ""}`}
                  fill="currentColor"
                  viewBox="0 0 20 20"
                  aria-hidden="true"
                >
                  <path d="M6 6l8 4-8 4V6z" />
                </svg>
                <span className="text-sm font-medium text-parchment">Quiz Questions</span>
              </span>
              <span
                className={`text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border ${PILL[quizStatus.tone]}`}
              >
                {quizStatus.text}
              </span>
            </button>
            {quizOpen && (
              <div className="px-4 pb-4 pt-1">
                <QuizEditor videoId={videoId} initialQuestions={initialQuestions} />
              </div>
            )}
          </div>

          <div className="border border-crimson-700 rounded-xl overflow-hidden">
            <button
              onClick={() => setLinksOpen((o) => !o)}
              aria-expanded={linksOpen}
              className="w-full flex items-center justify-between gap-3 px-4 py-3 text-left hover:bg-crimson-800/40 transition-colors"
            >
              <span className="flex items-center gap-2">
                <svg
                  className={`w-3 h-3 shrink-0 text-gold-400 transition-transform ${linksOpen ? "rotate-90" : ""}`}
                  fill="currentColor"
                  viewBox="0 0 20 20"
                  aria-hidden="true"
                >
                  <path d="M6 6l8 4-8 4V6z" />
                </svg>
                <span className="text-sm font-medium text-parchment">Practice links</span>
              </span>
              <span
                className={`text-[10px] uppercase tracking-wider px-1.5 py-0.5 rounded border ${PILL[linksTone]}`}
              >
                {parts.length > 0 ? parts.join(" · ") : "None"}
              </span>
            </button>
            {linksOpen && (
              <div className="px-4 pb-4 pt-1 space-y-5">
                {!hasLinkTargets ? (
                  <p className="text-sm text-parchment-dim">
                    Nothing to link yet — add a problem set on the Problem Sets tab, or turn on Grammar
                    lessons for this course above.
                  </p>
                ) : (
                  <>
                    {problemSets.length > 0 && (
                      <ProblemSetLinkEditor videoId={videoId} problemSets={problemSets} linked={linkedProblemSets} />
                    )}
                    {showGrammar && (
                      <LessonLinkEditor videoId={videoId} lessons={lessons} linked={linkedLessons} />
                    )}
                  </>
                )}
              </div>
            )}
          </div>
        </div>
      )}
    </div>
  );
}
