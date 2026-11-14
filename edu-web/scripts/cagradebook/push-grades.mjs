// push-grades.mjs — write the edu-web Linear Algebra gradebook into cagradebook.
//
//   npx tsx scripts/cagradebook/export-la.ts                     # refresh output/la-grades.json
//   node scripts/cagradebook/push-grades.mjs --dry-run           # plan only, writes nothing
//   node scripts/cagradebook/push-grades.mjs                     # create columns + enter scores
//   node scripts/cagradebook/push-grades.mjs --only "^1\.1 "     # limit to matching column names
//   node scripts/cagradebook/push-grades.mjs --skip "Lecture 8"  # leave matching columns out
//
// Idempotent: columns are matched by name (created only if missing) and cells
// are written only where the grid differs from edu-web. Every run ends with a
// reload + read-back of every targeted cell. Students are joined edu-web email →
// grid name via mapping.json; edu-web students without a mapping (dropped/test)
// are ignored, and a grid row without one aborts the run.

import { readFileSync } from 'fs';
import { join } from 'path';
import { open, pickDate, here, outDir } from './lib.mjs';

const args = process.argv.slice(2);
const DRY = args.includes('--dry-run');
const flag = (name) => (args.includes(name) ? new RegExp(args[args.indexOf(name) + 1]) : null);
const ONLY = flag('--only');
const SKIP = flag('--skip');

const data = JSON.parse(readFileSync(join(outDir, 'la-grades.json'), 'utf8'));
const mapping = JSON.parse(readFileSync(join(here, 'mapping.json'), 'utf8'));
const emailByGridName = new Map(mapping.students.map((s) => [s.gradebookName, s.email]));

const columns = data.columns.filter((c) => (!ONLY || ONLY.test(c.name)) && (!SKIP || !SKIP.test(c.name)));
const fmt = (v) => (v === null || v === undefined ? '' : String(v));
// Grid shows what was typed; compare case-insensitively and numerically.
const same = (a, b) => {
  const x = a.trim().toUpperCase();
  const y = b.trim().toUpperCase();
  return x === y || (x !== '' && y !== '' && Number(x) === Number(y));
};

const { ctx, page, shot, need, gotoGradebook } = await open();

async function readGrid() {
  const headers = await page.locator('table.gb thead th.col-asg').evaluateAll((ths) => ths.map((th) => th.getAttribute('title')));
  const names = await page.locator('table.gb tbody td.col-student').evaluateAll((tds) => tds.map((td) => td.textContent.trim()));
  return { headers, names };
}

async function createAssignment(col) {
  await page.getByRole('button', { name: /add assignment/i }).first().click();
  const dlg = await need(page.locator('.mud-dialog', { hasText: 'Add assignment' }), 'Add assignment dialog');
  await dlg.getByLabel('Assignment name').fill(col.name);
  await dlg.getByLabel('Possible points').fill(String(col.points));
  await dlg.locator('.mud-select').first().click();
  await need(page.locator('.mud-popover-open .mud-list-item', { hasText: new RegExp(`^${col.category} \\(`) }), `category ${col.category}`).then((o) => o.click());
  await page.waitForTimeout(300);
  const pickers = dlg.locator('.mud-picker');
  await pickDate(page, pickers.nth(0), col.date);
  await pickDate(page, pickers.nth(1), col.date);
  await dlg.getByRole('button', { name: /^save$/i }).click();
  await dlg.waitFor({ state: 'detached', timeout: 10000 });
  await need(page.locator(`table.gb thead th.col-asg[title="${col.name}"]`), `new column ${col.name}`);
}

// Type into a grid cell and confirm it holds the value (Blazor commits on blur).
async function setCell(id, value) {
  const cell = page.locator(`#${id}`);
  for (let attempt = 0; attempt < 4; attempt++) {
    await cell.click();
    await cell.fill(value);
    await cell.press('Tab');
    await page.waitForTimeout(200);
    if (same(await cell.inputValue(), value)) return;
  }
  throw new Error(`Cell ${id} would not accept "${value}"`);
}

try {
  console.log(`\n=== push-grades  [${DRY ? 'DRY RUN — nothing written' : 'LIVE'}]  ${columns.length} column(s) ===`);
  await gotoGradebook();
  await need(page.getByText(mapping.section.gradebookName.split(' — ')[0]), 'Linear Algebra section');

  let { headers, names } = await readGrid();
  const unmapped = names.filter((n) => !emailByGridName.has(n));
  if (unmapped.length) throw new Error(`Grid rows missing from mapping.json: ${unmapped.join('; ')}`);

  // 1) Columns.
  const missing = columns.filter((c) => !headers.includes(c.name));
  console.log(`• Columns present: ${columns.length - missing.length}, to create: ${missing.length}`);
  for (const col of missing) {
    console.log(`  + ${col.name}  (${col.category}, /${col.points}, ${col.date})`);
    if (!DRY) await createAssignment(col);
  }
  if (!DRY) ({ headers, names } = await readGrid());

  // 2) Cells.
  let changes = 0;
  for (const col of columns) {
    const ci = headers.indexOf(col.name);
    for (let ri = 0; ri < names.length; ri++) {
      const want = fmt(col.scores[emailByGridName.get(names[ri])]);
      const id = `cell-${ri}-${ci}`;
      const have = ci >= 0 ? await page.locator(`#${id}`).inputValue() : '';
      if (same(have, want) || (have.trim() === '' && want === '')) continue;
      changes++;
      console.log(`  ${col.name} · ${names[ri]}: "${have}" → "${want}"`);
      if (!DRY) await setCell(id, want);
    }
  }
  console.log(`• Cell changes: ${changes}`);

  // 3) Verify after a reload.
  if (!DRY) {
    await page.waitForTimeout(1500);
    await gotoGradebook();
    ({ headers, names } = await readGrid());
    const bad = [];
    for (const col of columns) {
      const ci = headers.indexOf(col.name);
      if (ci < 0) { bad.push(`${col.name}: column missing`); continue; }
      for (let ri = 0; ri < names.length; ri++) {
        const want = fmt(col.scores[emailByGridName.get(names[ri])]);
        const have = await page.locator(`#cell-${ri}-${ci}`).inputValue();
        if (!same(have, want) && !(have.trim() === '' && want === '')) bad.push(`${col.name} · ${names[ri]}: "${have}" ≠ "${want}"`);
      }
    }
    await shot('push-verified.png');
    if (bad.length) throw new Error(`Read-back mismatches:\n  ${bad.join('\n  ')}`);
    console.log('• Verified after reload: every targeted cell matches edu-web.');
  }
} catch (e) {
  await shot('push-error.png');
  console.error('\n✗ ' + e.message);
  process.exitCode = 1;
} finally {
  await ctx.close();
}
