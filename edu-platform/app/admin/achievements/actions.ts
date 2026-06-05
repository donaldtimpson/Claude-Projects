"use server";

import { cookies } from "next/headers";
import { revalidatePath } from "next/cache";
import { db } from "@/lib/db";
import { checkAdminPassword } from "@/lib/admin-auth";
import { BADGE_CATALOG } from "@/lib/gamification/mock";

async function assertAdmin() {
  const store = await cookies();
  if (!checkAdminPassword(store.get("admin_auth")?.value ?? null)) {
    throw new Error("Unauthorized");
  }
}

const VALID_KEYS = new Set(BADGE_CATALOG.map((b) => b.key));

export async function grantAchievement(userId: string, key: string) {
  await assertAdmin();
  if (!VALID_KEYS.has(key)) throw new Error("Unknown badge key");
  await db.userAchievement.upsert({
    where: { userId_key: { userId, key } },
    create: { userId, key, grantedBy: "admin" },
    update: { grantedBy: "admin" },
  });
  revalidatePath("/admin/achievements");
  revalidatePath("/leaderboard");
}

export async function revokeAchievement(userId: string, key: string) {
  await assertAdmin();
  await db.userAchievement.deleteMany({ where: { userId, key } });
  revalidatePath("/admin/achievements");
  revalidatePath("/leaderboard");
}
