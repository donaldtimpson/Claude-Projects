"use server";

import { getServerSession } from "next-auth";
import { revalidatePath } from "next/cache";
import { authOptions } from "@/lib/auth";
import { db } from "@/lib/db";
import { validateHandle } from "@/lib/gamification/handle";

export type HandleState = { error?: string; success?: boolean };

export async function setHandle(_prev: HandleState, formData: FormData): Promise<HandleState> {
  const session = await getServerSession(authOptions);
  if (!session?.user?.id) return { error: "You must be signed in." };

  const check = validateHandle(String(formData.get("handle") ?? ""));
  if (!check.ok) return { error: check.error };

  // Case-insensitive uniqueness, excluding the current user.
  const taken = await db.user.findFirst({
    where: { handle: { equals: check.value, mode: "insensitive" }, NOT: { id: session.user.id } },
    select: { id: true },
  });
  if (taken) return { error: "That handle is already taken." };

  await db.user.update({ where: { id: session.user.id }, data: { handle: check.value } });
  revalidatePath("/dashboard");
  revalidatePath("/leaderboard");
  return { success: true };
}
