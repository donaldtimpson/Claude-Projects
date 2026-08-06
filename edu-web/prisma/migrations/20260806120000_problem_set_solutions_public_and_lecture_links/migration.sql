-- Solutions are public by default ("public unless withheld"). Additive with a
-- default, so existing rows become visible without a backfill step.
ALTER TABLE "ProblemSet" ADD COLUMN "solutionsPublic" BOOLEAN NOT NULL DEFAULT true;

-- Many-to-many: which lectures a problem set covers.
CREATE TABLE "ProblemSetVideo" (
    "problemSetId" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,

    CONSTRAINT "ProblemSetVideo_pkey" PRIMARY KEY ("problemSetId","videoId")
);

CREATE INDEX "ProblemSetVideo_videoId_idx" ON "ProblemSetVideo"("videoId");

ALTER TABLE "ProblemSetVideo" ADD CONSTRAINT "ProblemSetVideo_problemSetId_fkey"
    FOREIGN KEY ("problemSetId") REFERENCES "ProblemSet"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "ProblemSetVideo" ADD CONSTRAINT "ProblemSetVideo_videoId_fkey"
    FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;
