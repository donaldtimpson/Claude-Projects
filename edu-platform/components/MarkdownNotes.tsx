"use client";

import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import remarkMath from "remark-math";
import rehypeKatex from "rehype-katex";
import type { Components } from "react-markdown";
import "katex/dist/katex.min.css";

// Shared renderer for lecture-note Markdown. Used by the public LectureNotes
// section, the admin editor's Preview tab, and the print/PDF page.
//   variant "dark"  → parchment/crimson/gold theme for the on-site dark UI
//   variant "print" → dark text on white for the print/PDF page
type Variant = "dark" | "print";

function buildComponents(variant: Variant): Components {
  const dark = variant === "dark";
  const body = dark ? "text-parchment-dim" : "text-zinc-700";
  const heading = dark ? "text-parchment" : "text-zinc-900";
  const section = dark ? "text-gold-300" : "text-zinc-800";
  const strong = dark ? "text-parchment" : "text-zinc-900";
  const link = dark ? "text-gold-300 hover:text-gold-200" : "text-zinc-900";
  const codeBg = dark ? "bg-crimson-950/60 text-gold-200" : "bg-zinc-100 text-zinc-800";
  const preBg = dark ? "bg-crimson-950/60 text-parchment-dim" : "bg-zinc-100 text-zinc-800";
  const quote = dark ? "border-gold-500/50 text-parchment-dim" : "border-zinc-300 text-zinc-600";
  const rule = dark ? "border-crimson-700" : "border-zinc-200";
  // Print runs a notch larger than the on-screen dark UI, with heavier section headers.
  const bodyText = dark ? "text-sm" : "text-base";
  const h1Cls = dark ? "text-lg font-bold" : "text-xl font-bold";
  const sectionCls = dark
    ? "font-display text-sm tracking-[0.15em]"
    : "font-display text-base font-bold tracking-[0.12em]";

  return {
    h1: ({ children }) => <h3 className={`${h1Cls} mt-5 first:mt-0 ${heading}`}>{children}</h3>,
    h2: ({ children }) => (
      <h3 className={`${sectionCls} uppercase mt-6 first:mt-0 ${section}`}>{children}</h3>
    ),
    h3: ({ children }) => <h4 className={`font-semibold mt-4 ${heading}`}>{children}</h4>,
    p: ({ children }) => <p className={`${bodyText} leading-relaxed my-3 ${body}`}>{children}</p>,
    ul: ({ children }) => <ul className={`list-disc pl-5 space-y-1.5 my-3 ${bodyText} ${body}`}>{children}</ul>,
    ol: ({ children }) => <ol className={`list-decimal pl-5 space-y-1.5 my-3 ${bodyText} ${body}`}>{children}</ol>,
    li: ({ children }) => <li className="leading-relaxed">{children}</li>,
    strong: ({ children }) => <strong className={`font-semibold ${strong}`}>{children}</strong>,
    em: ({ children }) => <em className="italic">{children}</em>,
    a: ({ href, children }) => (
      <a href={href} target="_blank" rel="noopener noreferrer" className={`underline ${link}`}>
        {children}
      </a>
    ),
    code: ({ children }) => (
      <code className={`px-1 py-0.5 rounded text-[0.85em] font-mono ${codeBg}`}>{children}</code>
    ),
    pre: ({ children }) => (
      <pre className={`my-3 p-3 rounded-lg overflow-x-auto text-sm ${preBg}`}>{children}</pre>
    ),
    blockquote: ({ children }) => (
      <blockquote className={`border-l-2 pl-4 my-3 italic ${quote}`}>{children}</blockquote>
    ),
    hr: () => <hr className={`my-5 ${rule}`} />,
  };
}

const DARK = buildComponents("dark");
const PRINT = buildComponents("print");

export default function MarkdownNotes({ content, variant = "dark" }: { content: string; variant?: Variant }) {
  return (
    <ReactMarkdown
      remarkPlugins={[remarkGfm, remarkMath]}
      rehypePlugins={[rehypeKatex]}
      components={variant === "print" ? PRINT : DARK}
    >
      {content}
    </ReactMarkdown>
  );
}
