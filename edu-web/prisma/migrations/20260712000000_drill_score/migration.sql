-- Arcade points for a Rapid Fire (timed) drill session; null for practice runs.
-- Best score per (user, slug, level, mode) is derived as MAX(score).
ALTER TABLE "DrillAttempt" ADD COLUMN "score" INTEGER;
