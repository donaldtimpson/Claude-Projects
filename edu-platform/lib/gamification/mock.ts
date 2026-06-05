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
} as const;

// Achievement point tiers. Unlocking a badge adds its tier's points to your
// standing (the "blend" — kept a meaningful minority of a typical total).
// Omniscient is a one-of-a-kind capstone in a tier of its own: doing literally
// everything, perfectly. Its absurd value barely moves the ranking because
// anyone who earns it has already maxed their activity points anyway.
export type Tier = "bronze" | "silver" | "gold" | "platinum" | "omniscient";

export const TIERS: Record<Tier, { label: string; points: number }> = {
  bronze: { label: "Bronze", points: 25 },
  silver: { label: "Silver", points: 75 },
  gold: { label: "Gold", points: 200 },
  platinum: { label: "Platinum", points: 500 },
  omniscient: { label: "Omniscient", points: 10000 },
};

export type Category =
  | "milestones"
  | "mastery"
  | "completion"
  | "consistency"
  | "exploration"
  | "special";

export const CATEGORIES: { key: Category; label: string; icon: string; blurb: string }[] = [
  { key: "milestones", label: "Milestones", icon: "🏃", blurb: "Volume — the steady climb." },
  { key: "mastery", label: "Mastery", icon: "🎯", blurb: "Quality — proof you learned it." },
  { key: "completion", label: "Completion", icon: "🏛️", blurb: "Finishing what you start." },
  { key: "consistency", label: "Consistency", icon: "🔥", blurb: "Showing up, day after day." },
  { key: "exploration", label: "Exploration", icon: "🧭", blurb: "Breadth across subjects." },
  { key: "special", label: "Special", icon: "✨", blurb: "Seasonal, rare, and just for fun." },
];

export type Badge = {
  key: string; // STABLE id — logic + earned-records reference this; never rename it
  name: string; // display only — safe to rename anytime
  blurb: string; // display only
  unlocked: boolean;
  tier: Tier;
  category: Category;
};

// The starter catalog: six categories × four metal tiers, plus the lone
// Omniscient capstone. The `unlocked` flags here reflect the signed-in demo
// scholar ("you" = EUCLID): a believable mid-game profile of 12 earned. Names
// and blurbs are comfortable placeholders — rename freely; only `key`, `tier`,
// and `category` carry meaning. Every "unlocks when" maps to data we store.
export const MOCK_BADGES: Badge[] = [
  // 🏃 Milestones — volume
  { key: "first-lecture", name: "First Steps", blurb: "Watch your first lecture.", tier: "bronze", category: "milestones", unlocked: true },
  { key: "first-quiz", name: "Opening Argument", blurb: "Complete your first quiz.", tier: "bronze", category: "milestones", unlocked: true },
  { key: "lectures-25", name: "Diligent", blurb: "Watch 25 lectures.", tier: "silver", category: "milestones", unlocked: true },
  { key: "quizzes-25", name: "Quick Study", blurb: "Complete 25 quizzes.", tier: "silver", category: "milestones", unlocked: true },
  { key: "lectures-100", name: "Devoted", blurb: "Watch 100 lectures.", tier: "gold", category: "milestones", unlocked: false },
  { key: "lectures-250", name: "Marathon Mind", blurb: "Watch 250 lectures.", tier: "platinum", category: "milestones", unlocked: false },

  // 🎯 Mastery — quality
  { key: "first-perfect", name: "Flawless", blurb: "Earn your first perfect score.", tier: "bronze", category: "mastery", unlocked: true },
  { key: "course-3-aces", name: "Sharp", blurb: "Ace 3 quizzes in one course.", tier: "silver", category: "mastery", unlocked: false },
  { key: "perfect-streak-5", name: "Perfectionist", blurb: "Ace 5 quizzes in a row.", tier: "gold", category: "mastery", unlocked: false },
  { key: "perfect-test", name: "Top of the Class", blurb: "Score 100% on a playlist test.", tier: "gold", category: "mastery", unlocked: false },
  { key: "course-all-perfect", name: "Summa Cum Laude", blurb: "Perfect score on every quiz in a course.", tier: "platinum", category: "mastery", unlocked: false },

  // 🏛️ Completion — finishing
  { key: "half-course", name: "Halfway There", blurb: "Watch half a course's lectures.", tier: "bronze", category: "completion", unlocked: true },
  { key: "first-course", name: "Scholar's Laurel", blurb: "Finish a course (all lectures + test passed).", tier: "gold", category: "completion", unlocked: false },
  { key: "three-courses", name: "Honored Graduate", blurb: "Finish three courses.", tier: "gold", category: "completion", unlocked: false },
  { key: "subject-complete", name: "Master of the Discipline", blurb: "Complete every course in one subject.", tier: "platinum", category: "completion", unlocked: false },

  // 🔥 Consistency — habit
  { key: "streak-2", name: "Kindling", blurb: "Return two days in a row.", tier: "bronze", category: "consistency", unlocked: true },
  { key: "streak-7", name: "Steady Flame", blurb: "Keep a 7-day learning streak.", tier: "silver", category: "consistency", unlocked: true },
  { key: "weekly-month", name: "Weekly Scholar", blurb: "Study every week for a month.", tier: "silver", category: "consistency", unlocked: false },
  { key: "streak-30", name: "Unwavering", blurb: "Keep a 30-day learning streak.", tier: "gold", category: "consistency", unlocked: false },
  { key: "streak-100", name: "Eternal Flame", blurb: "Keep a 100-day learning streak.", tier: "platinum", category: "consistency", unlocked: false },

  // 🧭 Exploration — breadth
  { key: "subjects-2", name: "Curious", blurb: "Watch lectures in two subjects.", tier: "bronze", category: "exploration", unlocked: true },
  { key: "subjects-3", name: "Polymath", blurb: "Study three different subjects.", tier: "silver", category: "exploration", unlocked: true },
  { key: "subjects-5", name: "Renaissance Mind", blurb: "Study five different subjects.", tier: "gold", category: "exploration", unlocked: false },
  { key: "subjects-all", name: "Universal Scholar", blurb: "A lecture in every subject offered.", tier: "platinum", category: "exploration", unlocked: false },

  // ✨ Special — flavor & prestige
  { key: "night-owl", name: "Night Owl", blurb: "Study past midnight.", tier: "bronze", category: "special", unlocked: true },
  { key: "early-bird", name: "Early Bird", blurb: "Study before 6 a.m.", tier: "bronze", category: "special", unlocked: false },
  { key: "founding-scholar", name: "Founding Scholar", blurb: "Joined in the Lyceum's first year.", tier: "gold", category: "special", unlocked: true },

  // ✦ Omniscient — a tier all its own
  {
    key: "omniscient",
    name: "Omniscient",
    blurb: "Every lecture watched, every quiz and test taken — and 100% on all of it. Theoretically possible.",
    tier: "omniscient",
    category: "special",
    unlocked: false,
  },
];

// The canonical catalog without per-user state — the real engine (engine.ts)
// maps this to unlocked/locked per scholar. MOCK_BADGES keeps its `unlocked`
// flags for the static house-scholar fallback only.
export const BADGE_CATALOG: Omit<Badge, "unlocked">[] = MOCK_BADGES.map(
  ({ unlocked: _unlocked, ...rest }) => rest,
);

// ---- Badge derivation helpers ----------------------------------------------

const TIER_DIFFICULTY: Tier[] = ["bronze", "silver", "gold", "platinum", "omniscient"];

export function sumBadgePoints(badges: Badge[]): number {
  return badges.filter((b) => b.unlocked).reduce((sum, b) => sum + TIERS[b.tier].points, 0);
}

// PROTOTYPE: deterministically "earn" a plausible badge set for a given activity
// level, scaled against the busiest scholar — higher activity unlocks more (and
// rarer) badges, easiest-first. Omniscient is deliberately EXCLUDED, so no seeded
// house scholar can hold it: it stays unclaimed for a real human to earn first.
function deriveBadges(activity: number, maxActivity: number): Badge[] {
  const regular = MOCK_BADGES.filter((b) => b.tier !== "omniscient");
  const ratio = maxActivity > 0 ? activity / maxActivity : 0;
  const earnCount = Math.max(0, Math.round(ratio * regular.length));

  const easiestFirst = [...regular].sort(
    (a, b) => TIER_DIFFICULTY.indexOf(a.tier) - TIER_DIFFICULTY.indexOf(b.tier),
  );
  const earned = new Set(easiestFirst.slice(0, earnCount).map((b) => b.key));

  // Omniscient is never in `earned`, so it remains locked for everyone.
  return MOCK_BADGES.map((b) => ({ ...b, unlocked: earned.has(b.key) }));
}

// ---- Scholars (the Hall) ----------------------------------------------------

export type Scholar = {
  handle: string;
  standing: number;
  lectures: number; // points from lectures watched
  quizPts: number; // points from quizzes + tests (best-of)
  completions: number; // points from course completions
  badgePts: number; // points from unlocked achievements
  house: boolean; // a seeded "house" scholar (not a real student)
  note?: string; // witty per-scholar line shown on house-scholar detail pages
};

// We author each scholar's ACTIVITY (lectures/quizzes/completions); badgePts and
// standing are then DERIVED so the breakdown bar, the badge grid, and the ranking
// always agree. Great minds up top as aspirational rivals; the jokes live at the
// bottom, where new scholars first overtake them. "Scholar" is the signed-in demo
// "you" — the only non-house entry — and uses the canonical MOCK_BADGES set.
type SeedActivity = {
  handle: string;
  lectures: number;
  quizPts: number;
  completions: number;
  house: boolean;
  note?: string;
};

const SEED_ACTIVITY: SeedActivity[] = [
  { handle: "Aristotle", lectures: 9600, quizPts: 8000, completions: 2400, house: true, note: "The original polymath — father of logic itself, and of biology, physics, ethics, and rhetoric besides. Half your syllabus traces back to him; he sits atop the Hall because he quite literally wrote the books your courses are built on. Unseat him and there is no one left to surpass." },
  { handle: "Einstein", lectures: 8100, quizPts: 6700, completions: 2000, house: true, note: "Relatively speaking, he was always going to top the board. Bend space, time, and your study schedule to pass him." },
  { handle: "Newton", lectures: 6900, quizPts: 5700, completions: 1600, house: true, note: "Invented calculus on a dare. Stands on the shoulders of giants — you'll have to climb over him." },
  { handle: "Galileo", lectures: 5700, quizPts: 4700, completions: 1400, house: true, note: "Maintains that the Hall revolves around merit. Prove him right and rise." },
  { handle: "Archimedes", lectures: 4900, quizPts: 4100, completions: 1200, house: true, note: "Shouted 'Eureka!' the moment we seeded him here. Give him a reason to run another bath." },
  { handle: "Gauss", lectures: 4200, quizPts: 3400, completions: 1000, house: true, note: "Summed the whole leaderboard in his head before breakfast. Out-study the arithmetic prodigy." },
  { handle: "Socrates", lectures: 3400, quizPts: 2800, completions: 800, house: true, note: "Knows only that he knows nothing — and that he isn't a real student. Question everything, then outrank him." },
  { handle: "Hypatia", lectures: 2900, quizPts: 2400, completions: 500, house: true, note: "Lectured in Alexandria long before you enrolled. A placeholder legend, not a classmate — pass her." },
  { handle: "Diogenes", lectures: 2300, quizPts: 1900, completions: 400, house: true, note: "Lives in a barrel, holding up a lamp in search of an honest scholar. Be the one he's looking for." },
  { handle: "Scholar", lectures: 1700, quizPts: 1200, completions: 500, house: false }, // you
  { handle: "Normie", lectures: 1500, quizPts: 1100, completions: 400, house: true, note: "Watches at 1x, never the bonus material. Aggressively average — clearing him is the bare minimum." },
  { handle: "NPC", lectures: 1200, quizPts: 1000, completions: 0, house: true, note: "Runs the same three quizzes on a loop, forever. Breaking the cycle is your side quest." },
  { handle: "Sophist", lectures: 900, quizPts: 600, completions: 0, house: true, note: "Will argue he earned the points without watching a single lecture. Don't buy it — just beat it." },
  { handle: "Daydreamer", lectures: 500, quizPts: 300, completions: 0, house: true, note: "Hit play, then watched a cloud for forty minutes. Easy to pass — simply pay attention." },
  { handle: "Dunce", lectures: 90, quizPts: 30, completions: 0, house: true, note: "Proudly wore the cap and tapped out at lecture one. He exists so that everyone — truly everyone — outranks someone." },
];

const activityOf = (s: { lectures: number; quizPts: number; completions: number }) =>
  s.lectures + s.quizPts + s.completions;

const MAX_ACTIVITY = Math.max(...SEED_ACTIVITY.map(activityOf));

export const MOCK_SCHOLARS: Scholar[] = SEED_ACTIVITY.map((s) => {
  const activity = activityOf(s);
  // EUCLID ("you") uses the hand-picked canonical badge set; everyone else derived.
  const badgePts = s.house ? sumBadgePoints(deriveBadges(activity, MAX_ACTIVITY)) : sumBadgePoints(MOCK_BADGES);
  return {
    handle: s.handle,
    lectures: s.lectures,
    quizPts: s.quizPts,
    completions: s.completions,
    badgePts,
    standing: activity + badgePts,
    house: s.house,
    note: s.note,
  };
}).sort((a, b) => b.standing - a.standing);

const ME_INDEX = MOCK_SCHOLARS.findIndex((s) => s.handle === "Scholar");

// The signed-in scholar's own standing (dummy) + their live rank in the Hall.
export const MOCK_ME: Scholar & { rank: number } = {
  ...MOCK_SCHOLARS[ME_INDEX],
  rank: ME_INDEX + 1,
};

// Badge set for any scholar's detail page. "You" gets the canonical hand-picked
// set; house scholars get the derived set (Omniscient always locked).
export function badgesForScholar(scholar: Scholar): Badge[] {
  if (scholar.handle === MOCK_ME.handle) return MOCK_BADGES;
  return deriveBadges(activityOf(scholar), MAX_ACTIVITY);
}

// Gold / silver / bronze for the top three; gold-dim for the rest.
// Mirrors the `scoreColor` helper idiom in components/AttemptRow.tsx.
export function rankMedal(rank: number): { color: string; medal: string } {
  if (rank === 1) return { color: "text-gold-300", medal: "🥇" };
  if (rank === 2) return { color: "text-parchment", medal: "🥈" };
  if (rank === 3) return { color: "text-gold-500", medal: "🥉" };
  return { color: "text-parchment-dim", medal: "" };
}
