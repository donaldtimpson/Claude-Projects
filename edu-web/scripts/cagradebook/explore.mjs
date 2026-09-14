// explore.mjs — guided, READ-ONLY, auto-capturing tour of cagradebook.com
//
// Opens a real browser. YOU log in and click through each screen you want me
// to see. The script snapshots the page AUTOMATICALLY whenever it changes
// (saving HTML + a full-page screenshot into ./output). No terminal input
// needed. When you're finished, just CLOSE the browser window — the script
// then exits on its own.
//
// Nothing is ever written to the gradebook. Your password only goes into the
// real login form, never into any file. The session is kept in ./.session
// (gitignored) so future runs stay logged in.

import { chromium } from 'playwright';
import { mkdirSync, writeFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, 'output');
const userDataDir = join(here, '.session');
mkdirSync(outDir, { recursive: true });

const START_URL = process.env.CAGRADEBOOK_URL || 'https://cagradebook.com/gradebook';
const MAX_SNAPS = 100;

const ctx = await chromium.launchPersistentContext(userDataDir, {
  headless: false,
  viewport: { width: 1440, height: 900 },
});

const page = ctx.pages()[0] || (await ctx.newPage());
await page.goto(START_URL, { waitUntil: 'domcontentloaded' }).catch(() => {});

let n = 0;
let lastHash = '';

// cheap content fingerprint so we only save when the page meaningfully changes
const hashOf = (s) => `${s.length}:${s.slice(0, 200)}:${s.slice(-200)}`;

async function snapshot(reason) {
  if (n >= MAX_SNAPS) return;
  let html;
  try {
    html = await page.content();
  } catch {
    return; // page navigating/closed
  }
  const h = hashOf(html);
  if (h === lastHash) return; // no meaningful change
  lastHash = h;
  n++;
  const slug = String(n).padStart(2, '0');
  const url = page.url();
  try {
    writeFileSync(join(outDir, `snap-${slug}.html`), html);
    writeFileSync(join(outDir, `snap-${slug}.url.txt`), `${url}\n(${reason})\n`);
    await page.screenshot({ path: join(outDir, `snap-${slug}.png`), fullPage: true });
    console.log(`✓ snap-${slug}  [${reason}]  ${url}`);
  } catch (e) {
    console.log(`✗ snap-${slug} failed: ${e.message}`);
  }
}

// capture on navigation, on DOM settling, and on a steady interval (Blazor
// re-renders in place without changing the URL, so we poll too)
page.on('framenavigated', (f) => {
  if (f === page.mainFrame()) snapshot('navigate');
});
page.on('load', () => snapshot('load'));
const timer = setInterval(() => snapshot('poll'), 3000);

console.log('\n===== cagradebook explorer (READ-ONLY — no grades are changed) =====');
console.log('  • Log in, then visit each screen: the gradebook grid, one');
console.log('    assignment/column, the add-grade dialog, any import/export/');
console.log('    settings pages. Pause a second on each so it gets captured.');
console.log('  • CLOSE the browser window when you are done.\n');

// exit cleanly once the browser window is closed
await new Promise((resolve) => ctx.on('close', resolve));
clearInterval(timer);
console.log(`\nDone. ${n} snapshot(s) saved to scripts/cagradebook/output/.`);
process.exit(0);
