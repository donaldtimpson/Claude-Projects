-- AlterTable
ALTER TABLE "Course" ADD COLUMN     "canonicalCourseId" TEXT;

-- CreateIndex
CREATE INDEX "Course_canonicalCourseId_idx" ON "Course"("canonicalCourseId");

-- AddForeignKey
ALTER TABLE "Course" ADD CONSTRAINT "Course_canonicalCourseId_fkey" FOREIGN KEY ("canonicalCourseId") REFERENCES "Course"("id") ON DELETE SET NULL ON UPDATE CASCADE;
