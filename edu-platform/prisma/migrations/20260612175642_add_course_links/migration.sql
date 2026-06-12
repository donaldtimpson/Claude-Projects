-- CreateEnum
CREATE TYPE "CourseLinkKind" AS ENUM ('RECOMMENDED', 'RELATED');

-- CreateTable
CREATE TABLE "CourseLink" (
    "id" TEXT NOT NULL,
    "fromCourseId" TEXT NOT NULL,
    "toCourseId" TEXT NOT NULL,
    "kind" "CourseLinkKind" NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "CourseLink_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "CourseLink_fromCourseId_idx" ON "CourseLink"("fromCourseId");

-- CreateIndex
CREATE INDEX "CourseLink_toCourseId_idx" ON "CourseLink"("toCourseId");

-- CreateIndex
CREATE UNIQUE INDEX "CourseLink_fromCourseId_toCourseId_kind_key" ON "CourseLink"("fromCourseId", "toCourseId", "kind");

-- AddForeignKey
ALTER TABLE "CourseLink" ADD CONSTRAINT "CourseLink_fromCourseId_fkey" FOREIGN KEY ("fromCourseId") REFERENCES "Course"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "CourseLink" ADD CONSTRAINT "CourseLink_toCourseId_fkey" FOREIGN KEY ("toCourseId") REFERENCES "Course"("id") ON DELETE CASCADE ON UPDATE CASCADE;
