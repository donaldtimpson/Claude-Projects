import { NextResponse } from "next/server";
import { searchCatalog } from "@/lib/search";

export const dynamic = "force-dynamic";

// GET ?q=  — catalog-wide search across courses, lectures, notes, and transcripts.
export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const q = searchParams.get("q") ?? "";
  const results = await searchCatalog(q);
  return NextResponse.json(results);
}
