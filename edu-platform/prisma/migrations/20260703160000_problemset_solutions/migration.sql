-- AlterTable
ALTER TABLE "ProblemSet" ADD COLUMN "solution" TEXT NOT NULL DEFAULT '';
ALTER TABLE "ProblemSet" ADD COLUMN "isDraft" BOOLEAN NOT NULL DEFAULT true;

-- AlterTable
ALTER TABLE "Assignment" ADD COLUMN "solutionsReleased" BOOLEAN NOT NULL DEFAULT false;
