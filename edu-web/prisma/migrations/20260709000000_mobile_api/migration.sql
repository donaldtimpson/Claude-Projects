-- Mobile API support. Additive + backward-safe: new nullable-defaulted columns
-- and two new tables. Nothing existing is altered destructively, so the live web
-- app keeps working before/after this is applied (local + prod share one Neon DB).

-- updatedAt columns power the offline sync manifest (GET /api/mobile/v1/sync/manifest).
-- Backfill existing rows via the DB default; Prisma keeps them fresh on write (@updatedAt).
ALTER TABLE "Course" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "Video" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
ALTER TABLE "QuizQuestion" ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Revocable refresh tokens for the native app (hashed at rest).
CREATE TABLE "MobileRefreshToken" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "lastUsedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "MobileRefreshToken_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "MobileRefreshToken_tokenHash_key" ON "MobileRefreshToken"("tokenHash");
CREATE INDEX "MobileRefreshToken_userId_idx" ON "MobileRefreshToken"("userId");
ALTER TABLE "MobileRefreshToken" ADD CONSTRAINT "MobileRefreshToken_userId_fkey"
    FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- Dedup guard for offline-queued writes replayed on reconnect.
CREATE TABLE "IdempotencyKey" (
    "key" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "scope" TEXT NOT NULL DEFAULT '',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "IdempotencyKey_pkey" PRIMARY KEY ("key")
);
CREATE INDEX "IdempotencyKey_userId_idx" ON "IdempotencyKey"("userId");
