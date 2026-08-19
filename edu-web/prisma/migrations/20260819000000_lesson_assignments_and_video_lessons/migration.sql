-- Lesson-drill assignments + lecture↔lesson links. Fully additive/backward-safe:
-- existing problem-set assignments keep working (problemSetId stays populated).

-- An Assignment can now be a lesson drill instead of a problem set. Make the
-- problem-set link optional and add the lesson slug (exactly one is set).
ALTER TABLE "Assignment" ALTER COLUMN "problemSetId" DROP NOT NULL;
ALTER TABLE "Assignment" ADD COLUMN "lessonSlug" TEXT;

-- Which lecture(s) a lesson drill is covered by. lessonSlug is bundled content,
-- not a DB row, so it is a plain string (no FK) — only the video side cascades.
CREATE TABLE "VideoLesson" (
    "videoId" TEXT NOT NULL,
    "lessonSlug" TEXT NOT NULL,

    CONSTRAINT "VideoLesson_pkey" PRIMARY KEY ("videoId","lessonSlug")
);

CREATE INDEX "VideoLesson_lessonSlug_idx" ON "VideoLesson"("lessonSlug");

ALTER TABLE "VideoLesson" ADD CONSTRAINT "VideoLesson_videoId_fkey"
    FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;
