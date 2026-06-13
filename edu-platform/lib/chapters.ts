// Shared helpers for the YouTube chapters pipeline: parse a chapter file, format
// timestamps, validate against YouTube's clickable-chapter rules, and merge a
// managed chapters block into an existing video description without clobbering
// the rest of it. Used by scripts/validate-chapters.ts and scripts/push-chapters.ts.

export type Chapter = { seconds: number; label: string };

export const MIN_CHAPTERS = 3;
export const MIN_CHAPTER_LENGTH = 10; // seconds — YouTube's minimum per chapter

// The header line that marks the start of the auto-managed chapters block. On
// re-push, everything FROM this line to the end of the description is replaced,
// so the block updates in place instead of duplicating. (YouTube descriptions
// are plain text — there are no hidden markers — so chapters live at the end.)
export const CHAPTER_HEADER = "Chapters";

export function formatTimestamp(seconds: number): string {
  const s = Math.floor(seconds % 60);
  const m = Math.floor((seconds / 60) % 60);
  const h = Math.floor(seconds / 3600);
  const ss = String(s).padStart(2, "0");
  return h > 0 ? `${h}:${String(m).padStart(2, "0")}:${ss}` : `${m}:${ss}`;
}

function parseTimestamp(ts: string): number | null {
  const parts = ts.split(":").map((p) => Number(p));
  if (parts.some((n) => Number.isNaN(n))) return null;
  if (parts.length === 2) return parts[0] * 60 + parts[1];
  if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2];
  return null;
}

// Parse a chapter file's text. Returns the chapters plus any malformed lines.
export function parseChapters(text: string): { chapters: Chapter[]; badLines: string[] } {
  const chapters: Chapter[] = [];
  const badLines: string[] = [];
  for (const raw of text.split("\n")) {
    const line = raw.trim();
    if (!line) continue;
    // M:SS / MM:SS / MMM:SS (long videos) / H:MM:SS.
    const m = line.match(/^(\d{1,3}:\d{2}(?::\d{2})?)\s+(.+)$/);
    if (!m) {
      badLines.push(line);
      continue;
    }
    const seconds = parseTimestamp(m[1]);
    if (seconds === null) {
      badLines.push(line);
      continue;
    }
    chapters.push({ seconds, label: m[2].trim() });
  }
  return { chapters, badLines };
}

// Validate against YouTube's clickable-chapter rules. Pass durationSeconds when
// known (from the Video row) to also bound the last chapter. Returns error
// strings; empty array means valid.
export function validateChapters(
  chapters: Chapter[],
  badLines: string[],
  durationSeconds?: number,
): string[] {
  const errors: string[] = [];
  for (const bad of badLines) errors.push(`unparseable line: "${bad}"`);

  if (chapters.length < MIN_CHAPTERS) {
    errors.push(`only ${chapters.length} chapter(s); YouTube needs at least ${MIN_CHAPTERS}`);
  }
  if (chapters.length === 0) return errors;

  if (chapters[0].seconds !== 0) {
    errors.push(`first chapter must start at 0:00 (got ${formatTimestamp(chapters[0].seconds)})`);
  }
  for (let i = 1; i < chapters.length; i++) {
    const gap = chapters[i].seconds - chapters[i - 1].seconds;
    if (gap <= 0) {
      errors.push(
        `timestamps not ascending at "${chapters[i].label}" ` +
          `(${formatTimestamp(chapters[i].seconds)} ≤ ${formatTimestamp(chapters[i - 1].seconds)})`,
      );
    } else if (gap < MIN_CHAPTER_LENGTH) {
      errors.push(
        `chapter "${chapters[i - 1].label}" is only ${gap}s long (min ${MIN_CHAPTER_LENGTH}s)`,
      );
    }
  }

  if (durationSeconds && durationSeconds > 0) {
    const last = chapters[chapters.length - 1];
    if (last.seconds >= durationSeconds) {
      errors.push(
        `last chapter ${formatTimestamp(last.seconds)} is at/after the video end ` +
          `(${formatTimestamp(durationSeconds)})`,
      );
    } else if (durationSeconds - last.seconds < MIN_CHAPTER_LENGTH) {
      errors.push(
        `final chapter "${last.label}" is only ${Math.round(durationSeconds - last.seconds)}s ` +
          `before the video ends (min ${MIN_CHAPTER_LENGTH}s)`,
      );
    }
  }
  return errors;
}

// Render the chapters block (header + normalized lines) for the description.
export function renderChaptersBlock(chapters: Chapter[]): string {
  const lines = chapters.map((c) => `${formatTimestamp(c.seconds)} ${c.label}`);
  return `${CHAPTER_HEADER}\n${lines.join("\n")}`;
}

// Merge the chapters block into an existing description. If a managed block (a
// line equal to CHAPTER_HEADER) already exists, replace from there to the end;
// otherwise append after a blank line. Non-destructive to everything above the
// header.
export function mergeDescription(existing: string, chapters: Chapter[]): string {
  const block = renderChaptersBlock(chapters);
  const lines = existing.split("\n");
  const headerIdx = lines.findIndex((l) => l.trim() === CHAPTER_HEADER);
  if (headerIdx !== -1) {
    const before = lines.slice(0, headerIdx).join("\n").replace(/\s+$/, "");
    return before.length ? `${before}\n\n${block}` : block;
  }
  const trimmed = existing.replace(/\s+$/, "");
  return trimmed.length ? `${trimmed}\n\n${block}` : block;
}
