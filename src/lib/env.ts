import { z } from "zod";

const publicEnvSchema = z.object({
  NEXT_PUBLIC_SUPABASE_URL: z.string().url(),
  NEXT_PUBLIC_SUPABASE_ANON_KEY: z.string().min(1),
  NEXT_PUBLIC_SITE_URL: z.string().url().default("http://localhost:3000"),
});

export function getPublicEnv() {
  return publicEnvSchema.parse({
    NEXT_PUBLIC_SUPABASE_URL: process.env.NEXT_PUBLIC_SUPABASE_URL,
    NEXT_PUBLIC_SUPABASE_ANON_KEY: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY,
    NEXT_PUBLIC_SITE_URL: process.env.NEXT_PUBLIC_SITE_URL,
  });
}

export function getSiteUrl() {
  return z.string().url().default("http://localhost:3000").parse(process.env.NEXT_PUBLIC_SITE_URL);
}

export function getServiceRoleKey() {
  return z.string().min(1).parse(process.env.SUPABASE_SERVICE_ROLE_KEY);
}

export function getWorkerSecret() {
  return z.string().min(32).parse(process.env.GAME_WORKER_SECRET);
}
