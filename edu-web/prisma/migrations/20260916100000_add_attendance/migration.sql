-- Per-lecture class attendance for a section. One row per (section, lecture,
-- student); absence of a row = unmarked (uncounted in the grade).
CREATE TABLE "Attendance" (
    "sectionId" TEXT NOT NULL,
    "videoId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "status" TEXT NOT NULL,
    "markedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Attendance_pkey" PRIMARY KEY ("sectionId","videoId","userId")
);

CREATE INDEX "Attendance_userId_idx" ON "Attendance"("userId");
CREATE INDEX "Attendance_sectionId_idx" ON "Attendance"("sectionId");

ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_sectionId_fkey" FOREIGN KEY ("sectionId") REFERENCES "Section"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_videoId_fkey" FOREIGN KEY ("videoId") REFERENCES "Video"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "Attendance" ADD CONSTRAINT "Attendance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
