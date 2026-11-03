# Mayanagari MMORPG: Engineering Plan and System Design

## Goals and assumptions

This is a greenfield design for an India-themed, text-based persistent MMORPG using TypeScript, Next.js/React, and Supabase. The initial launch includes character progression, energy/nerve, inventory, factions, an economy/marketplace, chat, and richer PvP. Gameplay is primarily asynchronous, with realtime notifications for selected events.

The design uses Next.js for the web experience and trusted server-side orchestration, Supabase Auth/Postgres/Realtime for identity, durable state, and selective event delivery, and PostgreSQL transactions/RPCs as the authority for game-state changes. It avoids one timer, process, or scheduled job per player. A shared, bounded scheduler/worker handles global events and due work; passive stats are calculated from elapsed time at request or mutation boundaries, with checkpoints persisted only when useful.

## System architecture

### Application boundaries

- **Next.js / React:** server-rendered pages and interactive client components. Route handlers/server actions authenticate requests, validate inputs, apply rate limits, and invoke narrowly scoped database functions. The browser never gets service-role credentials or direct authority to mutate balances, inventory, combat outcomes, or faction membership.
- **Supabase Auth:** account identity and session management. Keep game profile and character data separate from auth-owned identity data.
- **PostgreSQL:** canonical game state, constraints, transactions, combat/economy rules, audit records, and idempotency. Put multi-row critical actions in database functions or a trusted server transaction boundary so validation and mutation are atomic.
- **Supabase Realtime:** subscribe only to authorized, user/faction-scoped notifications or small event projections. Do not use it as the source of truth or stream full high-frequency game state.
- **Shared worker/scheduler:** one or a small bounded set of scheduled tasks dispatches due global events and bounded work batches. Use Supabase Cron/Edge Functions or an external queue/worker if workload measurements exceed Edge Function execution limits. Jobs must be retryable and idempotent.
- **Observability:** structured logs, job lag/failure metrics, game-action audit trails, database performance metrics, and alerts for economy anomalies and abuse.

### Domain and transaction patterns

- Treat each gameplay operation as a command: authenticate, validate, enforce cooldown/resource preconditions, mutate state atomically, write an audit/event record, then return an explicit result.
- Use optimistic concurrency (`version`/revision) or row locks for contested state. Lock records in a consistent order, keep transactions short, and add unique constraints as the final defense against duplicate operations.
- Require idempotency keys for retry-prone commands such as purchases, listings, PvP actions, rewards, and worker jobs. Store the request key and result under a unique constraint.
- Keep an append-only ledger for currency and valuable-item transfers; maintain balance/count projections transactionally. Reconcile projections from the ledger and alert on discrepancies.
- Separate immutable definitions (items, activities, locations, combat configuration) from per-character state. Version definitions so balance changes do not silently rewrite historical outcomes.
- Use explicit server-side validation and authorization for every action; RLS should protect user-owned reads and safe user-scoped access, not be the sole control for complex game rules.

### Frontend and API organization

- Organize TypeScript by domain (`characters`, `inventory`, `factions`, `market`, `combat`, `chat`) with shared validated command/result types.
- Keep UI state separate from authoritative persisted state; optimistically update only reversible presentation details and reconcile with server responses.
- Use server-rendered initial state where useful, small client components for interactions, and realtime subscriptions only on screens that need them.
- Centralize database access and error mapping; expose explicit domain errors (insufficient energy, stale listing, cooldown, permission denied) instead of silent fallbacks.

## Initial relational model

### Identity and progression

- `profiles`: `user_id` (FK to `auth.users`), public display fields, timestamps.
- `characters`: one or more characters per account if desired; level/experience, location, status, timestamps, optimistic `version`.
- `character_stats`: character ID, energy/nerve/current health, capacities, `*_updated_at`, regeneration rates or rate/config reference, and version. Keep resources that must be atomically consumed together in one locked row.

### Items and inventory

- `item_definitions`: stable item key, type, stackability, metadata/definition version.
- `inventories` / `inventory_slots`: owner character, item, quantity, slot/equipment state, uniqueness and nonnegative checks. Add capacity and stack constraints in transactional command logic.
- `item_transfers`: append-only item movement journal with source, destination, quantity, reason, command ID, and timestamp.

### Factions and social

- `factions`: name, description, leader, membership limits, created time.
- `faction_memberships`: faction/character, role, joined time, status; unique active membership constraints.
- `faction_events`: auditable donations, upgrades, wars, and membership changes.
- `chat_channels`, `chat_messages`, and moderation/report records: channel membership/access rules, server-stamped author/time, bounded message length, retention/moderation policy, and rate-limit keys. Keep private/social content out of broad realtime broadcasts.

### Economy and combat

- `wallets`: character and currency balance projection; version and constraints.
- `currency_ledger`: immutable signed entries, reason, related command/trade, and timestamp.
- `market_listings`: seller, item or currency, quantity, price, state, expiry, version; index active listings by search/sort fields.
- `market_transactions`: buyer/seller/listing, price/fees, item/ledger references, idempotency key.
- `combat_sessions` / `combat_actions`: participants, state/version, action sequence, outcomes, server timestamps, and audit metadata. Store authoritative outcomes, not client-supplied results.

### Operations and event delivery

- `idempotency_records`: actor, command key, request fingerprint, result/status, timestamps; unique actor/key.
- `outbox_events`: transactional event payload/reference and delivery state for reliable notifications.
- `scheduled_events` or `job_runs`: bounded global/due work, leases, attempts, next-run time, and completion state; index by due time and status.
- Add indexes from actual query patterns, foreign keys, check constraints, and retention/partitioning only when measured volume justifies it.

## Real-time stat modeling

Use integer units and timestamp-based accrual, not a row update every minute for every online/offline player. For a stat with capacity `cap`, current `value`, regeneration interval/rate `r`, and last checkpoint `t0`, derive available regeneration from elapsed time at the authoritative command/read boundary, clamp at capacity, and advance the checkpoint consistently. When capped, avoid accumulating excess regeneration by advancing the checkpoint to the appropriate capped reference time. Handle time using server/database timestamps and one documented unit/rounding rule.

For spending, lock the character stat row, derive the up-to-date value, validate sufficient resources, subtract cost, update the checkpoint/version, and commit the gameplay effect in the same transaction. Use one canonical function/helper for regeneration so reads, actions, and jobs cannot disagree. Reads can return derived values without writing on every page view; persist checkpoints on meaningful mutations and occasional bounded reconciliation. Do not send clients authoritative regeneration inputs that can be manipulated.

## Concurrent game loops without per-player server bloat

Do not create a timer or cron invocation for each character. Use two complementary mechanisms:

1. **Lazy stat accrual:** compute passive energy/nerve from timestamps when state is read for an action or a needed authoritative response; atomically persist only when changing state. This provides accurate offline progress with constant infrastructure cost.
2. **Shared scheduled processing:** run one global schedule at a chosen cadence for time-bounded events (market expiry, faction wars, daily resets, notifications, reconciliation). Select due rows in indexed batches, claim them with a lease/`FOR UPDATE SKIP LOCKED`-style pattern, commit claims quickly, and process idempotently. Keep batch size and execution time bounded; retry failures with backoff and dead-letter/alert after a defined attempt limit.

If requirements truly demand periodic materialized stat updates, process only due characters in bounded set-based batches, use leases/cursors and monitor backlog; do not make a separate cron job per player. Benchmark database write amplification and Supabase function duration before making this the normal path. Use a queue/external worker only when measured throughput or execution duration warrants added infrastructure.

## Realtime, security, and abuse controls

- Realtime is a notification layer: publish minimal events after committed transactions, preferably through an outbox/dispatcher so a DB commit cannot be lost between mutation and broadcast.
- Apply channel authorization and RLS to user/faction-scoped data; never trust a client-provided character ID, price, resource total, combat result, timestamp, or role.
- Validate all inputs with shared TypeScript schemas, enforce server-side cooldowns and rate limits, and use database constraints/transactions for races.
- Protect marketplace and PvP commands from replay/double-submit through idempotency and unique business constraints. Audit administrative actions and provide moderation tools for chat and player reports.
- Keep secrets server-only, use least-privilege keys, and test authorization boundaries with multiple users/roles.

## Milestone roadmap

1. **Foundation and threat model:** confirm game rules, single/multiple characters, resource formulas, currency/items, moderation expectations, and initial load targets. Establish Next.js/TypeScript conventions, environments, migrations, CI, Supabase local development, logging, and RLS test fixtures.
2. **Identity and core character loop:** profiles/characters, stat model, canonical regeneration/spend transaction, activities, inventory definitions/storage, idempotent commands, and basic UI. Validate offline accrual, capacity clamping, simultaneous spending, and retries.
3. **Items, progression, and event infrastructure:** rewards/experience, equipment/use-item flows, ledgers/audit, outbox, shared scheduler with leases/retries, and due-event monitoring.
4. **Factions and social:** faction creation/membership/roles, faction event journal, chat channels/messages/moderation/rate limits, scoped RLS, and selective realtime delivery.
5. **Economy and marketplace:** wallets/ledger, listing lifecycle, atomic purchase/cancellation/expiry, fees, anti-duplication, reconciliation, and load/race tests for competing buyers.
6. **Combat and richer PvP:** authoritative combat rules, resource/cooldown checks, combat history, concurrency handling, abuse controls, and notification UX; add balancing telemetry without exposing hidden server rules.
7. **Hardening and launch:** load/soak tests, database query/index tuning, backups/restore drill, RLS/security review, admin/moderation workflow, economy monitoring, incident runbooks, accessibility/mobile polish, and staged rollout.

## Verification gates

- Unit tests for regeneration math, rounding, capacity, and cooldown rules with boundary timestamps.
- Database/integration tests for two simultaneous spends, duplicate idempotent requests, buying one contested listing, inventory/wallet conservation, RLS isolation, and worker retries.
- Load tests for active-player reads, bursty commands, marketplace contention, chat, and scheduler backlog; set measurable latency and queue-lag targets before launch.
- Reconciliation tests proving ledger and inventory transfer records reproduce wallet/item projections.

## Design considerations

- The requested frequent worker tick model is implemented as a shared bounded worker, not a per-player timer. Per-request timestamp accrual is more efficient for passive stats; the worker should focus on due discrete events and optional bounded materialization only if product rules require it.
- Supabase/Postgres are a sound MVP foundation, but marketplace contention, chat volume, and realtime fanout should be measured early. Keep domain boundaries and event contracts so high-volume components can be moved to a queue/service later without changing game rules.
- Express the India theme through original setting, names, locations, and narrative; keep locale/timezone display separate from canonical UTC timestamps and game rules.

## Implemented foundation

The runnable repository now includes a Next.js App Router application with English/Hindi UI, original Mayanagari neighbourhood/item/activity seed content, Supabase SSR authentication, and a single playable city dashboard. The initial Supabase migration contains the domain tables, RLS/grants, account bootstrap trigger, timestamp-regeneration and gameplay RPCs, ledgers/item-transfer journal, report/moderation support, and combat challenge/accept/turn-based actions.

The five-minute shared worker is at `/api/worker/dispatch`. It expires bounded batches of bazaar listings and unanswered PvP challenges, claims due jobs and transactional outbox events with leases, and sends user-scoped Realtime broadcasts. Set `CRON_SECRET` equal to `GAME_WORKER_SECRET` for the included Vercel Cron. The worker currently handles `market_expiry` jobs; add explicit handlers and tests before scheduling new job kinds.

Use the local setup and test instructions in [README.md](../README.md). PostgreSQL integration, RLS isolation, and idempotency cases are described in [supabase/tests/game_invariants.sql](../supabase/tests/game_invariants.sql); run them with the Supabase local stack before deployment. Load testing, backup/restore drills, and production moderation/operations remain launch gates rather than claims of completion.
