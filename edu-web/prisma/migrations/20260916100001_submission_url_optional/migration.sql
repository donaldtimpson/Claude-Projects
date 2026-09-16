-- Allow a homework grade to exist without a student-pasted URL, so the
-- instructor can enter a score directly in the gradebook.
ALTER TABLE "Submission" ALTER COLUMN "url" DROP NOT NULL;
