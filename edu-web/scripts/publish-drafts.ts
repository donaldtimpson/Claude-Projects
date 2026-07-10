import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();
async function main() {
  const dryRun = process.argv.includes("--dry-run");
  const before = await prisma.quizQuestion.count({ where: { isDraft: true } });
  console.log(`${before} draft question(s) currently hidden from students.${dryRun ? " (dry run)" : ""}`);
  if (dryRun) { await prisma.$disconnect(); return; }
  const res = await prisma.quizQuestion.updateMany({ where: { isDraft: true }, data: { isDraft: false } });
  const after = await prisma.quizQuestion.count({ where: { isDraft: true } });
  console.log(`Published ${res.count} question(s). Remaining drafts: ${after}.`);
  await prisma.$disconnect();
}
main().catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
