// Geography atlas for the map drills — the same bundled Natural Earth vector data the
// iOS app uses (paths already projected to Web Mercator in a normalized viewBox, stored
// as SVG path strings). Pure data; the SVG map component renders it directly.

import worldRaw from "./data/world-countries.json";
import usRaw from "./data/us-states.json";

export type Rect = { x: number; y: number; w: number; h: number };

export type GeoRegion = {
  id: string; // stable key + answer text
  name: string;
  continent: string; // grouping (continent for countries, US region for states)
  rank: number; // prominence: 2 (famous) … 7 (obscure)
  askable: boolean; // false for disputed/dependency territories (still drawn)
  iso: string | null; // 2-letter code (emoji flag for countries; postal for states)
  focus: Rect; // bbox of the largest landmass (zoom target)
  path: string; // SVG path in viewBox coords
};

export type GeoAtlas = {
  viewBox: Rect;
  regions: GeoRegion[];
  rivers: string[]; // SVG path strings (US only)
  lakes: string[]; // water polygons drawn over land (carves lake-inclusive states)
  neighbors: string[]; // context countries drawn gray (US only)
  byId: Map<string, GeoRegion>;
  askable: GeoRegion[];
};

function rect(a: number[]): Rect {
  return { x: a[0], y: a[1], w: a[2], h: a[3] };
}

type RawRegion = Omit<GeoRegion, "focus" | "iso"> & { focus: number[]; iso: string | null };
type RawWorld = { viewBox: number[]; countries: RawRegion[] };
type RawUs = {
  viewBox: number[];
  states: RawRegion[];
  rivers: { path: string }[];
  lakes: { path: string }[];
  neighbors: { path: string }[];
};

const world = worldRaw as unknown as RawWorld;
const us = usRaw as unknown as RawUs;

function build(
  viewBox: number[],
  raw: RawRegion[],
  rivers: string[] = [],
  lakes: string[] = [],
  neighbors: string[] = [],
): GeoAtlas {
  const regions: GeoRegion[] = raw.map((r) => ({ ...r, focus: rect(r.focus) }));
  return {
    viewBox: rect(viewBox),
    regions,
    rivers,
    lakes,
    neighbors,
    byId: new Map(regions.map((r) => [r.id, r])),
    askable: regions.filter((r) => r.askable),
  };
}

export const WORLD: GeoAtlas = build(world.viewBox, world.countries);

export const US_STATES: GeoAtlas = build(
  us.viewBox,
  us.states,
  us.rivers.map((r) => r.path),
  us.lakes.map((l) => l.path),
  us.neighbors.map((n) => n.path),
);

export type GeoMapKind = "world" | "us";
export function atlas(kind: GeoMapKind): GeoAtlas {
  return kind === "world" ? WORLD : US_STATES;
}

// National flag as an emoji from the ISO code's regional-indicator letters (🇫🇷 from "FR").
// Countries only — US states have no flag emoji (we use bundled PNGs for those).
export function flagEmoji(iso: string | null): string {
  if (!iso || iso.length !== 2) return "";
  const A = 0x1f1e6;
  return [...iso.toUpperCase()]
    .map((c) => {
      const code = c.charCodeAt(0);
      return code >= 65 && code <= 90 ? String.fromCodePoint(A + code - 65) : "";
    })
    .join("");
}

// Public path to a US state's bundled flag PNG (e.g. "/flags/us-ca.png").
export function stateFlagSrc(iso: string | null): string | null {
  return iso ? `/flags/us-${iso.toLowerCase()}.png` : null;
}

// ---- Difficulty pools (mirror the iOS DrillCatalog) -------------------------
// Hand-curated Easy-tier tweaks — LABELRANK prominence isn't a perfect "how famous"
// score. Removed countries still appear on Medium/Hard.
const EASY_REMOVE = new Set(["Kenya", "Democratic Republic of the Congo", "Ethiopia"]);
const EASY_ADD = new Set(["Iceland", "Ireland", "Greece"]);

export function countryPool(level: number): GeoRegion[] {
  const all = WORLD.askable;
  if (level === 1) return all.filter((r) => (r.rank <= 2 && !EASY_REMOVE.has(r.name)) || EASY_ADD.has(r.name));
  if (level === 2) return all.filter((r) => r.rank <= 3);
  return all;
}

export function statePool(level: number): GeoRegion[] {
  return US_STATES.askable.filter((r) => r.rank <= level);
}
