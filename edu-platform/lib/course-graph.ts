// Pure helpers for the course-connections graph. No DB / framework deps so they
// can be reused by the admin write path (cycle guard) and the map page (layout).

export type Edge = { fromCourseId: string; toCourseId: string };

/**
 * RELATED links are undirected. Store them once with the two ids in a stable
 * order so (A,B) and (B,A) collapse to a single row.
 */
export function canonicalRelatedPair(a: string, b: string): [string, string] {
  return a < b ? [a, b] : [b, a];
}

/**
 * Would adding RECOMMENDED edge `from -> to` introduce a cycle in the existing
 * RECOMMENDED graph? True if it's a self-link, a duplicate, or if `to` can
 * already reach `from` (which the new edge would close into a loop).
 */
export function wouldCreateCycle(edges: Edge[], from: string, to: string): boolean {
  if (from === to) return true;

  const adj = new Map<string, string[]>();
  for (const e of edges) {
    if (!adj.has(e.fromCourseId)) adj.set(e.fromCourseId, []);
    adj.get(e.fromCourseId)!.push(e.toCourseId);
  }

  // DFS from `to`; if we can reach `from`, the new edge closes a cycle.
  const stack = [to];
  const seen = new Set<string>();
  while (stack.length) {
    const node = stack.pop()!;
    if (node === from) return true;
    if (seen.has(node)) continue;
    seen.add(node);
    for (const next of adj.get(node) ?? []) stack.push(next);
  }
  return false;
}

/**
 * Longest-path layering of the RECOMMENDED DAG: a node's level is the longest
 * recommended-path from any root (roots — no incoming RECOMMENDED — are level 0).
 * Returns a level per course id. Courses absent from any edge land at level 0.
 * Assumes the graph is acyclic (guaranteed by the write-path cycle guard).
 */
export function layerByLongestPath(courseIds: string[], edges: Edge[]): Map<string, number> {
  const outgoing = new Map<string, string[]>();
  const indegree = new Map<string, number>();
  for (const id of courseIds) indegree.set(id, 0);

  for (const e of edges) {
    if (!outgoing.has(e.fromCourseId)) outgoing.set(e.fromCourseId, []);
    outgoing.get(e.fromCourseId)!.push(e.toCourseId);
    indegree.set(e.toCourseId, (indegree.get(e.toCourseId) ?? 0) + 1);
  }

  const level = new Map<string, number>();
  const queue: string[] = [];
  for (const id of courseIds) {
    level.set(id, 0);
    if ((indegree.get(id) ?? 0) === 0) queue.push(id);
  }

  // Kahn's topological order; relax level along each edge.
  while (queue.length) {
    const node = queue.shift()!;
    for (const next of outgoing.get(node) ?? []) {
      level.set(next, Math.max(level.get(next) ?? 0, (level.get(node) ?? 0) + 1));
      indegree.set(next, (indegree.get(next) ?? 0) - 1);
      if ((indegree.get(next) ?? 0) === 0) queue.push(next);
    }
  }

  return level;
}
