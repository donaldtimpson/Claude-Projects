"use client";

import { useState } from "react";
import MarkdownNotes from "@/components/MarkdownNotes";
import type { PairedProblemSet } from "@/lib/problem-sets";

// Renders a problem set with its worked solutions attached to the problems they
// answer. Solutions start hidden so the page is still usable as practice, and
// open per problem — checking #3 shouldn't mean scrolling past the answers to
// #1 and #2, which is what a single solutions blob at the bottom forces.

function SolutionPanel({ children }: { children: React.ReactNode }) {
  return (
    <div className="mt-3 rounded-lg border border-gold-500/30 bg-crimson-950/40 px-4 py-1">
      <p className="font-display text-[0.65rem] tracking-[0.2em] uppercase text-gold-400 pt-3">
        Solution
      </p>
      {children}
    </div>
  );
}

function ToggleButton({
  open,
  onClick,
  children,
}: {
  open: boolean;
  onClick: () => void;
  children: React.ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      aria-expanded={open}
      className="font-display text-[0.65rem] tracking-[0.15em] uppercase text-parchment-dim hover:text-gold-300 border border-crimson-700 hover:border-gold-500 rounded-lg px-3 py-1.5 transition-colors"
    >
      {children}
    </button>
  );
}

// A permalink to one problem — lets a question in the discussion thread point at
// "problem 4" instead of "the one about the inkjet printer".
function Permalink({ anchor, label }: { anchor: string; label: string }) {
  return (
    <a
      href={`#${anchor}`}
      aria-label={`Link to ${label}`}
      title={`Link to ${label}`}
      className="opacity-0 group-hover:opacity-100 focus:opacity-100 text-parchment-dim hover:text-gold-300 transition-opacity shrink-0 text-sm"
    >
      #
    </a>
  );
}

export default function ProblemSetView({ data }: { data: PairedProblemSet }) {
  const [openIds, setOpenIds] = useState<Set<string>>(new Set());
  const [blockOpen, setBlockOpen] = useState(false);

  // Fallback shape: numbering didn't line up, so the solutions stay one block.
  if (data.mode === "blocks") {
    return (
      <div className="space-y-6">
        {data.body.trim() ? (
          <MarkdownNotes content={data.body} />
        ) : (
          <p className="text-parchment-dim">See the attachment above for the problems.</p>
        )}
        {data.solution && (
          <div className="pt-4 border-t border-crimson-700 space-y-3">
            <ToggleButton open={blockOpen} onClick={() => setBlockOpen((v) => !v)}>
              {blockOpen ? "Hide solutions" : "Show solutions"}
            </ToggleButton>
            {blockOpen && (
              <SolutionPanel>
                <MarkdownNotes content={data.solution} />
              </SolutionPanel>
            )}
          </div>
        )}
      </div>
    );
  }

  const solvable = data.parts.filter((p) => p.solution);
  const allOpen = solvable.length > 0 && solvable.every((p) => openIds.has(p.key));

  const toggle = (key: string) =>
    setOpenIds((prev) => {
      const next = new Set(prev);
      if (next.has(key)) next.delete(key);
      else next.add(key);
      return next;
    });

  const toggleAll = () =>
    setOpenIds(allOpen ? new Set() : new Set(solvable.map((p) => p.key)));

  return (
    <div className="space-y-6">
      {data.problemsPreamble && <MarkdownNotes content={data.problemsPreamble} />}

      {solvable.length > 0 && (
        <div className="flex items-center gap-3 flex-wrap pb-1">
          <ToggleButton open={allOpen} onClick={toggleAll}>
            {allOpen ? "Hide all solutions" : "Reveal all solutions"}
          </ToggleButton>
          <span className="text-xs text-parchment-dim">
            {openIds.size > 0
              ? `${openIds.size} of ${solvable.length} shown`
              : "Worked solutions are available for every problem."}
          </span>
        </div>
      )}

      {/* The solutions' own lead-in (constants to use, etc.) only matters once
          something is actually revealed. */}
      {data.solutionPreamble && openIds.size > 0 && (
        <div className="rounded-lg border border-gold-500/30 bg-crimson-950/40 px-4 py-1">
          <MarkdownNotes content={data.solutionPreamble} />
        </div>
      )}

      <ol className="space-y-5 list-none p-0 m-0">
        {data.parts.map((p) => {
          const open = openIds.has(p.key);
          // A named section (Extra Credit) stands apart from the numbered
          // problems — it's its own block of work, not another item in the run.
          const isSection = p.key.startsWith("section:");
          const anchor = p.key.replace(":", "-").replace(/\s+/g, "-");
          return (
            <li
              key={p.key}
              id={anchor}
              className={`group scroll-mt-24 border rounded-xl px-5 py-1 ${
                isSection
                  ? "bg-crimson-950/60 border-gold-500/40 mt-8"
                  : "bg-crimson-900/40 border-crimson-700"
              }`}
            >
              <div className="flex items-start gap-2">
                <div className="min-w-0 flex-1">
                  <MarkdownNotes content={p.problem} />
                </div>
                <span className="pt-4">
                  <Permalink anchor={anchor} label={`problem ${p.label}`} />
                </span>
              </div>
              {p.solution && (
                <div className="pb-4">
                  <ToggleButton open={open} onClick={() => toggle(p.key)}>
                    {open ? `Hide solution ${p.label}` : `Show solution ${p.label}`}
                  </ToggleButton>
                  {open && (
                    <SolutionPanel>
                      <MarkdownNotes content={p.solution} />
                    </SolutionPanel>
                  )}
                </div>
              )}
            </li>
          );
        })}
      </ol>
    </div>
  );
}
