import { NextResponse } from "next/server";
import { createUser } from "@/lib/users";

export async function POST(req: Request) {
  const { name, email, password } = await req.json();
  const result = await createUser({ name, email, password });
  if (!result.ok) {
    return NextResponse.json({ error: result.error }, { status: result.status });
  }
  return NextResponse.json({ ok: true }, { status: 201 });
}
