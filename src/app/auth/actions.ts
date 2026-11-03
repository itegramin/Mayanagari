"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { cookies } from "next/headers";
import { z } from "zod";
import { getSiteUrl } from "@/lib/env";
import { createSupabaseActionClient } from "@/lib/supabase/action-client";

function value(formData: FormData, key: string) {
  const entry = formData.get(key);
  return typeof entry === "string" ? entry.trim() : "";
}

export async function signInAction(formData: FormData) {
  const parsed = z.object({
    email: z.string().email(),
    password: z.string().min(8).max(128),
  }).safeParse({ email: value(formData, "email"), password: value(formData, "password") });
  if (!parsed.success) redirect("/auth?error=invalid");

  const supabase = await createSupabaseActionClient();
  const { error } = await supabase.auth.signInWithPassword(parsed.data);
  if (error) redirect("/auth?error=signin");
  revalidatePath("/", "layout");
  redirect("/");
}

export async function signUpAction(formData: FormData) {
  const parsed = z.object({
    email: z.string().email(),
    password: z.string().min(8).max(128),
    displayName: z.string().min(2).max(40),
  }).safeParse({
    email: value(formData, "email"),
    password: value(formData, "password"),
    displayName: value(formData, "display_name"),
  });
  if (!parsed.success) redirect("/auth?error=invalid");

  const supabase = await createSupabaseActionClient();
  const { error } = await supabase.auth.signUp({
    email: parsed.data.email,
    password: parsed.data.password,
    options: {
      data: { display_name: parsed.data.displayName },
      emailRedirectTo: new URL("/auth/callback", getSiteUrl()).toString(),
    },
  });
  if (error) redirect("/auth?error=signup");
  revalidatePath("/", "layout");
  redirect("/?welcome=1");
}

export async function signOutAction() {
  const supabase = await createSupabaseActionClient();
  const { error } = await supabase.auth.signOut();
  if (error) redirect("/?error=signout");
  revalidatePath("/", "layout");
  redirect("/");
}

export async function saveLocaleAction(locale: string) {
  const parsed = z.enum(["en", "hi"]).safeParse(locale);
  if (!parsed.success) return false;

  const supabase = await createSupabaseActionClient();
  const { data: authData, error: authError } = await supabase.auth.getUser();
  if (authError) return false;
  if (authData.user) {
    const { error } = await supabase
      .from("profiles")
      .update({ locale: parsed.data })
      .eq("id", authData.user.id);
    if (error) return false;
  }
  const cookieStore = await cookies();
  cookieStore.set("maya_locale", parsed.data, {
    path: "/",
    maxAge: 31_536_000,
    sameSite: "lax",
  });
  revalidatePath("/", "layout");
  return true;
}
