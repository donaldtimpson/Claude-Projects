"use client";

import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import type { Components } from "react-markdown";
import "katex/dist/katex.min.css";

// Shared renderer for lecture-note Markdown. Used by the public LectureNotes
// section and by the admin editor's Preview tab, so review fidelity is exact.
// Themed `components` map matches the parchment/crimson/gold palette rather than
// relying on a generic `prose` class.
const components: Components = {
  h1: ({ children }) => <h3 className="text-lg font-bold text-parchment mt-5 first:mt-0">{children}</h3>,
  h2: ({ children }) => (
    <h3 className="font-display text-sm tracking-[0.15em] uppercase text-gold-300 mt-6 first:mt-0">{children}</h3>
  ),
  h3: ({ children }) => <h4 className="font-semibold text-parchment mt-4">{children}</h4>,
  p: ({ children }) => <p className="text-sm text-parchment-dim leading-relaxed my-3">{children}</p>,
  ul: ({ children }) => <ul className="list-disc pl-5 space-y-1.5 my-3 text-sm text-parchment-dim">{children}</ul>,
  ol: ({ children }) => <ol className="list-decimal pl-5 space-y-1.5 my-3 text-sm text-parchment-dim">{children}</ol>,
  li: ({ children }) => <li className="leading-relaxed">{children}</li>,
  strong: ({ children }) => <strong className="font-semibold text-parchment">{children}</strong>,
  em: ({ children }) => <em className="italic">{children}</em>,
  a: ({ href, children }) => (
    <a href={href} target="_blank" rel="noopener noreferrer" className="text-gold-300 hover:text-gold-200 underline">
      {children}
    </a>
  ),
  code: ({ children }) => (
    <code className="px-1 py-0.5 rounded bg-crimson-950/60 text-gold-200 text-[0.85em] font-mono">{children}</code>
  ),
  pre: ({ children }) => (
    <pre className="my-3 p-3 rounded-lg bg-crimson-950/60 overflow-x-auto text-sm text-parchment-dim">{children}</pre>
  ),
  blockquote: ({ children }) => (
    <blockquote className="border-l-2 border-gold-500/50 pl-4 my-3 text-parchment-dim italic">{children}</blockquote>
  ),
  hr: () => <hr className="my-5 border-crimson-700" />,
};

export default function MarkdownNotes({ content }: { content: string }) {
  return (
    <ReactMarkdown
      remarkPlugins={[remarkGfm, remarkMath]}
      rehypePlugins={[rehypeKatex]}
      components={components}
    >
      {content}
    </ReactMarkdown>
  );
}
