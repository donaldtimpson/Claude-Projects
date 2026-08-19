"use client";

import { useState } from "react";
import NotesEditor from "../../NotesEditor";
import QuizEditor from "../../QuizEditor";
import LessonLinkEditor from "./LessonLinkEditor";

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

const TONE: Record<"ok" | "draft" | "none", string> = {
  ok: "text-green-400",
  draft: "text-amber-300",
  none: "text-parchment-dim",
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
}: {
  index: number;
  title: string;
  videoId: string;
  printHref: string;
  initialNote: Note | null;
  initialQuestions: Question[];
  lessons: { slug: string; title: string }[];
  linkedLessons: string[];
}) {
  const [open, setOpen] = useState(false);
  const quiz = quizSummary(initialQuestions);
  const note = noteSummary(initialNote);

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
          </span>
        </span>
      </button>

      {open && (
        <div className="px-5 pb-5 pt-1 space-y-4 border-t border-crimson-700/60">
          <NotesEditor videoId={videoId} initialNote={initialNote} printHref={printHref} />
          <QuizEditor videoId={videoId} initialQuestions={initialQuestions} />
          <LessonLinkEditor videoId={videoId} lessons={lessons} linked={linkedLessons} />
        </div>
      )}
    </div>
  );
}
