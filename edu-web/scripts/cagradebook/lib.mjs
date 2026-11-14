// lib.mjs — shared Playwright helpers for the cagradebook scripts.
import { chromium } from 'playwright';
import { mkdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

export const here = dirname(fileURLToPath(import.meta.url));
export const outDir = join(here, 'output');
mkdirSync(outDir, { recursive: true });
const START_URL = process.env.CAGRADEBOOK_URL || 'https://cagradebook.com/gradebook';

export async function open() {
  const ctx = await chromium.launchPersistentContext(join(here, '.session'), {
    headless: false,
    viewport: { width: 1440, height: 900 },
  });
  const page = ctx.pages()[0] || (await ctx.newPage());
  const shot = (name) => page.screenshot({ path: join(outDir, name), fullPage: true }).catch(() => {});

  // wait-or-scream: never blind-click. Screenshot + throw if the element is missing.
  async function need(locator, label, timeout = 15000) {
    try {
      await locator.first().waitFor({ state: 'visible', timeout });
      return locator.first();
    } catch (e) {
      await shot(`ERROR-${label.replace(/\W+/g, '-')}.png`);
      throw new Error(`Could not find: ${label} (screenshot saved). ${e.message}`);
    }
  }

  async function gotoGradebook() {
    await page.goto(START_URL, { waitUntil: 'domcontentloaded' });
    // The app redirects to /login client-side, so wait for the grid's toolbar.
    await need(page.getByRole('button', { name: /add assignment/i }), 'gradebook (session expired? run probe.mjs and log in)', 30000);
  }

  return { ctx, page, shot, need, gotoGradebook };
}

const MONTHS = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];

// Pick an ISO date (YYYY-MM-DD) in a read-only MudDatePicker by stepping months
// in its popover, then confirm the input shows it (M/D/YYYY).
export async function pickDate(page, picker, iso) {
  const [y, m, d] = iso.split('-').map(Number);
  const want = `${m}/${d}/${y}`;
  const input = picker.locator('input');
  for (let attempt = 0; attempt < 3; attempt++) {
    if ((await input.inputValue()) === want) return;
    try {
      await pickOnce(page, picker, y, m, d);
    } catch {
      // A missed click leaves the popover open or closed at random; reset and retry.
    }
    await page.waitForTimeout(400);
    if (await page.locator('.mud-picker-open').count()) await page.keyboard.press('Escape');
  }
  if ((await input.inputValue()) !== want) throw new Error(`Date picker shows ${await input.inputValue()}, wanted ${want}`);
}

async function pickOnce(page, picker, y, m, d) {
  await picker.locator('button').first().click();
  const pop = page.locator('.mud-picker-open').last();
  await pop.waitFor({ state: 'visible', timeout: 8000 });
  const target = `${MONTHS[m - 1]} ${y}`;
  for (let i = 0; i < 36; i++) {
    const shown = ((await pop.locator('.mud-picker-calendar-header-switch .mud-button-month').textContent()) || '').trim();
    if (shown === target) break;
    const [sm, sy] = shown.split(' ');
    const forward = Number(sy) * 12 + MONTHS.indexOf(sm) < y * 12 + (m - 1);
    await pop.locator(forward ? '.mud-picker-nav-button-next' : '.mud-picker-nav-button-prev').click();
    await page.waitForTimeout(150);
  }
  await pop.locator('button.mud-day:not(.mud-hidden)', { hasText: new RegExp(`^${d}$`) }).first().click();
  await page.waitForTimeout(250);
}
