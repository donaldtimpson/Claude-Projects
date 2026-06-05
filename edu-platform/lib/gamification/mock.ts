// PROTOTYPE — Hall of Scholars gamification.
//
// Everything here is dummy data so Donald can see and react to the look + scoring
// rules before we commit to real persistence. Nothing is wired to the DB yet.
//
// When we go real (next pass), replace the mock exports below with queries:
//   - lectures   ->  count of VideoProgress rows per user  (x SCORING.lecture)
//   - quizPts    ->  for each quiz, the user's BEST QuizAttempt score (best-of, so
//                    there's no incentive to google) x SCORING.quizPerCorrect, and
//                    playlist tests x SCORING.testPerCorrect
//   - completions->  courses where all videos watched AND test passed (x SCORING.completion)
//   - badges     ->  derived from the same activity tables (first-time / explorer rules)
//   - handle     ->  a stable pseudonym assigned per User (never the real name/email)
// `standing` is then the sum of those plus the achievement bonus (the "blend").

export const SCORING = {
  lecture: 10, // points per lecture watched
  quizPerCorrect: 1, // points per correct answer on your BEST video-quiz attempt
  testPerCorrect: 2, // points per correct answer on your BEST playlist-test attempt
  completion: 250, // bonus for finishing a course (all videos + test passed)
  badgeMinor: 25, // achievement bonus — minor badge
  badgeMajor: 100, // achievement bonus — major badge
} as const;

export type Scholar = {
  handle: string;
  standing: number;
  lectures: number; // points from lectures watched
  quizPts: number; // points from quizzes + tests (best-of)
  completions: number; // points from course completions
  badgePts: number; // points from unlocked achievements
};

// Pseudonymous classical handles — arcade-style high-score energy, no real names.
export const MOCK_SCHOLARS: Scholar[] = [
  { handle: "AURELIUS", standing: 24800, lectures: 9800, quizPts: 9000, completions: 5000, badgePts: 1000 },
  { handle: "HYPATIA", standing: 19150, lectures: 7600, quizPts: 7300, completions: 3500, badgePts: 750 },
  { handle: "SENECA", standing: 17400, lectures: 7000, quizPts: 6400, completions: 3500, badgePts: 500 },
  { handle: "ARCHIMEDES", standing: 14220, lectures: 6100, quizPts: 5120, completions: 2500, badgePts: 500 },
  { handle: "BOETHIUS", standing: 12060, lectures: 5400, quizPts: 4160, completions: 2250, badgePts: 250 },
  { handle: "PLOTINA", standing: 10480, lectures: 4800, quizPts: 3680, completions: 1750, badgePts: 250 },
  { handle: "EUCLID", standing: 9920, lectures: 4500, quizPts: 3420, completions: 1750, badgePts: 250 },
  { handle: "PORPHYRY", standing: 7640, lectures: 3600, quizPts: 2790, completions: 1000, badgePts: 250 },
  { handle: "AGNODICE", standing: 6180, lectures: 3000, quizPts: 2430, completions: 500, badgePts: 250 },
  { handle: "THALES", standing: 4720, lectures: 2400, quizPts: 1820, completions: 250, badgePts: 250 },
  { handle: "DIOTIMA", standing: 3110, lectures: 1700, quizPts: 1160, completions: 0, badgePts: 250 },
  { handle: "ZENO", standing: 1840, lectures: 1100, quizPts: 615, completions: 0, badgePts: 125 },
];

// The signed-in scholar's own standing (dummy). Sits mid-table so the "Your Standing"
// card shows a realistic rank rather than #1.
export const MOCK_ME: Scholar & { rank: number } = {
  handle: "EUCLID",
  rank: 7,
  standing: 9920,
  lectures: 4500,
  quizPts: 3420,
  completions: 1750,
  badgePts: 250,
};

export type Badge = {
  key: string;
  name: string;
  blurb: string;
  unlocked: boolean;
  major?: boolean; // major badges are worth SCORING.badgeMajor
};

// First-time / explorer set — easy early wins to hook new scholars.
export const MOCK_BADGES: Badge[] = [
  { key: "first-lecture", name: "First Steps", blurb: "Watched your first lecture.", unlocked: true },
  { key: "first-quiz", name: "Opening Argument", blurb: "Completed your first quiz.", unlocked: true },
  { key: "first-perfect", name: "Flawless", blurb: "Earned your first perfect score.", unlocked: true },
  { key: "first-test", name: "Sat the Trials", blurb: "Took your first playlist test.", unlocked: true },
  { key: "first-course", name: "Scholar's Laurel", blurb: "Finished your first course.", unlocked: false, major: true },
  { key: "three-subjects", name: "Polymath", blurb: "Explored three different subjects.", unlocked: false, major: true },
];

// Gold / silver / bronze for the top three; gold-dim for the rest.
// Mirrors the `scoreColor` helper idiom in components/AttemptRow.tsx.
export function rankMedal(rank: number): { color: string; medal: string } {
  if (rank === 1) return { color: "text-gold-300", medal: "🥇" };
  if (rank === 2) return { color: "text-parchment", medal: "🥈" };
  if (rank === 3) return { color: "text-gold-500", medal: "🥉" };
  return { color: "text-parchment-dim", medal: "" };
}
