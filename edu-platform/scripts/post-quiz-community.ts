// Schedule a lecture's 10 quiz questions as YouTube Community Quiz posts, 12h
// apart, by automating the youtube.com composer with a persistent logged-in
// Chrome profile (there is NO API for community/quiz posts). Local only.
//
// One-time setup: npx tsx scripts/yt-community-auth.ts  (log in once)
//
// Usage:
//   npx tsx scripts/post-quiz-community.ts --video <youtubeVideoId> [options]
// Options:
//   --start "YYYY-MM-DD HH:mm"   first post time (local); default tomorrow 09:00
//   --interval-hours <n>         spacing between posts; default 12
//   --dry-run                    build the FIRST post + set its schedule, screenshot,
//                                and ABORT before confirming (nothing is posted)
//   --force                      re-run even if a marker file already exists
//
// Safety: headed browser, aborts (with a screenshot) if any expected control is
// missing, reads the date back before trusting it, and — even on a real run —
// SCHEDULES posts so you can review/delete them in YouTube Studio before they go live.

import { PrismaClient } from "@prisma/client";
import { mkdirSync, existsSync, writeFileSync } from "node:fs";
import { join } from "node:path";
import type { BrowserContext, Page } from "playwright";
import { buildQuizPosts, defaultStart, parseStart, type QuizPost } from "../lib/community-post";
import { launchStudio, need, jitter, dumpDebug } from "../lib/yt-studio";

const CHANNEL = "UCkV7A7n4H0880ia0Z5DuDZw";
const COMMUNITY_URL = `https://www.youtube.com/channel/${CHANNEL}/community`;
const MARKER_DIR = join(process.cwd(), "scripts", "community-posts");

const fmtDate = (d: Date) => d.toLocaleDateString("en-US", { month: "short", day: "numeric", year: "numeric" });
const fmtTime = (d: Date) => d.toLocaleTimeString("en-US", { hour: "numeric", minute: "2-digit" });

// Round to the nearest 15 minutes — YouTube's time picker only offers :00/:15/:30/:45.
function round15(d: Date): Date {
  const r = new Date(d);
  const m = r.getMinutes();
  r.setMinutes(Math.round(m / 15) * 15, 0, 0);
  return r;
}

// Load a fresh community page and return the "Add a quiz" button once the
// composer is ready. The masthead "Create" button is flaky across reloads and
// isn't actually required (the composer toolbar renders by default), so it's
// best-effort; we anchor on "Add a quiz" and reload once if it's slow.
async function openComposer(page: Page) {
  for (let attempt = 0; attempt < 3; attempt++) {
    await page.goto(COMMUNITY_URL, { waitUntil: "domcontentloaded" });
    await page.waitForTimeout(4500);
    const create = page.getByRole("button", { name: "Create" }).first();
    if (await create.isVisible().catch(() => false)) await create.click().catch(() => {});
    const quiz = page.getByRole("button", { name: "Add a quiz" }).first();
    if (await quiz.isVisible().catch(() => false)) return quiz;
    await page.waitForTimeout(3000);
    if (await quiz.isVisible().catch(() => false)) return quiz;
  }
  await dumpDebug(page, "composer-not-ready");
  throw new Error("Aborting — composer (Add a quiz) not available after retries.");
}

async function fillOnePost(page: Page, post: QuizPost, when: Date, dryRun: boolean): Promise<void> {
  const quizBtn = await openComposer(page);
  await jitter();
  await quizBtn.click();
  await page.waitForTimeout(1200);

  // Answers (default 2 fields; add the rest).
  await (await need(page, page.getByPlaceholder("Answer 1"), "Answer 1 field")).fill(post.options[0]);
  await page.getByPlaceholder("Answer 2").fill(post.options[1]);
  for (let k = 2; k < post.options.length; k++) {
    await page.getByRole("button", { name: "Add answer" }).first().click();
    await jitter(200, 500);
    await page.getByPlaceholder(`Answer ${k + 1}`).fill(post.options[k]);
  }

  // Mark the correct answer (option 0 is correct by default).
  if (post.correctIndex !== 0) {
    const toggles = page.getByRole("button", { name: /correct/i });
    const t = toggles.nth(post.correctIndex);
    if ((await t.getAttribute("aria-pressed").catch(() => "")) !== "true") await t.click();
  }

  // Explanation (optional).
  if (post.explanation.trim()) {
    await page.getByPlaceholder("Add an explanation (optional)").fill(post.explanation).catch(() => {});
  }

  // Caption = the question prompt + CTA. insertText keeps newlines without firing Enter.
  await (await need(page, page.locator("[contenteditable='true']"), "caption box")).click();
  await jitter();
  await page.keyboard.insertText(post.caption);
  await page.waitForTimeout(600);

  // Confirm the post became valid before touching the schedule controls.
  const postBtn = page.getByRole("button", { name: "Post" }).first();
  if ((await postBtn.getAttribute("aria-disabled").catch(() => "")) === "true") {
    await dumpDebug(page, "post-still-disabled");
    throw new Error("Aborting — the post never became valid (Post button stayed disabled).");
  }

  // Open the schedule UI.
  await (await need(page, page.getByRole("button", { name: "Action menu" }), "composer Action menu")).click();
  await jitter();
  await (await need(page, page.getByRole("menuitem", { name: /schedul/i }), "Schedule post menu item")).click();
  await page.waitForTimeout(1200);

  // ---- Date: open calendar, click the target day, READ IT BACK to confirm ----
  await (await need(page, page.locator("#date-picker"), "date picker trigger")).click();
  await page.waitForTimeout(800);
  const targetDay = String(when.getDate());
  const cells = page.locator(".calendar-day");
  const total = await cells.count();
  let clicked = false;
  for (let i = 0; i < total; i++) {
    const c = cells.nth(i);
    if (!(await c.isVisible().catch(() => false))) continue;
    if ((await c.getAttribute("aria-disabled").catch(() => "")) === "true") continue;
    if ((await c.innerText().catch(() => "")).trim() !== targetDay) continue;
    await c.click();
    clicked = true;
    break;
  }
  if (!clicked) { await dumpDebug(page, "date-not-found"); throw new Error(`Aborting — no selectable calendar day "${targetDay}".`); }
  await page.waitForTimeout(500);
  const shownDate = (await page.locator("#date-label-text").innerText().catch(() => "")).trim();
  if (shownDate !== fmtDate(when)) {
    await dumpDebug(page, "date-mismatch");
    throw new Error(`Aborting — date readback "${shownDate}" != expected "${fmtDate(when)}".`);
  }

  // ---- Time: open dropdown, pick the matching 15-min option ----
  await (await need(page, page.getByRole("button", { name: /\b\d{1,2}:\d{2}\s?(AM|PM)\b/i }), "time field")).click();
  await page.waitForTimeout(600);
  const timeStr = fmtTime(when);
  await (await need(page, page.getByRole("option", { name: timeStr, exact: true }), `time option "${timeStr}"`)).click();
  await page.waitForTimeout(500);

  await dumpDebug(page, `scheduled-${post.index + 1}-${dryRun ? "dryrun" : "live"}`);

  if (dryRun) {
    console.log(`  [dry-run] post #${post.index + 1} composed + schedule set to ${shownDate} ${timeStr}; NOT confirming.`);
    return;
  }

  // ---- Confirm ----
  await (await need(page, page.getByRole("button", { name: /^Schedule$/ }), "Schedule confirm button")).click();
  await page.waitForTimeout(3500); // let it submit
  console.log(`  ✓ scheduled post #${post.index + 1} for ${shownDate} ${timeStr}`);
}

async function main() {
  const args = process.argv.slice(2);
  const dryRun = args.includes("--dry-run");
  const force = args.includes("--force");
  const get = (flag: string) => { const i = args.indexOf(flag); return i !== -1 ? args[i + 1] : undefined; };
  const youtubeVideoId = get("--video");
  if (!youtubeVideoId) { console.error("Required: --video <youtubeVideoId>"); process.exit(1); }
  const intervalHours = get("--interval-hours") ? Number(get("--interval-hours")) : 12;
  const start = round15(get("--start") ? parseStart(get("--start")!) : defaultStart(new Date()));
  const from = get("--from") ? Math.max(1, Number(get("--from"))) : 1; // 1-based; resume mid-run

  const marker = join(MARKER_DIR, `${youtubeVideoId}.json`);
  if (!dryRun && !force && existsSync(marker)) {
    console.error(`Already scheduled (marker ${marker} exists). Use --force to re-run.`);
    process.exit(1);
  }

  const prisma = new PrismaClient();
  const built = await buildQuizPosts(prisma, youtubeVideoId, { start, intervalHours });
  await prisma.$disconnect();

  // Snap each post's schedule to a 15-min boundary for the picker.
  const whens = built.posts.map((p) => round15(p.scheduledFor));

  console.log(`\n${built.lectureTitle}`);
  console.log(`${built.posts.length} quiz posts, every ${intervalHours}h, starting ${fmtDate(whens[0])} ${fmtTime(whens[0])}`);
  if (built.warnings.length) console.log(`warnings: ${built.warnings.join("; ")}`);
  whens.forEach((w, i) => console.log(`  #${i + 1}  ${fmtDate(w)} ${fmtTime(w)}  — correct: ${built.posts[i].options[built.posts[i].correctIndex]}`));
  console.log("");

  let ctx: BrowserContext | null = null;
  try {
    ctx = await launchStudio();
    const page = ctx.pages()[0] ?? (await ctx.newPage());

    const startIdx = from - 1;
    const endIdx = dryRun ? startIdx + 1 : built.posts.length;
    for (let i = startIdx; i < endIdx; i++) {
      console.log(`${dryRun ? "[dry-run] " : ""}post ${i + 1}/${built.posts.length}…`);
      await fillOnePost(page, built.posts[i], whens[i], dryRun);
      if (!dryRun && i < endIdx - 1) await page.waitForTimeout(4000 + Math.random() * 3000); // pace between posts
    }

    if (!dryRun) {
      mkdirSync(MARKER_DIR, { recursive: true });
      writeFileSync(marker, JSON.stringify({
        youtubeVideoId, lectureTitle: built.lectureTitle, url: built.url, intervalHours,
        scheduled: built.posts.map((p, i) => ({ index: p.index + 1, when: whens[i].toISOString(), correctIndex: p.correctIndex })),
      }, null, 2));
      console.log(`\n✓ Scheduled ${built.posts.length} posts. Review them in YouTube Studio (Content → Posts → Scheduled) before they publish.`);
      console.log(`  marker: ${marker}`);
    } else {
      console.log(`\n[dry-run] Looked good? Re-run without --dry-run to schedule all ${built.posts.length}.`);
    }
  } finally {
    if (ctx) await ctx.close();
  }
}

main().catch((e) => { console.error(e); process.exit(1); });
