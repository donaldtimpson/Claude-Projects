-- Instructor-defined grade categories per section (e.g. in-class "Tests"), each
-- with any number of graded items (columns) and per-student scores.
CREATE TABLE "GradeCategory" (
    "id" TEXT NOT NULL,
    "sectionId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "weight" INTEGER NOT NULL DEFAULT 10,
    "position" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "GradeCategory_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "GradeCategory_sectionId_idx" ON "GradeCategory"("sectionId");

CREATE TABLE "GradeItem" (
    "id" TEXT NOT NULL,
    "categoryId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "maxPoints" INTEGER NOT NULL DEFAULT 100,
    "position" INTEGER NOT NULL DEFAULT 0,
    CONSTRAINT "GradeItem_pkey" PRIMARY KEY ("id")
);
CREATE INDEX "GradeItem_categoryId_idx" ON "GradeItem"("categoryId");

CREATE TABLE "GradeScore" (
    "itemId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "score" INTEGER NOT NULL,
    CONSTRAINT "GradeScore_pkey" PRIMARY KEY ("itemId","userId")
);
CREATE INDEX "GradeScore_userId_idx" ON "GradeScore"("userId");

ALTER TABLE "GradeCategory" ADD CONSTRAINT "GradeCategory_sectionId_fkey" FOREIGN KEY ("sectionId") REFERENCES "Section"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GradeItem" ADD CONSTRAINT "GradeItem_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "GradeCategory"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GradeScore" ADD CONSTRAINT "GradeScore_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "GradeItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "GradeScore" ADD CONSTRAINT "GradeScore_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
