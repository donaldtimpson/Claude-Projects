import { PrismaClient, Prisma } from "@prisma/client";
import { writeFileSync } from "node:fs";
import { join } from "node:path";

const prisma = new PrismaClient();

// Usage:
//   npx tsx scripts/export-exemplars.ts
//     → all published questions → scripts/exemplars.json (style guide, unchanged default)
//   npx tsx scripts/export-exemplars.ts --course <courseId | title-substring> [--out <path>]
//     → one subject's published questions, topic-ordered → scripts/bank-<filter>.json
//       (the "anchor bank" for reusing questions in a sibling offering)
function parseArgs(argv: string[]) {
  let course: string | undefined;
  let out: string | undefined;
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--course") course = argv[++i];
    else if (argv[i] === "--out") out = argv[++i];
  }
  return { course, out };
}

function slugify(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "") || "filtered";
}

async function main() {
  const { course, out } = parseArgs(process.argv.slice(2));

  // A course filter matches either an exact Course.id or a case-insensitive
  // title substring, on whichever side owns the question (video's course, or
  // the course directly for playlist-test questions).
  let where: Prisma.QuizQuestionWhereInput = { isDraft: false };
  if (course) {
    const byTitle = { title: { contains: course, mode: "insensitive" as const } };
    where = {
      isDraft: false,
      OR: [
        { video: { courseId: course } },
        { courseId: course },
        { video: { course: byTitle } },
        { course: byTitle },
      ],
    };
  }

  const questions = await prisma.quizQuestion.findMany({
    where,
    include: {
      video: { select: { title: true, position: true, course: { select: { title: true } } } },
      course: { select: { title: true } },
    },
  });

  // Topic-ordered: group questions by their source lecture (video position), so
  // the bank reads as a topic-by-topic list. Course-scoped (test) questions have
  // no video; sort them last. Within a lecture, keep authored order (position).
  questions.sort((a, b) => {
    const pa = a.video?.position ?? Number.MAX_SAFE_INTEGER;
    const pb = b.video?.position ?? Number.MAX_SAFE_INTEGER;
    if (pa !== pb) return pa - pb;
    return a.position - b.position;
  });

  const exemplars = questions.map((q) => ({
    scope: q.videoId ? "video" : "course",
    courseTitle: q.video?.course?.title ?? q.course?.title ?? null,
    videoTitle: q.video?.title ?? null,
    lecturePosition: q.video?.position ?? null,
    prompt: q.prompt,
    options: q.options as string[],
    correctIndex: q.correctIndex,
    explanation: q.explanation,
  }));

  const defaultName = course ? `bank-${slugify(course)}.json` : "exemplars.json";
  const outPath = out
    ? (out.startsWith("/") ? out : join(process.cwd(), out))
    : join(process.cwd(), "scripts", defaultName);
  writeFileSync(outPath, JSON.stringify(exemplars, null, 2));
  console.log(
    `Wrote ${exemplars.length} ${course ? `questions for "${course}"` : "exemplars"} to ${outPath}`
  );

  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
