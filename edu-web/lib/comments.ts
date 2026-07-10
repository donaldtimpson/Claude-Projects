// Shared shaping for the lecture discussion. Comments are single-level threaded:
// a reply always points at a top-level comment (POST /api/comments collapses deeper
// replies), so nesting never goes past one level. A comment that still has replies is
// soft-deleted (deletedAt set, body cleared) so the thread keeps reading; the read
// paths render it as a "[comment deleted]" placeholder with the author hidden.

export const DELETED_BODY = "[comment deleted]";

export type CommentRow = {
  id: string;
  body: string;
  parentId: string | null;
  createdAt: Date;
  deletedAt: Date | null;
  user: { id: string; name: string | null };
};

export type SerializedComment = {
  id: string;
  body: string;
  createdAt: string;
  parentId: string | null;
  deleted: boolean;
  user: { id: string; name: string };
  replies: SerializedComment[];
};

export function serializeComment(c: CommentRow): SerializedComment {
  const deleted = c.deletedAt != null;
  return {
    id: c.id,
    parentId: c.parentId,
    body: deleted ? DELETED_BODY : c.body,
    createdAt: c.createdAt.toISOString(),
    deleted,
    user: deleted ? { id: "", name: "" } : { id: c.user.id, name: c.user.name ?? "Student" },
    replies: [],
  };
}

// Build the top-level list with each comment's replies nested underneath.
// `rows` should already be ordered createdAt asc so both levels come out chronological.
export function nestComments(rows: CommentRow[]): SerializedComment[] {
  const byId = new Map<string, SerializedComment>();
  for (const r of rows) byId.set(r.id, serializeComment(r));

  const top: SerializedComment[] = [];
  for (const r of rows) {
    const node = byId.get(r.id)!;
    const parent = r.parentId ? byId.get(r.parentId) : undefined;
    if (parent) parent.replies.push(node);
    else top.push(node);
  }
  return top;
}
