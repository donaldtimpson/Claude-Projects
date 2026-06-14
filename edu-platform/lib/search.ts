import { db } from "@/lib/db";

// Catalog-wide full-text search. Runs Postgres FTS against the GIN expression
// indexes created in the add_transcript_and_fts migration (the to_tsvector
// expressions here MUST match those indexes so they're used). websearch_to_tsquery
// safely parses raw user input (quotes, OR, -term). Everything is parameterized
// ($1), so the query string is never interpolated.
//
// A "lecture" hit matches if the video's title/description, its published note,
// or its transcript matches; ranked by summed ts_rank. Transcript hits get a
// snippet (highlighted via [[hl]]…[[/hl]] sentinels the UI turns into <mark>)
// and a best-effort start timestamp for deep-linking into the video.
//
// Results are limited to CANONICAL courses (canonicalCourseId IS NULL) so repeated
// sibling offerings of the same subject don't show up as near-duplicate hits.

export type CourseHit = {
  id: string;
  title: string;
  description: string;
  thumbnailUrl: string;
};

export type LectureHit = {
  videoId: string;
  courseId: string;
  title: string;
  courseTitle: string;
  snippet: string | null;
  startSeconds: number | null;
};

export type SearchResults = { courses: CourseHit[]; lectures: LectureHit[] };

type Segment = { start: number; text: string };

type LectureRow = {
  videoId: string;
  courseId: string;
  title: string;
  courseTitle: string;
  snippet: string | null;
  transcriptMatched: boolean;
  segments: unknown;
};

// Significant query terms (len >= 3), for locating the matched moment in segments.
function queryTerms(q: string): string[] {
  return [...new Set(q.toLowerCase().match(/[a-z0-9]+/g) ?? [])].filter((w) => w.length >= 3);
}

function earliestMatchSeconds(segments: unknown, terms: string[]): number | null {
  if (!terms.length) return null;
  let segs: Segment[];
  try {
    segs = typeof segments === "string" ? JSON.parse(segments) : (segments as Segment[]);
  } catch {
    return null;
  }
  if (!Array.isArray(segs)) return null;
  for (const s of segs) {
    if (!s || typeof s.text !== "string") continue;
    const t = s.text.toLowerCase();
    if (terms.some((w) => t.includes(w))) return Math.max(0, Math.floor(s.start));
  }
  return null;
}

export async function searchCatalog(rawQuery: string): Promise<SearchResults> {
  const q = rawQuery.trim();
  if (!q) return { courses: [], lectures: [] };

  const [courses, lectureRows] = await Promise.all([
    db.$queryRawUnsafe<CourseHit[]>(
      `SELECT id, title, description, "thumbnailUrl"
       FROM "Course"
       WHERE "canonicalCourseId" IS NULL
         AND to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,''))
             @@ websearch_to_tsquery('english', $1)
       ORDER BY ts_rank(
         to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,'')),
         websearch_to_tsquery('english', $1)
       ) DESC
       LIMIT 12`,
      q,
    ),
    db.$queryRawUnsafe<LectureRow[]>(
      `SELECT v.id AS "videoId",
              v."courseId" AS "courseId",
              v.title AS "title",
              c.title AS "courseTitle",
              t.segments AS "segments",
              (t.content IS NOT NULL
                AND to_tsvector('english', t.content) @@ websearch_to_tsquery('english', $1)) AS "transcriptMatched",
              CASE
                WHEN t.content IS NOT NULL
                     AND to_tsvector('english', t.content) @@ websearch_to_tsquery('english', $1)
                THEN ts_headline('english', t.content, websearch_to_tsquery('english', $1),
                       'StartSel=[[hl]], StopSel=[[/hl]], MaxFragments=1, MinWords=6, MaxWords=22')
                ELSE NULL
              END AS "snippet"
       FROM "Video" v
       JOIN "Course" c ON c.id = v."courseId"
       LEFT JOIN "LectureNote" n ON n."videoId" = v.id AND n."isDraft" = false
       LEFT JOIN "Transcript" t ON t."videoId" = v.id
       WHERE c."canonicalCourseId" IS NULL
         -- Drop test / "no new material" review videos (titled "… Lecture NA" or
         -- "… No New Material") — they shouldn't surface as lecture results.
         AND v.title NOT ILIKE '%Lecture NA%'
         AND v.title NOT ILIKE '%No New Material%'
         -- Pick candidate videos via per-table indexed subqueries. An OR across
         -- the joined note/transcript tables can't use their GIN indexes and makes
         -- Postgres re-tokenize every transcript per search (~5s); this UNION lets
         -- each match hit its index (~150ms). ts_rank/ts_headline below then run
         -- only on the small candidate set.
         AND v.id IN (
           SELECT v2.id FROM "Video" v2
             WHERE to_tsvector('english', coalesce(v2.title,'') || ' ' || coalesce(v2.description,''))
                   @@ websearch_to_tsquery('english', $1)
           UNION
           SELECT n2."videoId" FROM "LectureNote" n2
             WHERE n2."isDraft" = false
               AND to_tsvector('english', n2.content) @@ websearch_to_tsquery('english', $1)
           UNION
           SELECT tr."videoId" FROM "Transcript" tr
             WHERE to_tsvector('english', tr.content) @@ websearch_to_tsquery('english', $1)
         )
       ORDER BY
         -- Tier first: a lecture whose TITLE matches outranks one matched only in
         -- its notes, which outranks a transcript-only (passing-mention) match.
         (CASE
            WHEN to_tsvector('english', coalesce(v.title,'') || ' ' || coalesce(v.description,''))
                 @@ websearch_to_tsquery('english', $1) THEN 2
            WHEN to_tsvector('english', coalesce(n.content,'')) @@ websearch_to_tsquery('english', $1) THEN 1
            ELSE 0
          END) DESC,
         -- Within a tier: weighted + length-normalized relevance. setweight tags
         -- title=A, notes=B, transcript=C; the {D,C,B,A} weight array favors A>B>C,
         -- and normalization flag 1 (÷ 1+log(len)) stops long transcripts from
         -- saturating so a focused lecture beats a long one that merely says the word.
         ts_rank(
           '{0.1, 0.2, 0.4, 1.0}'::float4[],
           setweight(to_tsvector('english', coalesce(v.title,'') || ' ' || coalesce(v.description,'')), 'A')
             || setweight(to_tsvector('english', coalesce(n.content,'')), 'B')
             || setweight(to_tsvector('english', coalesce(t.content,'')), 'C'),
           websearch_to_tsquery('english', $1),
           1
         ) DESC
       LIMIT 30`,
      q,
    ),
  ]);

  const terms = queryTerms(q);
  const lectures: LectureHit[] = lectureRows.map((r) => ({
    videoId: r.videoId,
    courseId: r.courseId,
    title: r.title,
    courseTitle: r.courseTitle,
    snippet: r.snippet,
    startSeconds: r.transcriptMatched ? earliestMatchSeconds(r.segments, terms) : null,
  }));

  return { courses, lectures };
}
