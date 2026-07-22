// Geography drills — parity with the iOS app's four map drills:
//   name-country / name-state  → identify the highlighted region (choice + map diagram)
//   locate-country / locate-state → tap the named region on the map (mapTap input)
// Data + pools come from lib/drills/geo/atlas (the shared Natural Earth vector data).

import type { DrillDef, Problem, Level } from "../types";
import {
  countryPool,
  statePool,
  flagEmoji,
  stateFlagSrc,
  WORLD,
  US_STATES,
  type GeoRegion,
} from "../geo/atlas";

function shuffle<T>(arr: T[]): T[] {
  const a = [...arr];
  for (let i = a.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

// Shuffle-bag per (drill, level): draw the whole pool in a random order before any
// region repeats, so a session cycles all of them first (matches iOS).
const bags = new Map<string, GeoRegion[]>();
function draw(key: string, pool: GeoRegion[]): GeoRegion {
  if (pool.length === 0) return WORLD.askable[0];
  let bag = bags.get(key);
  if (!bag || bag.length === 0) {
    bag = shuffle(pool);
    bags.set(key, bag);
  }
  return bag.pop()!;
}

// 3 distractors preferring the same group (continent / US region), then anywhere.
function distractors(target: GeoRegion, all: GeoRegion[]): GeoRegion[] {
  const seen = new Set([target.id]);
  const out: GeoRegion[] = [];
  const sameGroup = all.filter((r) => r.continent === target.continent && r.id !== target.id);
  for (const r of [...shuffle(sameGroup), ...shuffle(all)]) {
    if (!seen.has(r.id)) {
      seen.add(r.id);
      out.push(r);
      if (out.length === 3) break;
    }
  }
  return out;
}

// ---- Identify (choice + geoMap diagram) -------------------------------------
function identifyProblem(target: GeoRegion, all: GeoRegion[], map: "world" | "us"): Problem {
  const picks = shuffle([target, ...distractors(target, all)]);
  const useFlag = map === "world";
  const options = picks.map((r) => (useFlag && flagEmoji(r.iso) ? `${flagEmoji(r.iso)} ${r.name}` : r.name));
  const optionImages = map === "us" ? picks.map((r) => stateFlagSrc(r.iso)) : undefined;
  const label = useFlag && flagEmoji(target.iso) ? `${flagEmoji(target.iso)} ${target.name}` : target.name;
  return {
    id: `${map}-id-${target.id}-${Math.random().toString(36).slice(2, 7)}`,
    prompt: map === "world" ? "Which country is highlighted?" : "Which state is highlighted?",
    input: {
      kind: "choice",
      options,
      correctIndex: picks.findIndex((r) => r.id === target.id),
      optionImages,
    },
    explanation: `${label} — ${target.continent}.`,
    diagram: { kind: "geoMap", map, highlightId: target.id },
  };
}

// ---- Locate (mapTap) --------------------------------------------------------
function locateProblem(target: GeoRegion, map: "world" | "us"): Problem {
  return {
    id: `${map}-loc-${target.id}-${Math.random().toString(36).slice(2, 7)}`,
    prompt: `Find ${target.name}`,
    input: { kind: "mapTap", map, targetId: target.id },
    explanation: `${target.name} — ${target.continent}.`,
  };
}

const LEVELS: { value: Level; label: string }[] = [
  { value: 1, label: "Easy" },
  { value: 2, label: "Medium" },
  { value: 3, label: "Hard" },
];

export const nameCountryDrill: DrillDef = {
  slug: "name-country",
  title: "Name the Country",
  blurb: "Identify the highlighted country on the world map.",
  icon: "🌍",
  subject: "Geography",
  levels: LEVELS,
  generate: (level) => identifyProblem(draw(`name-country-${level}`, countryPool(level)), WORLD.askable, "world"),
};

export const nameStateDrill: DrillDef = {
  slug: "name-state",
  title: "Name the State",
  blurb: "Identify the highlighted U.S. state — major rivers drawn in for context.",
  icon: "🗺️",
  subject: "Geography",
  levels: LEVELS,
  generate: (level) => identifyProblem(draw(`name-state-${level}`, statePool(level)), US_STATES.askable, "us"),
};

export const locateCountryDrill: DrillDef = {
  slug: "locate-country",
  title: "Where's the Country?",
  blurb: "Find the named country on the world map — click it.",
  icon: "🧭",
  subject: "Geography",
  levels: LEVELS,
  generate: (level) => locateProblem(draw(`locate-country-${level}`, countryPool(level)), "world"),
};

export const locateStateDrill: DrillDef = {
  slug: "locate-state",
  title: "Where's the State?",
  blurb: "Find the named U.S. state — click it.",
  icon: "📍",
  subject: "Geography",
  levels: LEVELS,
  generate: (level) => locateProblem(draw(`locate-state-${level}`, statePool(level)), "us"),
};
