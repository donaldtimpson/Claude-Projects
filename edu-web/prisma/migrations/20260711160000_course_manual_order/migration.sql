-- Manual lecture ordering: when true, YouTube sync will not recompute this
-- course's Video.position values (order is hand-arranged in the admin UI).
ALTER TABLE "Course" ADD COLUMN "manualOrder" BOOLEAN NOT NULL DEFAULT false;
