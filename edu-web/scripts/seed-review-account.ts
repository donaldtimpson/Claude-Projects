// Creates (or re-seeds) the App Store review account whose credentials go in the
// App Store Connect review notes. The app is login-gated, so a reviewer with an
// empty account sees zeroes everywhere — streak 0, no badges, nothing to review.
// This walks the account through real activity via the mobile API so every screen
// has something on it.
//
// Deliberately separate from Donald's own QA student account: a reviewer poking
// around shouldn't disturb his testing, and this one can be wiped and rebuilt.
//
//   npx tsx scripts/seed-review-account.ts                  # against production
//   npx tsx scripts/seed-review-account.ts --local          # against localhost:3000
//   npx tsx scripts/seed-review-account.ts --reset          # delete and rebuild
//
// Credentials are fixed (not random) so the review notes stay valid across runs.
import { PrismaClient } from "@prisma/client";

const REVIEW_EMAIL = "appreview@timpsonlyceum.com";
const REVIEW_PASSWORD = "LyceumReview2026!";
const REVIEW_NAME = "App Review";
const REVIEW_HANDLE = "Peripatetic";

const local = process.argv.includes("--local");
const reset = process.argv.includes("--reset");
const BASE = local ? "http://localhost:3000" : "https://timpson-lyceum.vercel.app";
const V1 = `${BASE}/api/mobile/v1`;

const db = new PrismaClient();
let token = "";

async function api<T>(path: string, init?: RequestInit & { body?: string }): Promise<T> {
  const res = await fetch(V1 + path, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(init?.headers ?? {}),
    },
  });
  const text = await res.text();
  if (!res.ok) throw new Error(`${init?.method ?? "GET"} ${path} -> ${res.status} ${text}`);
  return text ? (JSON.parse(text) as T) : ({} as T);
}

const post = <T>(path: string, body: unknown) =>
  api<T>(path, { method: "POST", body: JSON.stringify(body) });

async function main() {
  console.log(`Seeding the App Store review account against ${BASE}\n`);

  const existing = await db.user.findUnique({
    where: { email: REVIEW_EMAIL },
    select: { id: true },
  });
  if (existing && reset) {
    // Same order as DELETE /api/mobile/v1/me: IdempotencyKey has a bare userId
    // with no relation, so cascade won't take it.
    await db.$transaction([
      db.idempotencyKey.deleteMany({ where: { userId: existing.id } }),
      db.user.delete({ where: { id: existing.id } }),
    ]);
    console.log("· removed the previous review account");
  } else if (existing) {
    console.log("Review account already exists. Re-run with --reset to rebuild it.");
    console.log(`  email    ${REVIEW_EMAIL}`);
    console.log(`  password ${REVIEW_PASSWORD}`);
    return;
  }

  const auth = await post<{ accessToken: string; user: { id: string } }>("/auth/register", {
    name: REVIEW_NAME,
    email: REVIEW_EMAIL,
    password: REVIEW_PASSWORD,
  });
  token = auth.accessToken;
  const userId = auth.user.id;
  console.log(`· registered ${REVIEW_EMAIL}`);

  // A handle is what the Hall of Scholars shows; without one the account is
  // invisible there, and the leaderboard is one of the screens worth reviewing.
  await db.user.update({ where: { id: userId }, data: { handle: REVIEW_HANDLE } });
  console.log(`· handle @${REVIEW_HANDLE}`);

  // Work through the two courses with the most material so progress and quiz
  // history land on screens a reviewer is likely to open first.
  const { courses } = await api<{ courses: { id: string; title: string }[] }>("/courses");
  const picked = courses.slice(0, 2);

  let watched = 0;
  let quizzes = 0;
  for (const course of picked) {
    const detail = await api<{ course: { videos: { id: string }[] } }>(`/courses/${course.id}`);
    const videos = detail.course?.videos ?? [];

    // Watch the first third — enough for a visible progress bar and a Continue
    // Watching entry, without looking like the account finished the course.
    for (const v of videos.slice(0, Math.max(1, Math.ceil(videos.length / 3)))) {
      await post("/progress/video-watched", { videoId: v.id, clientId: `seed-watch-${v.id}` });
      watched++;
    }

    // Quizzes on the watched lectures, scored high but not perfect.
    for (const v of videos.slice(0, 4)) {
      const quiz = await api<{ questions?: { id: string }[] }>(`/quiz?videoId=${v.id}`);
      const total = quiz.questions?.length ?? 0;
      if (total === 0) continue;
      const score = Math.max(1, total - (quizzes % 3 === 0 ? 1 : 0));
      await post("/quiz/attempt", {
        videoId: v.id,
        score,
        total,
        answers: Array.from({ length: total }, () => 0),
        clientId: `seed-quiz-${v.id}`,
      });
      quizzes++;
    }
    console.log(`· ${course.title}: ${watched} watched, ${quizzes} quizzes so far`);
  }

  // Drill sessions across categories, including a Rapid Fire score high enough to
  // earn a badge and populate the high-score line on the drill screen.
  const drills: [string, number, number][] = [
    ["name-the-country", 1, 470],
    ["us-state-capitals", 1, 380],
    ["subject-verb-agreement", 2, 310],
  ];
  for (const [slug, level, score] of drills) {
    await post("/drills/session", {
      slug, level, total: 20, correct: 18, bestStreak: 11,
      mode: "timed", durationSec: 60, score,
      clientId: `seed-drill-${slug}`,
    });
  }
  console.log(`· ${drills.length} drill sessions`);

  // The quizzes above auto-enrolled every question into spaced repetition, but a
  // card is never due the same UTC day it was answered (box 1 is a 1-day interval),
  // so the Review tab would greet a reviewer with "nothing due". Backdate a slice
  // of them to look like an account a few days old, which is the state the tab is
  // actually built for.
  const enrolled = await db.questionReview.findMany({
    where: { userId },
    orderBy: { dueAt: "asc" },
    select: { questionId: true },
    take: 18,
  });
  const yesterday = new Date(Date.now() - 86_400_000);
  await db.questionReview.updateMany({
    where: { userId, questionId: { in: enrolled.map((r) => r.questionId) } },
    data: { dueAt: yesterday },
  });
  console.log(`· ${enrolled.length} review cards backdated to due now`);

  // Then actually grade a few through the API, so the account has review history
  // and a partly-worked queue rather than a full untouched one.
  const deck = await api<{ cards?: { id: string }[] }>("/review/deck");
  const cards = deck.cards ?? [];
  for (const [i, card] of cards.slice(0, 6).entries()) {
    await post("/review/grade", {
      questionId: card.id,
      correct: i % 3 !== 0, // a couple of misses, which stay in the queue
      clientId: `seed-review-${card.id}`,
    });
  }
  console.log(`· graded ${Math.min(cards.length, 6)} of them`);

  const me = await api<{
    streak: { count: number };
    dueCount: number;
  }>("/me");
  const badges = await db.userAchievement.count({ where: { userId } });

  console.log("\nReview account ready — put these in App Store Connect review notes:");
  console.log(`  email    ${REVIEW_EMAIL}`);
  console.log(`  password ${REVIEW_PASSWORD}`);
  console.log(`\n  streak ${me.streak.count} · ${badges} badges · ${me.dueCount} cards due` +
    ` · ${watched} lectures watched · ${quizzes} quizzes`);
}

main()
  .catch((e) => {
    console.error("\nFailed:", e instanceof Error ? e.message : e);
    process.exit(1);
  })
  .finally(() => db.$disconnect());
