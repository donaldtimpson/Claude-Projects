// Validation for student-chosen public handles. The handle is the ONLY name shown
// in the Hall of Scholars, so it must be safe (no impersonating house legends, no
// slurs) and URL-clean. Uniqueness is checked against the DB in the server action.

import { MOCK_SCHOLARS } from "@/lib/gamification/mock";

export const HANDLE_MIN = 3;
export const HANDLE_MAX = 20;
const HANDLE_RE = /^[A-Za-z0-9_-]+$/;

// Reserve the house-scholar names (no impersonating Aristotle) plus staff/system words.
const RESERVED = new Set<string>([
  ...MOCK_SCHOLARS.map((s) => s.handle.toLowerCase()),
  "admin", "administrator", "moderator", "mod", "staff", "owner", "official",
  "timpson", "lyceum", "house", "system", "null", "undefined", "you", "me",
]);

// Modest substring blocklist. Not exhaustive — a backstop, not a guarantee.
const PROFANITY = [
  "fuck", "shit", "bitch", "cunt", "nigg", "fag", "slut", "whore",
  "rape", "nazi", "retard", "dick", "cock", "pussy", "asshole",
];

export type HandleCheck = { ok: true; value: string } | { ok: false; error: string };

export function validateHandle(raw: string): HandleCheck {
  const value = raw.trim();
  if (value.length < HANDLE_MIN) return { ok: false, error: `Handle must be at least ${HANDLE_MIN} characters.` };
  if (value.length > HANDLE_MAX) return { ok: false, error: `Handle must be ${HANDLE_MAX} characters or fewer.` };
  if (!HANDLE_RE.test(value)) return { ok: false, error: "Use only letters, numbers, hyphens, and underscores." };

  const lower = value.toLowerCase();
  if (RESERVED.has(lower)) return { ok: false, error: "That handle is reserved — try another." };
  if (PROFANITY.some((w) => lower.includes(w))) return { ok: false, error: "Please choose a different handle." };

  return { ok: true, value };
}
