import { NextResponse } from "next/server";
import type { NextRequest } from "next/server";

export function proxy(request: NextRequest) {
  if (!request.nextUrl.pathname.startsWith("/admin")) return NextResponse.next();
  if (request.nextUrl.pathname === "/admin/login") return NextResponse.next();

  const cookie = request.cookies.get("admin_auth")?.value;
  const expected = process.env.ADMIN_PASSWORD;

  if (cookie === expected) return NextResponse.next();

  const loginUrl = new URL("/admin/login", request.url);
  return NextResponse.redirect(loginUrl);
}

export const config = { matcher: ["/admin/:path*", "/api/auth/:path*", "/auth/:path*"] };
