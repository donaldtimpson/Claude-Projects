import { readFileSync, readdirSync, existsSync } from "node:fs";
import { join } from "node:path";

// Pre-import structural check for scripts/notes/*.md. Verifies each file is
// non-empty, contains the four expected study-note sections, and has no
// instructor-name leak. DB-level checks (videoId exists) happen at import time.
const dir = join(process.cwd(), "scripts", "notes");
if (!existsSync(dir)) {
  console.error(`No notes directory found at ${dir}`);
  process.exit(1);
}

const REQUIRED_SECTIONS = ["## Overview", "## Key Concepts", "## Worked Example", "## Summary"];
const files = readdirSync(dir).filter((f) => f.endsWith(".md"));
let errors = 0;
const err = (m: string) => { console.log("  ✗ " + m); errors++; };

for (const f of files) {
  const content = readFileSync(join(dir, f), "utf8");
  if (!content.trim()) { err(`${f}: empty file`); continue; }
  for (const section of REQUIRED_SECTIONS) {
    if (!content.includes(section)) err(`${f}: missing "${section}" section`);
  }
  if (content.toLowerCase().includes("donald")) err(`${f}: mentions instructor name`);
}

console.log(`\n${files.length} file(s) checked. errors=${errors}`);
process.exit(errors > 0 ? 1 : 0);
