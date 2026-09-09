-- Add a per-course Markdown syllabus (mirrors Course.description; additive, backward-safe).
ALTER TABLE "Course" ADD COLUMN "syllabus" TEXT NOT NULL DEFAULT '';
