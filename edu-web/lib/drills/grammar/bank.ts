// Turn a bundled grammar JSON bank into DrillDefs — the web counterpart of the
// iOS GrammarDrills loader. Content is authored in content/grammar/ and emitted
// to ./data by tools/grammar/build_app_content.py; this wraps each drill object
// so it plays through the same generic DrillPlayer as the procedural drills.
//
// A "bank" drill draws from a fixed pool instead of generating: a per-slug
// shuffle bag deals every item once before repeating (matches iOS), and option
// order is shuffled per play — except drills tagged `order: "fixed"`, whose
// recurring option sets (its/it's, Active/Passive…) render in a stable
// case-insensitive order so the answer never drifts between slots.

import type { DrillDef, Problem, Level } from "../types";
import { pid, shuffle } from "../rand";

export type BankItem = {
  id: string;
  prompt: string;
  options: string[];
  answer: number;
  explain: string;
};
export type Bank = {
  slug: string;
  title: string;
  blurb?: string;
  icon?: string;
  order?: string; // "fixed" | else shuffle
  items: BankItem[];
};
export type BankFile = { drills: Bank[] };

const bags = new Map<string, BankItem[]>();

function draw(slug: string, items: BankItem[]): BankItem {
  let bag = bags.get(slug);
  if (!bag || bag.length === 0) {
    bag = shuffle(items);
    bags.set(slug, bag);
  }
  return bag.pop()!;
}

function orderedOptions(item: BankItem, fixed: boolean): { options: string[]; correctIndex: number } {
  const correct = item.options[item.answer];
  const options = fixed
    ? [...item.options].sort((a, b) => a.toLowerCase().localeCompare(b.toLowerCase()))
    : shuffle(item.options);
  return { options, correctIndex: options.indexOf(correct) };
}

export function bankDrill(bank: Bank, subject: string): DrillDef {
  const fixed = bank.order === "fixed";
  const homework = subject === "Grammar Lessons";
  return {
    slug: bank.slug,
    title: bank.title,
    blurb: bank.blurb ?? "",
    icon: bank.icon ?? "✒️",
    subject,
    levels: [{ value: 1 as Level, label: homework ? "Homework" : "Practice" }],
    // Finite bank ⇒ the session picker can offer "All", and a session starts from a
    // fresh bag so "All" deals every item exactly once.
    poolSize: () => bank.items.length,
    resetPool: () => { bags.delete(bank.slug); },
    generate: (): Problem => {
      const it = draw(bank.slug, bank.items);
      const { options, correctIndex } = orderedOptions(it, fixed);
      return {
        id: pid(bank.slug),
        prompt: it.prompt,
        input: { kind: "choice", options, correctIndex },
        explanation: it.explain,
      };
    },
  };
}

export function bankDrills(file: BankFile, subject: string): DrillDef[] {
  return file.drills.map((b) => bankDrill(b, subject));
}
