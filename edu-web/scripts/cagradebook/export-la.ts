// export-la.ts — flatten the edu-web Linear Algebra gradebook into the
// assignment/cell list that push-grades.mjs writes into cagradebook.
//
//   npx tsx scripts/cagradebook/export-la.ts      # → output/la-grades.json
//
// Read-only. Columns mirror how cagradebook is set up for the section:
//   Attendance  one 1-pt column per lecture (present/late = 1, absent = Z, excused = X)
//   Quizzes     one column per lecture quiz, out of its question count; untaken = Z
//   Homework    one column per problem set that has at least one score; blank = unscored
//   Unit Tests  one column per Tests item that has at least one score
// Students are keyed by email; mapping.json links each email to its grid name.
// Uses a plain PrismaClient (TCP) — the Neon websocket adapter needs Node 22's
// global WebSocket.

import { PrismaClient } from "@prisma/client";
import { writeFileSync, mkdirSync } from "node:fs";
import { join } from "node:path";

(globalThis as { prisma?: PrismaClient }).prisma = new PrismaClient();
const SECTION_ID = process.env.LA_SECTION_ID || "cmtw3bl550001l504ugp8fias";
const OUT = join(process.cwd(), "scripts", "cagradebook", "output", "la-grades.json");

type Cell = number | "Z" | "X" | null;
type Column = { key: string; name: string; category: string; points: number; date: string; scores: Record<string, Cell> };

const day = (d: Date | null | undefined) => (d ?? new Date()).toISOString().slice(0, 10);
// cuid v1 embeds its creation time (base36 ms) in chars 1–8.
const cuidDate = (id: string) => new Date(parseInt(id.slice(1, 9), 36));

(async () => {
  const { getSectionGradebook } = await import("@/lib/gradebook");
  const db = (globalThis as { prisma?: PrismaClient }).prisma!;
  const gb = await getSectionGradebook(SECTION_ID);
  if (!gb) throw new Error(`No section ${SECTION_ID}`);

  const videos = await db.video.findMany({
    where: { id: { in: gb.lectures.map((l) => l.id) } },
    select: { id: true, publishedAt: true, _count: { select: { quizQuestions: { where: { isDraft: false } } } } },
  });
  const vMeta = new Map(videos.map((v) => [v.id, v]));
  // Homework date = due date, else the earliest linked lecture's publish date.
  const asg = await db.assignment.findMany({
    where: { sectionId: SECTION_ID },
    select: { id: true, createdAt: true, dueAt: true, problemSet: { select: { videos: { select: { video: { select: { publishedAt: true } } } } } } },
  });
  const aDate = new Map(
    asg.map((a) => {
      const linked = (a.problemSet?.videos ?? []).map((v) => v.video.publishedAt).filter((d): d is Date => !!d);
      linked.sort((x, y) => x.getTime() - y.getTime());
      return [a.id, a.dueAt ?? linked[0] ?? null];
    }),
  );

  const lectureNo = (title: string) => (title.match(/Lecture\s+(\d+)/i) || [])[1] ?? "?";
  const columns: Column[] = [];

  for (const l of gb.lectures) {
    const scores: Record<string, Cell> = {};
    for (const s of gb.students) {
      const st = s.attendanceByVideo[l.id];
      scores[s.email] = st === "absent" ? "Z" : st === "excused" ? "X" : 1;
    }
    columns.push({ key: `att:${l.id}`, name: `Attendance – Lecture ${lectureNo(l.title)}`, category: "Attendance", points: 1, date: day(vMeta.get(l.id)?.publishedAt), scores });
  }

  for (const q of gb.quizzes) {
    const n = vMeta.get(q.videoId)?._count.quizQuestions ?? 10;
    const scores: Record<string, Cell> = {};
    for (const s of gb.students) {
      const pct = s.quizByVideo[q.videoId];
      scores[s.email] = pct === undefined ? "Z" : Math.round((pct / 100) * n * 100) / 100;
    }
    columns.push({ key: `quiz:${q.videoId}`, name: `Quiz – Lecture ${lectureNo(q.title)}`, category: "Quizzes", points: n, date: day(vMeta.get(q.videoId)?.publishedAt), scores });
  }

  let lastHwDate = day(null);
  for (const a of gb.assignments) {
    const scores: Record<string, Cell> = {};
    for (const s of gb.students) scores[s.email] = s.hwByAssignment[a.id]?.score ?? null;
    if (Object.values(scores).every((v) => v === null)) continue;
    // Unlinked sets inherit the previous set's date (columns are in section order).
    const d = aDate.get(a.id);
    if (d) lastHwDate = day(d);
    columns.push({ key: `hw:${a.id}`, name: a.title, category: "Homework", points: a.points, date: lastHwDate, scores });
  }

  for (const c of gb.customCategories) {
    for (const it of c.items) {
      const scores: Record<string, Cell> = {};
      for (const s of gb.students) scores[s.email] = s.customScores[it.id] ?? null;
      if (Object.values(scores).every((v) => v === null)) continue;
      columns.push({ key: `item:${it.id}`, name: it.name, category: "Unit Tests", points: it.maxPoints, date: day(cuidDate(it.id)), scores });
    }
  }

  mkdirSync(join(OUT, ".."), { recursive: true });
  const students = gb.students.map((s) => ({ email: s.email, name: s.name, eduwebGrade: s.currentGrade }));
  writeFileSync(OUT, JSON.stringify({ exportedAt: new Date().toISOString(), section: gb.section.name, students, columns }, null, 2));
  console.log(`${columns.length} columns, ${students.length} students → ${OUT}`);
  process.exit(0);
})();
