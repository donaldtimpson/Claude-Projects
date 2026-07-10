-- CreateTable
CREATE TABLE "DrillAttempt" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "slug" TEXT NOT NULL,
    "level" INTEGER NOT NULL,
    "total" INTEGER NOT NULL,
    "correct" INTEGER NOT NULL,
    "bestStreak" INTEGER NOT NULL DEFAULT 0,
    "mode" TEXT NOT NULL,
    "durationSec" INTEGER NOT NULL DEFAULT 0,
    "completedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "DrillAttempt_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "DrillAttempt_userId_completedAt_idx" ON "DrillAttempt"("userId", "completedAt");

-- CreateIndex
CREATE INDEX "DrillAttempt_userId_slug_idx" ON "DrillAttempt"("userId", "slug");

-- AddForeignKey
ALTER TABLE "DrillAttempt" ADD CONSTRAINT "DrillAttempt_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
