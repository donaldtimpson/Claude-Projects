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

// The post body IS the question — YouTube's quiz module holds only the answer
// choices + explanation, so the prompt goes in the caption, followed by the CTA.
function caption(prompt: string, lectureTitle: string, n: number, total: number, url: string): string {
  return `${prompt}\n\nPop quiz ${n}/${total} from ${lectureTitle} — pick your answer, then watch the full lecture:\n${url}`;
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
    const options = (q.options as unknown[]).map((o) => String(o));
    if (options.length < QUIZ_MIN_OPTIONS || options.length > QUIZ_MAX_OPTIONS) {
      throw new Error(`Q${i + 1}: ${options.length} options — YouTube quiz posts allow ${QUIZ_MIN_OPTIONS}–${QUIZ_MAX_OPTIONS}.`);
    }
    if (q.correctIndex < 0 || q.correctIndex >= options.length) {
      throw new Error(`Q${i + 1}: correctIndex ${q.correctIndex} out of range for ${options.length} options.`);
    }
    if (q.prompt.length > SOFT_QUESTION_MAX) warnings.push(`Q${i + 1} prompt is ${q.prompt.length} chars (soft cap ${SOFT_QUESTION_MAX})`);
    options.forEach((o, j) => {
      if (o.length > SOFT_OPTION_MAX) warnings.push(`Q${i + 1} option ${j + 1} is ${o.length} chars (soft cap ${SOFT_OPTION_MAX})`);
    });
    const cap = caption(q.prompt, video.title, i + 1, questions.length, url);
    if (cap.length > SOFT_CAPTION_MAX) warnings.push(`Q${i + 1} caption is ${cap.length} chars (soft cap ${SOFT_CAPTION_MAX})`);

    return {
      index: i,
      caption: cap,
      question: q.prompt,
      options,
      correctIndex: q.correctIndex,
      explanation: q.explanation ?? "",
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
