// Spaced-repetition core. One QuestionReview row per (student, published
// question); a question auto-enrolls the first time the student answers it in a
// quiz/test. Leitner scheduling: a correct answer promotes the card a box (longer
// interval), a wrong answer resets it to box 1. The cross-course daily review at
// /review serves the cards whose dueAt has passed.

import { db } from "@/lib/db";

const DAY_MS = 86_400_000;

// Interval (in days) until a card in box N is due again. Index 0 is unused so the
// box number indexes directly. Tunable.
export const INTERVALS_DAYS = [0, 1, 3, 7, 21, 60];
export const MAX_BOX = INTERVALS_DAYS.length - 1; // 5
export const DAILY_CAP = 50; // most a single daily-review session will serve

// Cards bucket by UTC day (matching the streak math), so a card answered today is
// never due again the same day.
function startOfUtcDay(d: Date): number {
  return Math.floor(d.getTime() / DAY_MS) * DAY_MS;
}

// Next box + due date. A brand-new card (prevBox null) answered correctly lands in
// box 2; answered wrong it sits in box 1. Existing cards step up/down from there.
export function nextSchedule(
  prevBox: number | null,
  correct: boolean,
  now: Date,
): { box: number; dueAt: Date } {
  const box = correct ? Math.min((prevBox ?? 1) + 1, MAX_BOX) : 1;
  const dueAt = new Date(startOfUtcDay(now) + INTERVALS_DAYS[box] * DAY_MS);
  return { box, dueAt };
}

// Auto-enroll / reschedule every published question in a just-submitted quiz. The
// `answers` index array is aligned to the same position-ordered, published-only
// question list the quiz pages render (see the video/test pages), so answers[i]
// belongs to questions[i]. Unanswered (null) entries are skipped.
export async function recordQuizAnswersForSrs(
  userId: string,
  scope: { videoId: string | null; courseId: string | null },
  answers: (number | null)[],
): Promise<void> {
  const where = scope.videoId
    ? { videoId: scope.videoId, isDraft: false }
    : scope.courseId
      ? { courseId: scope.courseId, videoId: null, isDraft: false }
      : null;
  if (!where) return;

  const questions = await db.quizQuestion.findMany({
    where,
    orderBy: { position: "asc" },
    select: { id: true, correctIndex: true },
  });
  if (questions.length === 0) return;

  const existing = await db.questionReview.findMany({
    where: { userId, questionId: { in: questions.map((q) => q.id) } },
    select: { questionId: true, box: true },
  });
  const prevBox = new Map(existing.map((e) => [e.questionId, e.box]));

  const now = new Date();
  await Promise.all(
    questions.map((q, i) => {
      const answer = answers[i];
      if (answer === null || answer === undefined) return Promise.resolve();
      const correct = answer === q.correctIndex;
      const prev = prevBox.get(q.id) ?? null;
      const { box, dueAt } = nextSchedule(prev, correct, now);
      return db.questionReview.upsert({
        where: { userId_questionId: { userId, questionId: q.id } },
        create: { userId, questionId: q.id, box, dueAt, lastReviewedAt: now, reps: 1 },
        update: {
          box,
          dueAt,
          lastReviewedAt: now,
          reps: { increment: 1 },
          ...(correct ? {} : { lapses: { increment: prev && prev > 1 ? 1 : 0 } }),
        },
      });
    }),
  );
}

// Grade a single card from the daily review.
export async function applyReviewGrade(
  userId: string,
  questionId: string,
  correct: boolean,
): Promise<void> {
  const existing = await db.questionReview.findUnique({
    where: { userId_questionId: { userId, questionId } },
    select: { box: true },
  });
  const prev = existing?.box ?? null;
  const now = new Date();
  const { box, dueAt } = nextSchedule(prev, correct, now);
  await db.questionReview.upsert({
    where: { userId_questionId: { userId, questionId } },
    create: { userId, questionId, box, dueAt, lastReviewedAt: now, reps: 1 },
    update: {
      box,
      dueAt,
      lastReviewedAt: now,
      reps: { increment: 1 },
      ...(correct ? {} : { lapses: { increment: prev && prev > 1 ? 1 : 0 } }),
    },
  });
}

export function getDueCount(userId: string): Promise<number> {
  return db.questionReview.count({
    where: { userId, dueAt: { lte: new Date() }, question: { isDraft: false } },
  });
}

// Cards a student has driven to the top box — fully mastered, longest interval.
export function masteredCardCount(userId: string): Promise<number> {
  return db.questionReview.count({ where: { userId, box: MAX_BOX } });
}

export type DueCard = {
  id: string;
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation: string;
  source: string; // lecture title, or course title for a playlist-test question
};

// The due deck for today's review, most-overdue first, capped. Only published
// questions; the dueAt filter is redundant with isDraft but kept explicit.
export async function getDueDeck(userId: string, cap = DAILY_CAP): Promise<DueCard[]> {
  const rows = await db.questionReview.findMany({
    where: { userId, dueAt: { lte: new Date() }, question: { isDraft: false } },
    orderBy: { dueAt: "asc" },
    take: cap,
    include: {
      question: {
        select: {
          id: true,
          prompt: true,
          options: true,
          correctIndex: true,
          explanation: true,
          video: { select: { title: true } },
          course: { select: { title: true } },
        },
      },
    },
  });
  return rows.map((r) => ({
    id: r.question.id,
    prompt: r.question.prompt,
    options: r.question.options as string[],
    correctIndex: r.question.correctIndex,
    explanation: r.question.explanation,
    source: r.question.video?.title ?? r.question.course?.title ?? "Review",
  }));
}
