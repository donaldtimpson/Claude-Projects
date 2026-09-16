-- Gate the per-lecture grammar-lesson linker to courses that actually use a
-- bundled lesson-drill bank. Nullable + no default = additive and backward-safe.
ALTER TABLE "Course" ADD COLUMN "lessonBank" TEXT;
