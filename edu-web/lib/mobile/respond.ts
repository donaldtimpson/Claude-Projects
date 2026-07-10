import { NextResponse } from "next/server";

// Tiny response helpers shared across the app/api/mobile/v1/* handlers so
// success/error envelopes stay consistent.
export function ok<T>(data: T, init?: ResponseInit): NextResponse {
  return NextResponse.json(data, init);
}

export function fail(status: number, error: string): NextResponse {
  return NextResponse.json({ error }, { status });
}

export function unauthorized(): NextResponse {
  return fail(401, "Unauthorized");
}

export function badRequest(error = "Bad request"): NextResponse {
  return fail(400, error);
}
