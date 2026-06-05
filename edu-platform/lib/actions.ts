"use server";

import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { syncAchievements } from "@/lib/gamification/engine";
import type { Badge } from "@/lib/gamification/mock";

export async function markVideoWatched(videoId: string): Promise<Badge[]> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return [];
  await db.videoProgress.upsert({
    where: { userId_videoId: { userId: session.user.id, videoId } },
    create: { userId: session.user.id, videoId },
    update: {},
  });
  return syncAchievements(session.user.id);
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
  await db.quizAttempt.create({
    data: {
      userId: session.user.id,
      videoId,
      courseId,
      score,
      totalQuestions: total,
      answers,
    },
  });
  return syncAchievements(session.user.id);
}
