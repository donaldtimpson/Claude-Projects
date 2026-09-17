-- DESTRUCTIVE: drops the retired Assignment.solutionsReleased column.
-- Solution visibility is now solely ProblemSet.solutionsPublic; nothing reads
-- this column. STAGED FOR HUMAN REVIEW — do not `migrate deploy` on the shared
-- Neon prod DB without confirming.

-- AlterTable
ALTER TABLE "Assignment" DROP COLUMN "solutionsReleased";
