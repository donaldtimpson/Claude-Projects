-- CreateTable
CREATE TABLE "Transcript" (
    "id" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "segments" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Transcript_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "Transcript_videoId_key" ON "Transcript"("videoId");

-- AddForeignKey
ALTER TABLE "Transcript" ADD CONSTRAINT "Transcript_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Full-text search: GIN expression indexes (English). Queries in lib/search.ts
-- use the SAME to_tsvector('english', ...) expressions so these indexes are used.
-- The two-arg to_tsvector(regconfig, text) form is IMMUTABLE, so it is indexable.
CREATE INDEX "Transcript_content_fts" ON "Transcript"
  USING GIN (to_tsvector('english', "content"));

CREATE INDEX "LectureNote_content_fts" ON "LectureNote"
  USING GIN (to_tsvector('english', "content"));

CREATE INDEX "Video_title_desc_fts" ON "Video"
  USING GIN (to_tsvector('english', coalesce("title", '') || ' ' || coalesce("description", '')));

CREATE INDEX "Course_title_desc_fts" ON "Course"
  USING GIN (to_tsvector('english', coalesce("title", '') || ' ' || coalesce("description", '')));
