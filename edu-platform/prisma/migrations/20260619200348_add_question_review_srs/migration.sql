-- CreateTable
CREATE TABLE "QuestionReview" (
    "userId" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "box" INTEGER NOT NULL DEFAULT 1,
    "dueAt" TIMESTAMP(3) NOT NULL,
    "lastReviewedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "reps" INTEGER NOT NULL DEFAULT 0,
    "lapses" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "QuestionReview_pkey" PRIMARY KEY ("userId","questionId")
);

-- CreateIndex
CREATE INDEX "QuestionReview_userId_dueAt_idx" ON "QuestionReview"("userId", "dueAt");

-- AddForeignKey
ALTER TABLE "QuestionReview" ADD CONSTRAINT "QuestionReview_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "QuestionReview" ADD CONSTRAINT "QuestionReview_questionId_fkey" FOREIGN KEY ("questionId") REFERENCES "QuizQuestion"("id") ON DELETE CASCADE ON UPDATE CASCADE;
