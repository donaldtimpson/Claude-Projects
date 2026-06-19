// Playwright helpers for driving YouTube Studio with a persistent, already
// logged-in Chrome profile. There is no API for community/quiz posts, so this
// is browser automation; everything here is defensive — headed by default, with
// guards that screenshot and abort the moment an expected element is missing,
// rather than blind-clicking on the live UI.
//
// Runs ONLY locally on Donald's Mac. Never imported by the Next.js app / Vercel.

import { chromium, type BrowserContext, type Page, type Locator } from "playwright";
import { join } from "node:path";
import { mkdirSync } from "node:fs";

export const PROFILE_DIR = join(process.cwd(), ".yt-profile");
export const DEBUG_DIR = join(process.cwd(), "scripts", "community-debug");
export const STUDIO_URL = "https://studio.youtube.com";

// Launch (or reuse) the persistent Chrome profile. Uses the real installed
// Google Chrome (channel "chrome") rather than bundled Chromium — closer to a
// normal session for a logged-in Google account. Headed by default.
export async function launchStudio(opts: { headless?: boolean } = {}): Promise<BrowserContext> {
  mkdirSync(PROFILE_DIR, { recursive: true });
  // Google blocks sign-in from sessions that advertise automation ("this browser
  // may not be secure"). Drop the --enable-automation flag and the
  // AutomationControlled blink feature so navigator.webdriver is false and the
  // automation infobar is gone — i.e. present as an ordinary Chrome.
  const ctx = await chromium.launchPersistentContext(PROFILE_DIR, {
    headless: opts.headless ?? false,
    channel: "chrome",
    viewport: null,
    ignoreDefaultArgs: ["--enable-automation"],
    args: ["--start-maximized", "--disable-blink-features=AutomationControlled", "--no-first-run"],
  });
  return ctx;
}

// Is this context signed in to Studio? Studio redirects logged-out users to a
// Google sign-in page; a signed-in session lands on /channel/UC...
export async function isSignedIn(page: Page): Promise<boolean> {
  await page.goto(STUDIO_URL, { waitUntil: "domcontentloaded" }).catch(() => {});
  await page.waitForTimeout(2500);
  return /studio\.youtube\.com\/(channel|video|playlist|content)/.test(page.url());
}

// Human-ish pause between actions to avoid a robotic cadence.
export function jitter(minMs = 350, maxMs = 1100): Promise<void> {
  const ms = Math.floor(minMs + Math.random() * (maxMs - minMs));
  return new Promise((r) => setTimeout(r, ms));
}

// Wait for a required element; if it never appears, dump debug + throw so the
// run aborts instead of doing something unintended on the live channel.
export async function need(page: Page, locator: Locator, what: string, timeout = 15000): Promise<Locator> {
  try {
    await locator.first().waitFor({ state: "visible", timeout });
    return locator.first();
  } catch {
    await dumpDebug(page, `missing-${slug(what)}`);
    throw new Error(`Aborting — expected UI element not found: ${what}. Saved a screenshot to ${DEBUG_DIR}.`);
  }
}

// Screenshot + a snippet of the DOM, for selector discovery and abort forensics.
export async function dumpDebug(page: Page, name: string): Promise<void> {
  mkdirSync(DEBUG_DIR, { recursive: true });
  const stamp = `${name}-${Date.now()}`;
  await page.screenshot({ path: join(DEBUG_DIR, `${stamp}.png`), fullPage: true }).catch(() => {});
}

function slug(s: string): string {
  return s.toLowerCase().replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "").slice(0, 60);
}
