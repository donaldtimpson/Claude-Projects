// Pure, browser-free builder for the YouTube Community Quiz posts. Reads a
// lecture's published quiz questions and turns them into an ordered list of
// scheduled posts. No Playwright here — this is the testable half of the
// pipeline (see scripts/post-quiz-community.ts for the automation half).
//
// There is NO YouTube API for community/quiz posts, so the posting itself is
// browser automation; this module only prepares WHAT to post and WHEN.

import type { PrismaClient } from "@prisma/client";

// YouTube's interactive Quiz post allows 2–5 options. Length caps below are
// conservative guesses to surface obviously-too-long fields early; the real
// limits get confirmed against the live UI during the selector spike. Exceeding
// a soft cap warns (doesn't throw) so a borderline field still gets a chance.
export const QUIZ_MIN_OPTIONS = 2;
export const QUIZ_MAX_OPTIONS = 5;
export const SOFT_QUESTION_MAX = 140;
export const SOFT_OPTION_MAX = 90;
export const SOFT_CAPTION_MAX = 700;

const DEFAULT_SITE_URL = "https://timpson-lyceum.vercel.app";

export type QuizPost = {
  index: number; // 0-based, in question order
  caption: string; // the post body text (framing + CTA link)
  question: string;
  options: string[];
  correctIndex: number;
  explanation: string; // "" when none
  scheduledFor: Date;
};

export type BuiltQuiz = {
  youtubeVideoId: string;
  videoId: string; // Prisma Video.id (used in the lecture URL)
  courseId: string;
  courseTitle: string;
  lectureTitle: string;
  url: string;
  posts: QuizPost[];
  warnings: string[];
};

export type BuildOptions = {
  start: Date;
  intervalHours?: number; // default 12
  siteUrl?: string;
};

// ---- LaTeX -> plain text -------------------------------------------------
// Quiz prompts/options/explanations are authored with KaTeX for the website.
// YouTube community posts are PLAIN TEXT — a "$x_1$" would post literally, so
// math is flattened to unicode here (and only here; the DB keeps the LaTeX).
const SUB: Record<string, string> = { "0":"₀","1":"₁","2":"₂","3":"₃","4":"₄","5":"₅","6":"₆","7":"₇","8":"₈","9":"₉","+":"₊","-":"₋","=":"₌","(":"₍",")":"₎","a":"ₐ","e":"ₑ","h":"ₕ","i":"ᵢ","j":"ⱼ","k":"ₖ","l":"ₗ","m":"ₘ","n":"ₙ","o":"ₒ","p":"ₚ","r":"ᵣ","s":"ₛ","t":"ₜ","u":"ᵤ","v":"ᵥ","x":"ₓ" };
const SUP: Record<string, string> = { "0":"⁰","1":"¹","2":"²","3":"³","4":"⁴","5":"⁵","6":"⁶","7":"⁷","8":"⁸","9":"⁹","+":"⁺","-":"⁻","=":"⁼","(":"⁽",")":"⁾","n":"ⁿ","i":"ⁱ" };
const CMD: Record<string, string> = {
  "\\cdot":"·", "\\times":"×", "\\div":"÷", "\\pm":"±", "\\mp":"∓",
  "\\neq":"≠", "\\ne":"≠", "\\leq":"≤", "\\le":"≤", "\\geq":"≥", "\\ge":"≥",
  "\\approx":"≈", "\\equiv":"≡", "\\sim":"~", "\\infty":"∞",
  "\\to":"→", "\\rightarrow":"→", "\\Rightarrow":"⇒", "\\leftarrow":"←", "\\mapsto":"↦",
  "\\in":"∈", "\\notin":"∉", "\\subset":"⊂", "\\subseteq":"⊆", "\\cup":"∪", "\\cap":"∩",
  "\\emptyset":"∅", "\\forall":"∀", "\\exists":"∃", "\\sum":"∑", "\\prod":"∏", "\\int":"∫",
  "\\sqrt":"√", "\\partial":"∂", "\\nabla":"∇", "\\dots":"…", "\\cdots":"…", "\\ldots":"…",
  "\\alpha":"α","\\beta":"β","\\gamma":"γ","\\delta":"δ","\\epsilon":"ε","\\theta":"θ",
  "\\lambda":"λ","\\mu":"μ","\\pi":"π","\\rho":"ρ","\\sigma":"σ","\\tau":"τ","\\phi":"φ",
  "\\omega":"ω","\\Delta":"Δ","\\Sigma":"Σ","\\Omega":"Ω",
};

function mapRun(run: string, table: Record<string, string>): string | null {
  let out = "";
  for (const ch of run) {
    const m = table[ch];
    if (!m) return null; // not fully representable — leave the run alone
    out += m;
  }
  return out;
}

// Rewrites the CONTENTS of one math span. Never sees a "$".
function convertMathSpan(body: string): string {
  let s = body;
  // \frac{a}{b} -> a/b   (also \tfrac, \dfrac)
  s = s.replace(/\\[tdc]?frac\s*\{([^{}]*)\}\s*\{([^{}]*)\}/g, "$1/$2");
  // \text{...}, \mathrm{...}, \mathbb{R} -> inner
  s = s.replace(/\\(?:text|mathrm|mathbf|mathbb|operatorname)\s*\{([^{}]*)\}/g, "$1");
  // named commands (longest first so \leq beats \le)
  for (const k of Object.keys(CMD).sort((a, b) => b.length - a.length)) {
    s = s.split(k).join(CMD[k]);
  }
  // sub/superscripts: _{...} / ^{...} and single-char _x / ^2
  s = s.replace(/([_^])\{([^{}]*)\}/g, (m, kind, inner) =>
    mapRun(inner, kind === "_" ? SUB : SUP) ?? inner);
  s = s.replace(/([_^])(\w)/g, (m, kind, ch) =>
    mapRun(ch, kind === "_" ? SUB : SUP) ?? ch);
  // spacing macros and sizing wrappers
  s = s.replace(/\\(?:left|right|quad|qquad|,|;|:|!)/g, " ");
  // any leftover \command (\tan, \sin, \log, \lim, ...) -> its bare name
  return s.replace(/\\([a-zA-Z]+)/g, "$1");
}

// A "$" in this catalog is not always math: College Algebra writes currency
// ("invests $5,000") and Computation Theory uses a bare "$" as a PDA
// bottom-of-stack marker. So only a PAIRED span whose body actually carries a
// LaTeX marker (\ _ ^ {) is rewritten — everything else is left verbatim.
// Under-converting is safe here; eating a dollar sign changes what a question
// means. Quiz text is authored in plain unicode anyway, so this is a backstop.
export function texToPlain(input: string): string {
  const out = input.replace(/\$\$?([^$]+)\$\$?/g, (whole, body: string) =>
    /[\\_^{]/.test(body) ? convertMathSpan(body) : whole);
  return out.replace(/[ \t]{2,}/g, " ").trim();
}


// The post body IS the question — YouTube's quiz module holds only the answer
// choices + explanation, so the prompt goes in the caption, followed by a
// curiosity-gap CTA: pose the question, then dangle the "why" to drive the click.
function caption(prompt: string, url: string): string {
  return `${prompt}\n\nThink you've got it? The "why" is in the lecture 👇\n${url}`;
}

// Reads the published quiz for a video (by youtubeVideoId) and lays the
// questions out as posts spaced `intervalHours` apart starting at `start`.
export async function buildQuizPosts(
  prisma: PrismaClient,
  youtubeVideoId: string,
  opts: BuildOptions,
): Promise<BuiltQuiz> {
  const intervalHours = opts.intervalHours ?? 12;
  const siteUrl = (opts.siteUrl ?? process.env.NEXT_PUBLIC_SITE_URL ?? DEFAULT_SITE_URL).replace(/\/$/, "");

  const video = await prisma.video.findUnique({
    where: { youtubeVideoId },
    select: { id: true, courseId: true, title: true, course: { select: { title: true } } },
  });
  if (!video) throw new Error(`No Video row for youtubeVideoId "${youtubeVideoId}".`);

  // Canonical published-quiz query (mirrors app/api/quiz/route.ts).
  const questions = await prisma.quizQuestion.findMany({
    where: { videoId: video.id, isDraft: false },
    orderBy: { position: "asc" },
    select: { prompt: true, options: true, correctIndex: true, explanation: true },
  });
  if (questions.length === 0) {
    throw new Error(`No published quiz questions for "${video.title}" (${youtubeVideoId}). Publish the quiz first.`);
  }

  const url = `${siteUrl}/courses/${video.courseId}/${video.id}`;
  const warnings: string[] = [];
  if (questions.length !== 10) warnings.push(`expected 10 questions, found ${questions.length}`);

  const startMs = opts.start.getTime();
  const stepMs = intervalHours * 3_600_000;

  const posts: QuizPost[] = questions.map((q, i) => {
    const prompt = texToPlain(q.prompt);
    const options = (q.options as unknown[]).map((o) => texToPlain(String(o)));
    const explanation = texToPlain(q.explanation ?? "");
    if (options.length < QUIZ_MIN_OPTIONS || options.length > QUIZ_MAX_OPTIONS) {
      throw new Error(`Q${i + 1}: ${options.length} options — YouTube quiz posts allow ${QUIZ_MIN_OPTIONS}–${QUIZ_MAX_OPTIONS}.`);
    }
    if (q.correctIndex < 0 || q.correctIndex >= options.length) {
      throw new Error(`Q${i + 1}: correctIndex ${q.correctIndex} out of range for ${options.length} options.`);
    }
    if (prompt.length > SOFT_QUESTION_MAX) warnings.push(`Q${i + 1} prompt is ${prompt.length} chars (soft cap ${SOFT_QUESTION_MAX})`);
    options.forEach((o, j) => {
      if (o.length > SOFT_OPTION_MAX) warnings.push(`Q${i + 1} option ${j + 1} is ${o.length} chars (soft cap ${SOFT_OPTION_MAX})`);
    });
    const cap = caption(prompt, url);
    if (cap.length > SOFT_CAPTION_MAX) warnings.push(`Q${i + 1} caption is ${cap.length} chars (soft cap ${SOFT_CAPTION_MAX})`);

    return {
      index: i,
      caption: cap,
      question: prompt,
      options,
      correctIndex: q.correctIndex,
      explanation,
      scheduledFor: new Date(startMs + i * stepMs),
    };
  });

  return {
    youtubeVideoId,
    videoId: video.id,
    courseId: video.courseId,
    courseTitle: video.course.title,
    lectureTitle: video.title,
    url,
    posts,
    warnings,
  };
}

// Default first-post time: next day at 09:00 local. Keeps posts off "right now"
// so the whole 5-day run lands at a sensible hour.
export function defaultStart(now: Date): Date {
  const d = new Date(now);
  d.setDate(d.getDate() + 1);
  d.setHours(9, 0, 0, 0);
  return d;
}

// Parse a "YYYY-MM-DD HH:mm" (local) --start value. Throws on malformed input.
export function parseStart(s: string): Date {
  const m = s.match(/^(\d{4})-(\d{2})-(\d{2})[ T](\d{2}):(\d{2})$/);
  if (!m) throw new Error(`--start must look like "YYYY-MM-DD HH:mm" (got "${s}").`);
  const [, y, mo, da, h, mi] = m.map(Number) as unknown as number[];
  const d = new Date(y, mo - 1, da, h, mi, 0, 0);
  if (Number.isNaN(d.getTime())) throw new Error(`--start is not a valid date/time ("${s}").`);
  return d;
}
