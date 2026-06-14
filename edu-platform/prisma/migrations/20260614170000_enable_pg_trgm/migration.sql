-- Trigram matching for typo-tolerant fallback search (lib/search.ts uses
-- word_similarity() when the full-text query returns nothing). Titles are few
-- and short, so the fallback seq-scans them — no trigram index needed.
CREATE EXTENSION IF NOT EXISTS pg_trgm;
