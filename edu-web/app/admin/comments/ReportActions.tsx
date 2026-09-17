"use client";

import { useState, useTransition } from "react";
import { deleteReportedComment, resolveReport, dismissReport } from "./actions";

// Action buttons for one open report in the moderation queue. Server actions run
// through a transition so the row shows a pending state and the page revalidates.
export default function ReportActions({
  reportId,
  commentId,
  commentDeleted,
}: {
  reportId: string;
  commentId: string;
  commentDeleted: boolean;
}) {
  const [pending, startTransition] = useTransition();
  const [confirmDelete, setConfirmDelete] = useState(false);

  return (
    <div className="flex items-center gap-3 flex-wrap">
      {!commentDeleted &&
        (confirmDelete ? (
          <span className="flex items-center gap-2">
            <span className="text-xs text-parchment-dim">Delete comment?</span>
            <button
              disabled={pending}
              onClick={() => startTransition(() => deleteReportedComment(commentId))}
              className="text-xs font-semibold text-red-400 hover:text-red-300 disabled:opacity-50"
            >
              Confirm
            </button>
            <button
              onClick={() => setConfirmDelete(false)}
              className="text-xs text-parchment-dim hover:text-parchment"
            >
              No
            </button>
          </span>
        ) : (
          <button
            onClick={() => setConfirmDelete(true)}
            className="text-xs font-semibold text-red-400 hover:text-red-300"
          >
            Delete comment
          </button>
        ))}
      <button
        disabled={pending}
        onClick={() => startTransition(() => resolveReport(reportId))}
        className="text-xs text-gold-400 hover:text-gold-300 disabled:opacity-50"
      >
        Resolve
      </button>
      <button
        disabled={pending}
        onClick={() => startTransition(() => dismissReport(reportId))}
        className="text-xs text-parchment-dim hover:text-parchment disabled:opacity-50"
      >
        Dismiss
      </button>
    </div>
  );
}
