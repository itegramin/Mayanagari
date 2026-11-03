# Mayanagari

Mayanagari is a bilingual, text-based online role-playing game set in an original fictional Indian-inspired metropolis. The current playable foundation includes Supabase authentication, character stats and regeneration, neighbourhood activities, inventory, guild halls, chat, a player bazaar, and server-resolved sparring.

The setting is intentionally original: its stories draw on neighbourhood arts, shared public spaces, monsoon weather, food, and everyday community life without mapping real-world political or religious groups to in-game factions.

## Stack and architecture

- Next.js App Router, React, TypeScript, Zod, and server actions.
- Supabase Auth and Postgres as the authority for game state, RLS-protected reads, and atomic game commands.
- Supabase Realtime for city chat and small, user-scoped outbox notifications.
- Timestamp-based passive regeneration plus one bounded scheduled worker for listings, queued jobs, and event delivery; no process/timer per character.
- English and Hindi UI and seed content. Game timestamps are UTC; player-facing chat times use India Standard Time.

See [docs/architecture.md](./docs/architecture.md) for the full system design and [the database migration](./supabase/migrations/202611030001_game_foundation.sql) for tables, policies, and authoritative RPCs.

## Local development

Prerequisites: Node.js 20.9 or later and Docker Desktop (required by the Supabase local stack). Install the Supabase CLI using its official installation instructions.

1. Install JavaScript dependencies:

   ```sh
   npm install
   ```

2. Start the local Supabase services and apply migrations/seed data:

   ```sh
   npx supabase start
   npx supabase db reset
   npx supabase status
   ```

3. Copy `.env.example` to `.env.local`. Set `NEXT_PUBLIC_SUPABASE_URL` and `NEXT_PUBLIC_SUPABASE_ANON_KEY` from `supabase status`; set `SUPABASE_SERVICE_ROLE_KEY` to the local service-role key. Generate a long random `GAME_WORKER_SECRET`, for example:

   ```sh
   node -e "console.log(require('node:crypto').randomBytes(32).toString('hex'))"
   ```

4. Start Next.js:

   ```sh
   npm run dev
   ```

   Open `http://localhost:3000`, create a traveller account, and begin exploring. Local email confirmation is disabled in `supabase/config.toml`.

The worker endpoint is `POST /api/worker/dispatch` (or `GET` for scheduled callers) with `Authorization: Bearer <GAME_WORKER_SECRET>`. The included Vercel Cron runs every five minutes; configure `CRON_SECRET` to the same value as `GAME_WORKER_SECRET` in deployments. The endpoint processes bounded batches, expires bazaar listings, and delivers/retries outbox notifications. Keep the service-role key and worker secret server-only.

## Checks

```sh
npm run typecheck
npm run lint
npm test
npm run build
npx supabase test db
```

The SQL tests use the local Supabase/Postgres stack. Validate authorization and concurrent purchase/action behavior against a local database before deploying migrations to a shared project.
