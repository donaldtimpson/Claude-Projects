import { PrismaClient } from "@prisma/client";
import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

const prisma = new PrismaClient();

type DraftQuestion = {
  prompt: string;
  options: string[];
  correctIndex: number;
  explanation?: string;
};

type DraftFile =
  | {
      scope: "video";
      videoId: string;
      questions: DraftQuestion[];
    }
  | {
      scope: "course";
      courseId: string;
      questions: DraftQuestion[];
    };

function validate(data: unknown, filename: string): DraftFile {
  if (!data || typeof data !== "object") throw new Error(`${filename}: not an object`);
  const d = data as Partial<DraftFile> & Record<string, unknown>;
  if (d.scope !== "video" && d.scope !== "course") throw new Error(`${filename}: scope must be "video" or "course"`);
  if (d.scope === "video" && typeof (d as Record<string, unknown>).videoId !== "string") throw new Error(`${filename}: missing videoId`);
  if (d.scope === "course" && typeof (d as Record<string, unknown>).courseId !== "string") throw new Error(`${filename}: missing courseId`);
  if (!Array.isArray(d.questions) || d.questions.length === 0) throw new Error(`${filename}: questions must be a non-empty array`);
  for (const [i, q] of d.questions.entries()) {
    if (typeof q.prompt !== "string" || !q.prompt.trim()) throw new Error(`${filename} q${i}: prompt required`);
    if (!Array.isArray(q.options) || q.options.length < 2) throw new Error(`${filename} q${i}: need ≥2 options`);
    if (q.options.some((o) => typeof o !== "string" || !o.trim())) throw new Error(`${filename} q${i}: all options must be non-empty strings`);
    if (typeof q.correctIndex !== "number" || q.correctIndex < 0 || q.correctIndex >= q.options.length) {
      throw new Error(`${filename} q${i}: correctIndex out of range`);
    }
  }
  return d as DraftFile;
}

async function main() {
  const draftsDir = join(process.cwd(), "scripts", "drafts");
  if (!existsSync(draftsDir)) {
    console.error(`No drafts directory found at ${draftsDir}`);
    process.exit(1);
  }

  const files = readdirSync(draftsDir).filter((f) => f.endsWith(".json"));
  if (files.length === 0) {
    console.error(`No .json draft files found in ${draftsDir}`);
    process.exit(1);
  }

  const dryRun = process.argv.includes("--dry-run");
  console.log(`Found ${files.length} draft file(s).${dryRun ? " (dry run)" : ""}`);

  let totalInserted = 0;
  let totalSkipped = 0;

  for (const file of files) {
    const path = join(draftsDir, file);
    let parsed: DraftFile;
    try {
      parsed = validate(JSON.parse(readFileSync(path, "utf8")), file);
    } catch (e) {
      console.error(`  ✗ ${file}: ${(e as Error).message}`);
      continue;
    }

    // Idempotency: if any drafts already exist for this target, skip the whole file.
    const targetWhere = parsed.scope === "video"
      ? { videoId: parsed.videoId, isDraft: true }
      : { courseId: parsed.courseId, videoId: null, isDraft: true };
    const existingDrafts = await prisma.quizQuestion.count({ where: targetWhere });
    if (existingDrafts > 0) {
      console.log(`  • ${file}: ${existingDrafts} draft(s) already imported — skipping`);
      totalSkipped += parsed.questions.length;
      continue;
    }

    // Position drafts after any existing published questions.
    const positionWhere = parsed.scope === "video"
      ? { videoId: parsed.videoId }
      : { courseId: parsed.courseId, videoId: null };
    const existingCount = await prisma.quizQuestion.count({ where: positionWhere });

    const rows = parsed.questions.map((q, i) => ({
      videoId: parsed.scope === "video" ? parsed.videoId : null,
      courseId: parsed.scope === "course" ? parsed.courseId : null,
      prompt: q.prompt.trim(),
      options: q.options,
      correctIndex: q.correctIndex,
      explanation: (q.explanation ?? "").trim(),
      position: existingCount + i,
      isDraft: true,
    }));

    if (dryRun) {
      console.log(`  ✓ ${file}: would insert ${rows.length} draft(s)`);
      totalInserted += rows.length;
      continue;
    }

    const result = await prisma.quizQuestion.createMany({ data: rows });
    console.log(`  ✓ ${file}: inserted ${result.count} draft(s)`);
    totalInserted += result.count;
  }

  console.log(`\nDone. inserted=${totalInserted} skipped=${totalSkipped}`);
  await prisma.$disconnect();
}

main().catch(async (e) => {
  console.error(e);
  await prisma.$disconnect();
  process.exit(1);
});
