import { ResourceKind } from "@prisma/client";

export const RESOURCE_KIND_LABELS: Record<ResourceKind, string> = {
  TEXTBOOK: "Textbook",
  SLIDES: "Slides",
  PROBLEM_SET: "Problem Set",
  TOOL: "Tool / Applet",
  VIDEO: "Video",
  DOCUMENT: "Document",
  LINK: "Link",
};

export const RESOURCE_KIND_OPTIONS: { value: ResourceKind; label: string }[] =
  (Object.keys(RESOURCE_KIND_LABELS) as ResourceKind[]).map((value) => ({
    value,
    label: RESOURCE_KIND_LABELS[value],
  }));
