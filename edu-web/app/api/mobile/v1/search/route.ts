import { searchCatalog } from "@/lib/search";
import { ok } from "@/lib/mobile/respond";

export async function GET(req: Request) {
  const q = new URL(req.url).searchParams.get("q") ?? "";
  const results = await searchCatalog(q);
  return ok(results);
}
