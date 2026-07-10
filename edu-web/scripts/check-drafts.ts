import { PrismaClient } from "@prisma/client";
const prisma = new PrismaClient();

function norm(s: string) { return s.toLowerCase().replace(/[^a-z0-9]+/g, " ").trim(); }

async function main() {
  const courses = await prisma.course.findMany({ select: { id: true, title: true }, orderBy: { title: "asc" } });
  for (const c of courses) {
    const all = await prisma.quizQuestion.findMany({
      where: { courseId: c.id, videoId: null },
      select: { id: true, prompt: true, options: true, correctIndex: true, explanation: true, isDraft: true },
      orderBy: { id: "asc" },
    });
    const drafts = all.filter((q) => q.isDraft);
    const pub = all.filter((q) => !q.isDraft);
    if (drafts.length === 0) continue;
    const pubPrompts = new Set(pub.map((q) => norm(q.prompt)));
    const draftPrompts = new Set<string>();
    const issues: string[] = [];

    drafts.forEach((q, i) => {
      const opts = q.options as string[];
      const tag = `  q${i}`;
      // option count
      if (opts.length !== 4) issues.push(`${tag} OPTION-COUNT=${opts.length}`);
      // length parity: correct answer conspicuously longest
      const lens = opts.map((o) => o.length);
      const maxLen = Math.max(...lens);
      const correctLen = lens[q.correctIndex];
      const secondLongest = [...lens].sort((a, b) => b - a)[1] ?? 0;
      if (correctLen === maxLen && maxLen > 0 && correctLen >= secondLongest * 1.4 && correctLen - secondLongest >= 8) {
        issues.push(`${tag} CORRECT-LONGEST (${correctLen} vs 2nd ${secondLongest})`);
      }
      // duplicate prompt vs published
      const np = norm(q.prompt);
      if (pubPrompts.has(np)) issues.push(`${tag} DUP-VS-PUBLISHED: "${q.prompt.slice(0,60)}"`);
      // duplicate within drafts
      if (draftPrompts.has(np)) issues.push(`${tag} DUP-WITHIN-DRAFTS: "${q.prompt.slice(0,60)}"`);
      draftPrompts.add(np);
      // instructor name
      const blob = (q.prompt + " " + opts.join(" ") + " " + (q.explanation ?? "")).toLowerCase();
      if (/\b(donald|timpson|instructor|professor|the lecturer)\b/.test(blob)) issues.push(`${tag} NAME/INSTRUCTOR-REF`);
      // arctan
      if (/\barctan\b/.test(blob)) issues.push(`${tag} ARCTAN (use tan^{-1})`);
      // BCE/CE era
      if (/\b(bce|ce)\b/.test(q.prompt.toLowerCase() + " " + opts.join(" ").toLowerCase())) issues.push(`${tag} BCE/CE era (prefer BC/AD)`);
      // correctIndex range
      if (q.correctIndex < 0 || q.correctIndex >= opts.length) issues.push(`${tag} BAD-CORRECT-INDEX=${q.correctIndex}`);
    });

    if (issues.length) {
      console.log(`\n### ${c.title}  (${drafts.length} drafts)`);
      issues.forEach((s) => console.log(s));
    }
  }
  await prisma.$disconnect();
}
main().catch(async (e) => { console.error(e); await prisma.$disconnect(); process.exit(1); });
