// Shared moderation helpers for the lecture discussion: block-list lookup used to
// filter comment listings, and the comment-report reason vocabulary shared by the
// web + mobile report endpoints. Reports and blocks are the App Store Guideline
// 1.2 "report objectionable content" + "block abusive users" affordances that
// gate re-enabling discussion (user-generated content).

import { db } from "@/lib/db";

// The set of userIds the viewer has blocked. Empty set for signed-out viewers.
// Callers pass the result to `where: { userId: { notIn: [...] } }` on the comment
// query so blocked authors' comments (and their replies) never load.
export async function getBlockedUserIds(viewerId: string | null): Promise<string[]> {
  if (!viewerId) return [];
  const rows = await db.userBlock.findMany({
    where: { blockerId: viewerId },
    select: { blockedId: true },
  });
  return rows.map((r) => r.blockedId);
}

// Valid `CommentReportReason` enum values, mirrored as a plain set so the API can
// validate an incoming reason string without importing the generated enum object.
export const REPORT_REASONS = ["SPAM", "HARASSMENT", "HATE", "SEXUAL", "VIOLENCE", "OTHER"] as const;
export type ReportReason = (typeof REPORT_REASONS)[number];

export function normalizeReason(input: unknown): ReportReason {
  return typeof input === "string" && (REPORT_REASONS as readonly string[]).includes(input)
    ? (input as ReportReason)
    : "OTHER";
}
