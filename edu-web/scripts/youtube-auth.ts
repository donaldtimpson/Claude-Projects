// One-time OAuth consent flow to mint a YouTube refresh token for writing video
// descriptions. Run via `! npx tsx scripts/youtube-auth.ts` so it can open your
// browser. Prereqs in .env first:
//   YOUTUBE_OAUTH_CLIENT_ID, YOUTUBE_OAUTH_CLIENT_SECRET
// (from a "Desktop app" OAuth client in the same Google Cloud project as the API
// key). This script does the loopback consent dance and writes
// YOUTUBE_OAUTH_REFRESH_TOKEN back into .env.
//
// Tip: set the OAuth consent screen to "In production" so the refresh token is
// long-lived; "Testing" status expires it after 7 days.

import { createServer } from "node:http";
import { exec } from "node:child_process";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const SCOPE = "https://www.googleapis.com/auth/youtube.force-ssl";
const AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
const TOKEN_URL = "https://oauth2.googleapis.com/token";
const ENV_PATH = join(process.cwd(), ".env");

function loadEnvVar(name: string): string | undefined {
  // Prefer process.env (tsx may load .env), else parse the file directly.
  if (process.env[name]) return process.env[name];
  if (!existsSync(ENV_PATH)) return undefined;
  const line = readFileSync(ENV_PATH, "utf8")
    .split("\n")
    .find((l) => l.trim().startsWith(`${name}=`));
  return line?.slice(line.indexOf("=") + 1).trim().replace(/^["']|["']$/g, "");
}

function upsertEnvVar(name: string, value: string): void {
  let content = existsSync(ENV_PATH) ? readFileSync(ENV_PATH, "utf8") : "";
  const re = new RegExp(`^${name}=.*$`, "m");
  if (re.test(content)) {
    content = content.replace(re, `${name}=${value}`);
  } else {
    if (content.length && !content.endsWith("\n")) content += "\n";
    content += `${name}=${value}\n`;
  }
  writeFileSync(ENV_PATH, content);
}

async function main() {
  const clientId = loadEnvVar("YOUTUBE_OAUTH_CLIENT_ID");
  const clientSecret = loadEnvVar("YOUTUBE_OAUTH_CLIENT_SECRET");
  if (!clientId || !clientSecret) {
    console.error(
      "Missing YOUTUBE_OAUTH_CLIENT_ID / YOUTUBE_OAUTH_CLIENT_SECRET in .env.\n\n" +
        "Create them first:\n" +
        "  1. Google Cloud Console → same project as your API key → APIs & Services → Credentials\n" +
        "  2. Create Credentials → OAuth client ID → Application type: Desktop app\n" +
        "  3. On the OAuth consent screen add scope youtube.force-ssl, add yourself as a user,\n" +
        "     and (recommended) set publishing status to In production.\n" +
        "  4. Put the client ID and secret in .env as YOUTUBE_OAUTH_CLIENT_ID / _CLIENT_SECRET.\n",
    );
    process.exit(1);
  }

  // Loopback redirect on an OS-assigned port (Desktop clients allow any localhost port).
  const code = await new Promise<string>((resolve, reject) => {
    const server = createServer((req, res) => {
      const url = new URL(req.url ?? "/", `http://localhost`);
      const c = url.searchParams.get("code");
      const err = url.searchParams.get("error");
      res.writeHead(200, { "Content-Type": "text/html" });
      res.end(
        `<html><body style="font-family:system-ui;padding:3rem;text-align:center">` +
          `<h2>${c ? "✓ Authorized — you can close this tab." : `Authorization failed: ${err}`}</h2>` +
          `</body></html>`,
      );
      server.close();
      if (c) resolve(c);
      else reject(new Error(`OAuth error: ${err}`));
    });
    server.listen(0, "127.0.0.1", () => {
      const addr = server.address();
      const port = typeof addr === "object" && addr ? addr.port : 0;
      const redirectUri = `http://127.0.0.1:${port}`;
      const authUrl =
        `${AUTH_URL}?` +
        new URLSearchParams({
          client_id: clientId,
          redirect_uri: redirectUri,
          response_type: "code",
          scope: SCOPE,
          access_type: "offline", // request a refresh token
          prompt: "consent", // force a refresh token even on re-consent
        }).toString();

      // Stash the redirect URI for the token exchange (must match exactly).
      (globalThis as Record<string, unknown>).__redirectUri = redirectUri;

      console.log("\nOpening your browser to authorize. If it doesn't open, paste this URL:\n");
      console.log(authUrl + "\n");
      exec(`open "${authUrl}"`); // macOS; harmless no-op message elsewhere
    });
  });

  const redirectUri = (globalThis as Record<string, unknown>).__redirectUri as string;
  const res = await fetch(TOKEN_URL, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      code,
      client_id: clientId,
      client_secret: clientSecret,
      redirect_uri: redirectUri,
      grant_type: "authorization_code",
    }),
  });
  if (!res.ok) {
    console.error(`Token exchange failed: ${res.status} ${await res.text()}`);
    process.exit(1);
  }
  const data = (await res.json()) as { refresh_token?: string };
  if (!data.refresh_token) {
    console.error(
      "No refresh_token returned. Revoke the app's access at https://myaccount.google.com/permissions " +
        "and run again (Google only returns a refresh token on first consent / with prompt=consent).",
    );
    process.exit(1);
  }

  upsertEnvVar("YOUTUBE_OAUTH_REFRESH_TOKEN", data.refresh_token);
  console.log("\n✓ Saved YOUTUBE_OAUTH_REFRESH_TOKEN to .env. You're ready to push chapters.");
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
