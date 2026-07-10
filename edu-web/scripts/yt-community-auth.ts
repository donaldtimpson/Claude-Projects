// One-time setup for the community-quiz-post pipeline. Opens the persistent
// Chrome profile (headed) at YouTube Studio so Donald can log into
// @donaldDtimpson MANUALLY once. The session cookies persist in .yt-profile/,
// so the poster script never has to automate the Google login itself.
//
// Usage: npx tsx scripts/yt-community-auth.ts
// Then log in (incl. 2FA) in the window that opens; this exits automatically
// once it detects a signed-in Studio session.

import { launchStudio, STUDIO_URL } from "../lib/yt-studio";

const MAX_WAIT_MS = 5 * 60 * 1000;
const POLL_MS = 3000;
const SIGNED_IN = /studio\.youtube\.com\/(channel|video|playlist|content)/;

async function main() {
  const ctx = await launchStudio();
  const page = ctx.pages()[0] ?? (await ctx.newPage());
  await page.goto(STUDIO_URL, { waitUntil: "domcontentloaded" }).catch(() => {});

  if (SIGNED_IN.test(page.url())) {
    console.log("✓ Already signed in to YouTube Studio. Session is ready.");
    await ctx.close();
    return;
  }

  console.log("A Chrome window has opened. Log in to YouTube as @donaldDtimpson (incl. 2FA).");
  console.log("Waiting up to 5 minutes for a signed-in Studio session…");

  const deadline = Date.now() + MAX_WAIT_MS;
  while (Date.now() < deadline) {
    await new Promise((r) => setTimeout(r, POLL_MS));
    if (SIGNED_IN.test(page.url())) {
      console.log(`✓ Signed in (${page.url()}). Session saved to .yt-profile/.`);
      await page.waitForTimeout(1500); // let cookies flush
      await ctx.close();
      return;
    }
  }

  console.error("✗ Timed out waiting for sign-in. Re-run when ready.");
  await ctx.close();
  process.exit(1);
}

main().catch(async (e) => {
  console.error(e);
  process.exit(1);
});
