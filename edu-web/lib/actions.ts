"use server";

import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { applyReviewGrade } from "@/lib/srs";
import {
  markVideoWatchedFor,
  recordReviewClearedFor,
  recordQuizAttemptFor,
  recordDrillSessionFor,
  finishDailyReviewFor,
} from "@/lib/services/activity";
import { type Badge } from "@/lib/gamification/mock";
import type { DrillSummary } from "@/lib/drills";

// These "use server" actions are the WEB transport. Each resolves the current
// user from the NextAuth cookie session, then delegates to the shared,
// userId-parameterized service in lib/services/activity.ts. The native app hits
// the same services through app/api/mobile/v1/* (Bearer token) — one
// implementation, two front doors.

export async function markVideoWatched(videoId: string): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  return markVideoWatchedFor(session.user.id, videoId);
}

// courseId is bound by the page for future per-course review badges.
export async function recordReviewCleared(courseId: string, perfect: boolean): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  return recordReviewClearedFor(session.user.id, courseId, perfect);
}

// videoId/courseId bound by the page via .bind(null, videoId, courseId)
export async function saveQuizAttempt(
  videoId: string | null,
  courseId: string | null,
  score: number,
  total: number,
  answers: (number | null)[],
): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  return recordQuizAttemptFor(session.user.id, { videoId, courseId, score, total, answers });
}

export async function recordDrillSession(s: DrillSummary): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  return recordDrillSessionFor(session.user.id, s);
}

// Grade a single card in the cross-course daily review (/review). Persists the
// card's new Leitner box + due date immediately, so leaving mid-session keeps
// the progress already made.
export async function gradeReview(questionId: string, correct: boolean): Promise<void> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return;
  await applyReviewGrade(session.user.id, questionId, correct);
}

export async function finishDailyReview(): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  return finishDailyReviewFor(session.user.id);
}
