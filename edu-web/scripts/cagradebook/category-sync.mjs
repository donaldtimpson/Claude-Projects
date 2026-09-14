// category-sync.mjs — create/reconcile weighted grade categories in cagradebook.
//
// Test run for the write automation: touches NO student data, only the
// "Manage categories" dialog. Categories come from the first-semester Linear
// Algebra syllabus (Extra Credit deliberately omitted — can't be a category).
//
//   node scripts/cagradebook/category-sync.mjs              # DRY RUN (no save)
//   node scripts/cagradebook/category-sync.mjs --commit     # actually save
//
// Reuses the saved login in ./.session. Reconciles: renames/reweights existing
// rows, adds missing ones, deletes extras, verifies the total is 100%.

import { chromium } from 'playwright';
import { mkdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';

const here = dirname(fileURLToPath(import.meta.url));
const outDir = join(here, 'output');
const userDataDir = join(here, '.session');
mkdirSync(outDir, { recursive: true });

const COMMIT = process.argv.includes('--commit');
const SECTION = process.env.CAGRADEBOOK_SECTION || 'Linear Algebra';
const START_URL = process.env.CAGRADEBOOK_URL || 'https://cagradebook.com/gradebook';

// First-semester Linear Algebra categories (weights total 100).
// Distinct colors so gradebook columns are easy to tell apart.
const DESIRED = [
  { name: 'Attendance', weight: 10, color: '#607D8B' }, // slate
  { name: 'Homework', weight: 20, color: '#1E88E5' },   // blue
  { name: 'Quizzes', weight: 10, color: '#00897B' },    // teal
  { name: 'Unit Tests', weight: 30, color: '#F9A825' }, // amber
  { name: 'Midterm', weight: 30, color: '#C62828' },    // crimson (the big exam)
];

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

const ctx = await chromium.launchPersistentContext(userDataDir, {
  headless: false,
  viewport: { width: 1440, height: 900 },
});
const page = ctx.pages()[0] || (await ctx.newPage());

try {
  console.log(`\n=== category-sync  [${COMMIT ? 'COMMIT — will save' : 'DRY RUN — nothing saved'}] ===`);
  await page.goto(START_URL, { waitUntil: 'domcontentloaded' });

  // Bail out clearly if the saved session has expired.
  if (/\/login/i.test(page.url())) {
    await shot('ERROR-not-logged-in.png');
    throw new Error('Session expired — re-run explore.mjs and log in once to refresh ./.session, then retry.');
  }

  // Confirm the right section is loaded (it persists between visits).
  const sectionLabel = await need(page.getByText(SECTION, { exact: false }), `section "${SECTION}"`);
  console.log(`• Section: ${(await sectionLabel.textContent())?.trim()}`);

  await (await need(page.getByRole('button', { name: /manage categories/i }), 'Manage categories button')).click();

  const dialog = page.locator('.mud-dialog', { hasText: 'Manage categories' });
  await need(dialog, 'Manage categories dialog');

  const rows = dialog.locator('tbody tr');
  const nameInput = (i) => rows.nth(i).locator('td').nth(0).locator('input');
  const weightInput = (i) => rows.nth(i).locator('td').nth(1).locator('input[type="number"]');
  const colorInput = (i) => rows.nth(i).locator('td').nth(2).locator('input[type="text"]');
  const deleteBtn = (i) => rows.nth(i).locator('td').last().locator('button');
  const addCategory = dialog.getByRole('button', { name: /add category/i });

  // Snapshot current state for the log.
  const before = [];
  for (let i = 0; i < (await rows.count()); i++) {
    before.push(`${(await nameInput(i).inputValue()).trim()} / ${(await weightInput(i).inputValue()).trim()}%`);
  }
  console.log(`• Existing rows: ${before.length ? before.join(', ') : '(none)'}`);

  // Fill a field and confirm Blazor accepted it, retrying (some rows commit a
  // beat after blur). Tab triggers the change/blur the MudBlazor binding needs.
  async function setField(input, value, { ci = false } = {}) {
    const norm = (s) => (ci ? s.trim().toLowerCase() : s.trim());
    for (let attempt = 0; attempt < 4; attempt++) {
      await input.click();
      await input.fill('');
      await input.fill(value);
      await input.press('Tab');
      await page.waitForTimeout(150);
      if (norm(await input.inputValue()) === norm(value)) return;
    }
    throw new Error(`Field would not accept value "${value}"`);
  }

  async function setRow(i, cat) {
    await setField(nameInput(i), cat.name);
    await setField(weightInput(i), String(cat.weight));
    // Color is cosmetic — best-effort so a picker quirk can't abort the save.
    if (cat.color) {
      try {
        await setField(colorInput(i), cat.color, { ci: true });
      } catch (e) {
        console.log(`    (color for ${cat.name} skipped: ${e.message})`);
      }
    }
  }

  // Reconcile to DESIRED: fill existing rows, add missing, delete extras.
  for (let i = 0; i < DESIRED.length; i++) {
    if (i >= (await rows.count())) {
      await addCategory.click();
      await rows.nth(i).waitFor({ state: 'visible', timeout: 8000 });
    }
    await setRow(i, DESIRED[i]);
    console.log(`  → row ${i + 1}: ${DESIRED[i].name} = ${DESIRED[i].weight}%`);
  }
  while ((await rows.count()) > DESIRED.length) {
    const last = (await rows.count()) - 1;
    const doomed = (await nameInput(last).inputValue()).trim();
    await deleteBtn(last).click();
    await rows.nth(last).waitFor({ state: 'detached', timeout: 8000 }).catch(() => {});
    console.log(`  ✕ removed extra row: ${doomed || '(blank)'}`);
  }

  // Verify the live total reads 100%, polling until the chip settles.
  const wantTotal = DESIRED.reduce((s, c) => s + c.weight, 0);
  const totalChip = dialog.getByText(/total:\s*\d+%/i).first();
  let total = NaN;
  let totalText = '';
  for (let i = 0; i < 20; i++) {
    totalText = (await totalChip.textContent().catch(() => '')) || '';
    total = Number((totalText.match(/(\d+)%/) || [])[1]);
    if (total === wantTotal) break;
    await page.waitForTimeout(250);
  }
  console.log(`• Total after edits: ${totalText.trim() || '(not found)'}`);
  if (total !== wantTotal) {
    await shot('ERROR-total-mismatch.png');
    throw new Error(`Total is ${total}%, expected ${wantTotal}%. Aborting before save.`);
  }

  await shot(COMMIT ? 'categories-before-save.png' : 'categories-dryrun.png');

  if (!COMMIT) {
    await dialog.getByRole('button', { name: /cancel/i }).click();
    console.log('\nDRY RUN complete — dialog cancelled, nothing saved.');
    console.log('Review scripts/cagradebook/output/categories-dryrun.png, then re-run with --commit.');
  } else {
    await dialog.getByRole('button', { name: /^save$/i }).click();
    await dialog.waitFor({ state: 'detached', timeout: 10000 }).catch(() => {});
    console.log('\nCOMMITTED — categories saved.');

    // Verify persistence: reopen the dialog and read the rows back.
    await (await need(page.getByRole('button', { name: /manage categories/i }), 'Manage categories (verify)')).click();
    await need(dialog, 'Manage categories dialog (verify)');
    const saved = [];
    for (let i = 0; i < (await rows.count()); i++) {
      saved.push(`${(await nameInput(i).inputValue()).trim()} / ${(await weightInput(i).inputValue()).trim()}%`);
    }
    await shot('categories-verified.png');
    await dialog.getByRole('button', { name: /cancel/i }).click();
    console.log(`• Verified saved rows: ${saved.join(', ')}`);
    console.log('  Screenshot: scripts/cagradebook/output/categories-verified.png');
  }
} catch (e) {
  console.error('\n✗ ' + e.message);
  process.exitCode = 1;
} finally {
  await ctx.close();
}
