-- Sign in with Apple support. Additive + backward-safe.
-- password becomes nullable (Apple accounts have no password); appleUserId links
-- returning Apple users by their stable `sub`.
ALTER TABLE "User" ALTER COLUMN "password" DROP NOT NULL;
ALTER TABLE "User" ADD COLUMN "appleUserId" TEXT;
CREATE UNIQUE INDEX "User_appleUserId_key" ON "User"("appleUserId");
