"use client";

import katex from "katex";
import "katex/dist/katex.min.css";
import type { Renderable } from "@/lib/drills/types";

// Renders a Renderable: a plain string as-is, or `{ tex }` as KaTeX. Lighter than
// the full react-markdown pipeline (MarkdownNotes) for per-keystroke option labels.
export default function Tex({ value, block = false }: { value: Renderable; block?: boolean }) {
  if (typeof value === "string") return <>{value}</>;
  const html = katex.renderToString(value.tex, {
    throwOnError: false,
    displayMode: block,
    output: "html",
  });
  return <span dangerouslySetInnerHTML={{ __html: html }} />;
}
