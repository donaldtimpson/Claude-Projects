// probe.mjs — READ-ONLY: load the gradebook, save HTML + screenshot of current state.
import { chromium } from 'playwright';
import { writeFileSync } from 'fs';
const ctx = await chromium.launchPersistentContext('.session', { headless: false, viewport: { width: 1440, height: 900 } });
const page = ctx.pages()[0] || (await ctx.newPage());
await page.goto('https://cagradebook.com/gradebook', { waitUntil: 'domcontentloaded' });
// The app redirects to /login client-side, so wait for the real grid (up to 10 min for a manual login).
await page.getByRole('button', { name: /add assignment/i }).first().waitFor({ state: 'visible', timeout: 600000 });
await page.waitForTimeout(3000);
writeFileSync('output/probe.html', await page.content());
await page.screenshot({ path: 'output/probe.png', fullPage: true });
console.log('url', page.url());
await ctx.close();
