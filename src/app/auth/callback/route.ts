import { NextResponse, type NextRequest } from "next/server";
import { createSupabaseActionClient } from "@/lib/supabase/action-client";

export async function GET(request: NextRequest) {
  const code = request.nextUrl.searchParams.get("code");
  if (code) {
    const supabase = await createSupabaseActionClient();
    const { error } = await supabase.auth.exchangeCodeForSession(code);
    if (!error) return NextResponse.redirect(new URL("/", request.url));
  }
  return NextResponse.redirect(new URL("/auth?error=callback", request.url));
}
