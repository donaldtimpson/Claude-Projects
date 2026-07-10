import { getLeaderboard } from "@/lib/gamification/engine";
import { ok } from "@/lib/mobile/respond";

export async function GET() {
  const scholars = await getLeaderboard();
  return ok({ scholars });
}
