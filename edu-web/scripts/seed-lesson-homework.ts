import { PrismaClient } from "@prisma/client";
import { readFileSync } from "node:fs";
import { join } from "node:path";

// Seed the 19 Grammar-lesson homework assignments for a section: "Homework N"
// linked to lesson-drill "lesson-0N" (auto-graded — acing the 30-run earns full
// points, binary). Idempotent: skips any lesson already assigned to the section.
//
// Usage:
//   npx tsx scripts/seed-lesson-homework.ts <joinCode|sectionId>            # dry run
//   npx tsx scripts/seed-lesson-homework.ts <joinCode|sectionId> --apply    # write

const prisma = new PrismaClient();

const POINTS = 100; // equal weight per lesson; homework category credits an ace as full points

async function main() {
  const key = process.argv[2];
  const apply = process.argv.includes("--apply");
  if (!key) throw new Error("Pass a section join code or id: seed-lesson-homework.ts <joinCode|sectionId> [--apply]");

  // The bundled lesson banks are the source of truth for the slugs (lesson-01…19).
  const lessons = JSON.parse(
    readFileSync(join(process.cwd(), "lib/drills/grammar/data/lessons.json"), "utf8"),
  ) as { drills?: { slug: string; lesson?: number }[] } | { slug: string }[];
  const drills = Array.isArray(lessons) ? lessons : lessons.drills ?? [];
  const slugs = drills.map((d) => d.slug).filter((s) => /^lesson-\d+$/.test(s)).sort();
  if (slugs.length !== 19) console.warn(`⚠ expected 19 lesson slugs, found ${slugs.length}: ${slugs.join(", ")}`);

  const section = await prisma.section.findFirst({
    where: { OR: [{ joinCode: key.toUpperCase() }, { id: key }] },
    select: {
      id: true,
      name: true,
      course: { select: { title: true } },
      assignments: { select: { lessonSlug: true } },
    },
  });
  if (!section) throw new Error(`No section found for "${key}"`);
  console.log(`Section: ${section.course.title} · ${section.name} (${section.id})`);

  const already = new Set(section.assignments.map((a) => a.lessonSlug).filter(Boolean));
  const base = Date.parse("2026-01-01T00:00:00Z"); // deterministic, spaced createdAt → stable Homework 1…19 order

  const plan = slugs.map((slug, i) => ({
    n: i + 1,
    slug,
    title: `Homework ${i + 1}`,
    createdAt: new Date(base + i * 1000),
    skip: already.has(slug),
  }));

  for (const p of plan) {
    console.log(`  ${p.skip ? "skip (exists)" : apply ? "create" : "would create"}: ${p.title} → ${p.slug}`);
  }

  const toCreate = plan.filter((p) => !p.skip);
  if (!apply) {
    console.log(`\nDRY RUN — ${toCreate.length} to create, ${plan.length - toCreate.length} skipped. Re-run with --apply to write.`);
    return;
  }
  for (const p of toCreate) {
    await prisma.assignment.create({
      data: { sectionId: section.id, lessonSlug: p.slug, title: p.title, points: POINTS, createdAt: p.createdAt },
    });
  }
  console.log(`\n✓ Created ${toCreate.length} homework assignments (${plan.length - toCreate.length} already existed).`);
}

main().catch((e) => { console.error(e); process.exitCode = 1; }).finally(() => prisma.$disconnect());
