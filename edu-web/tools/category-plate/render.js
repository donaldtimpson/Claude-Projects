// Render a category plate to public/categories/<slug>.png at 832×466.
//   node tools/category-plate/render.js language
// Draws at 2× and downsamples for cleaner type. Fonts are embedded as base64 in
// fonts.css (generate with build-fonts.js) so the render doesn't depend on the network.
const { chromium } = require("playwright");
const { execFileSync } = require("node:child_process");
const { join } = require("node:path");

const slug = process.argv[2];
if (!slug) { console.error("usage: node tools/category-plate/render.js <slug>"); process.exit(1); }

(async () => {
  const dir = __dirname;
  const browser = await chromium.launch({ channel: "chrome" }); // bundled chromium isn't installed
  const page = await browser.newPage({ viewport: { width: 832, height: 466 }, deviceScaleFactor: 2 });
  await page.goto(`file://${join(dir, `${slug}.html`)}`);
  await page.waitForTimeout(900);                                // let the embedded fonts settle
  const tmp = join(dir, `${slug}@2x.png`);
  await page.screenshot({ path: tmp });
  await browser.close();
  const out = join(dir, "..", "..", "public", "categories", `${slug}.png`);
  execFileSync("sips", ["--resampleWidth", "832", tmp, "--out", out], { stdio: "ignore" });
  execFileSync("rm", ["-f", tmp]);
  console.log(`wrote ${out}`);
})();
