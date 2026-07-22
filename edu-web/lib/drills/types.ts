// Interactive practice drills — shared types.
//
// A drill type is pure data + pure functions: a `DrillDef` exposes `generate()`
// which returns a fresh random `Problem`. One generic `DrillPlayer` renders and
// grades ANY drill — the only thing that varies is the answer-input mode, modeled
// as a discriminated union on `Problem.input`. The correct answer lives inside the
// input descriptor, so grading is mechanical and generators stay self-contained.
//
// Unlike quizzes (a stored bank of authored QuizQuestion rows), drills generate an
// endless stream of problems in the browser — no DB, no authoring.

// A single rendered chunk of prompt/option/feedback text. Plain string by default;
// `{ tex }` when it must render as math (KaTeX, via components/drills/Tex.tsx).
export type Renderable = string | { tex: string };

// ---- Input modes (discriminated union) -------------------------------------
// The player switches on `kind` to pick BOTH the input widget and the grader.

// A single typed numeric answer (arithmetic). Exact match unless `tolerance` set.
export type NumericInput = {
  kind: "numeric";
  answer: number;
  tolerance?: number; // absolute difference allowed (e.g. 0.01 for rounded values)
  unit?: string; // optional suffix shown after the box
};

// Multiple choice (unit circle — pick the exact value). Options render as Renderables.
// `optionImages` (parallel to options) shows a flag/image above each label — e.g. US state
// flags in "Name the State", which have no emoji. null = no image for that option.
export type ChoiceInput = {
  kind: "choice";
  options: Renderable[];
  correctIndex: number;
  optionImages?: (string | null)[];
};

// Tap-to-locate: the map IS the input. The player renders an interactive map (geography
// drills) and grades a click — correct when the clicked region id === targetId.
export type MapTapInput = {
  kind: "mapTap";
  map: "world" | "us";
  targetId: string;
};

// Several typed numeric fields (vectors — vₓ and v_y). Each graded independently;
// the problem is correct only if EVERY field passes.
export type FieldsInput = {
  kind: "fields";
  fields: { label: Renderable; answer: number; tolerance?: number; unit?: string }[];
};

export type DrillInput = NumericInput | ChoiceInput | FieldsInput | MapTapInput;

// ---- Optional diagram (pure data; DrillDiagram renders inline SVG) ----------
export type DiagramSpec =
  | { kind: "vector"; magnitude: number; angleDeg: number; component?: "x" | "y" }
  | { kind: "unit-circle"; angleRad: number; fn: "sin" | "cos" | "tan" }
  // Identify drills ("Name the Country/State"): the map with one region highlighted.
  | { kind: "geoMap"; map: "world" | "us"; highlightId: string };

// ---- A generated problem ----------------------------------------------------
export type Problem = {
  id: string; // React key / dedupe — unique per generated problem
  prompt: Renderable;
  input: DrillInput;
  explanation?: Renderable;
  diagram?: DiagramSpec;
};

// ---- Difficulty -------------------------------------------------------------
export type Level = 1 | 2 | 3;

// ---- The drill definition (one per drill type) ------------------------------
export type DrillDef = {
  slug: string; // URL segment, e.g. "arithmetic" — STABLE id
  title: string;
  blurb: string;
  icon: string; // emoji shown on the hub card
  subject: string; // "Mathematics" etc.
  levels: { value: Level; label: string }[];
  generate: (level: Level) => Problem; // pure, synchronous
};

// ---- Session mechanics ------------------------------------------------------
export type DrillMode =
  | { type: "count"; n: number } // practice a fixed number of problems
  | { type: "timed"; seconds: number }; // beat the clock

// What a finished session reports back (to recordDrillSession for badges/streak).
export type DrillSummary = {
  slug: string;
  level: Level;
  total: number; // problems answered
  correct: number;
  bestStreak: number; // longest in-session correct run
  mode: "count" | "timed";
  durationSec: number;
  score?: number; // arcade points for a Rapid Fire (timed) run; omitted for practice
};
