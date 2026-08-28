import { getLeaderboard } from "@/lib/gamification/engine";
import { SCORING, TIERS } from "@/lib/gamification/mock";
import { ok } from "@/lib/mobile/respond";

export async function GET() {
  const scholars = await getLeaderboard();
  // The scoring rules travel with the board. The app explains how standing is
  // earned on the same screen that shows the totals, so a hardcoded copy that
  // drifted would contradict the numbers directly above it — which is exactly
  // what happened when the iOS screen was first written against guessed values.
  return ok({
    scholars,
    scoring: {
      lecture: SCORING.lecture,
      quizPerCorrect: SCORING.quizPerCorrect,
      testPerCorrect: SCORING.testPerCorrect,
      completion: SCORING.completion,
      badgeMin: TIERS.bronze.points,
      badgeMax: TIERS.platinum.points,
    },
  });
}
