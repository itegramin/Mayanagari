create extension if not exists pgcrypto with schema extensions;

create type public.regenerated_stat as (
  value integer,
  updated_at timestamptz
);

create table public.locations (
  id text primary key,
  name_en text not null,
  name_hi text not null,
  description_en text not null,
  description_hi text not null,
  created_at timestamptz not null default now()
);

insert into public.locations (id, name_en, name_hi, description_en, description_hi) values
  ('rangmahal', 'Rangmahal Quarter', 'रंगमहल मोहल्ला', 'A lantern-lit old quarter where painters, bookbinders, and tea sellers share the same lively lanes.', 'रंगीन लालटेनों वाला पुराना इलाक़ा, जहाँ चित्रकार, जिल्दसाज़ और चायवाले चहल-पहल भरी गलियों में साथ रहते हैं।'),
  ('monsoon-ghat', 'Monsoon Ghat', 'मानसून घाट', 'Wide stone steps descend to the river. After the rains, musicians gather beneath the banyan trees.', 'पत्थर की चौड़ी सीढ़ियाँ नदी तक उतरती हैं। बरसात के बाद बरगदों के नीचे संगीतकार जुटते हैं।'),
  ('saffron-market', 'Saffron Market', 'केसर बाज़ार', 'A covered bazaar of spice merchants, repair stalls, brasswork, and fresh jalebi at dawn.', 'मसालों की दुकानों, मरम्मत के ठेलों, पीतल के काम और सुबह की ताज़ी जलेबी वाला ढका बाज़ार।'),
  ('neem-gardens', 'Neem Gardens', 'नीम के बाग़', 'Quiet garden paths wind between neem trees, a community library, and a small open-air theatre.', 'नीम के पेड़ों, सामुदायिक पुस्तकालय और खुले रंगमंच के बीच से गुज़रते शांत रास्ते।')
on conflict (id) do nothing;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  handle text not null unique,
  display_name text not null check (char_length(display_name) between 2 and 40),
  locale text not null default 'en' check (locale in ('en', 'hi')),
  is_moderator boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.characters (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null unique references public.profiles(id) on delete cascade,
  name text not null check (char_length(name) between 2 and 32),
  level integer not null default 1 check (level >= 1),
  experience bigint not null default 0 check (experience >= 0),
  location_id text not null default 'rangmahal' references public.locations(id),
  faction_id uuid,
  last_pvp_at timestamptz,
  version bigint not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.character_stats (
  character_id uuid primary key references public.characters(id) on delete cascade,
  energy integer not null default 100 check (energy >= 0),
  energy_capacity integer not null default 100 check (energy_capacity > 0),
  energy_updated_at timestamptz not null default now(),
  energy_regen_seconds integer not null default 300 check (energy_regen_seconds > 0),
  nerve integer not null default 20 check (nerve >= 0),
  nerve_capacity integer not null default 20 check (nerve_capacity > 0),
  nerve_updated_at timestamptz not null default now(),
  nerve_regen_seconds integer not null default 900 check (nerve_regen_seconds > 0),
  health integer not null default 100 check (health >= 0),
  health_capacity integer not null default 100 check (health_capacity > 0),
  health_updated_at timestamptz not null default now(),
  health_regen_seconds integer not null default 600 check (health_regen_seconds > 0),
  version bigint not null default 0,
  check (energy <= energy_capacity),
  check (nerve <= nerve_capacity),
  check (health <= health_capacity)
);

create table public.item_definitions (
  id text primary key,
  name_en text not null,
  name_hi text not null,
  description_en text not null,
  description_hi text not null,
  stackable boolean not null default true,
  max_stack integer not null default 99 check (max_stack > 0),
  item_version integer not null default 1 check (item_version > 0)
);

insert into public.item_definitions (id, name_en, name_hi, description_en, description_hi, stackable) values
  ('cutting-chai', 'Cutting Chai', 'कटिंग चाय', 'A small, sweet cup of spiced tea. Restores a little energy.', 'मसालेदार मीठी चाय का छोटा प्याला। थोड़ी ऊर्जा लौटाता है।', true),
  ('block-print-swatch', 'Block-print Swatch', 'ब्लॉक-प्रिंट कपड़ा', 'A hand-printed cotton swatch from a Rangmahal workshop.', 'रंगमहल की कार्यशाला में हाथ से छपा सूती कपड़ा।', true),
  ('river-polished-stone', 'River-polished Stone', 'नदी का चिकना पत्थर', 'A smooth stone gathered from the Monsoon Ghat.', 'मानसून घाट से मिला चिकना पत्थर।', true)
on conflict (id) do nothing;

create table public.inventories (
  character_id uuid not null references public.characters(id) on delete cascade,
  item_id text not null references public.item_definitions(id),
  quantity integer not null check (quantity between 1 and 1000000),
  updated_at timestamptz not null default now(),
  primary key (character_id, item_id)
);

create table public.item_transfers (
  id bigint generated always as identity primary key,
  item_id text not null references public.item_definitions(id),
  from_character_id uuid references public.characters(id),
  to_character_id uuid references public.characters(id),
  quantity integer not null check (quantity > 0),
  reason text not null,
  reference_id uuid,
  command_key uuid,
  created_at timestamptz not null default now(),
  check (from_character_id is distinct from to_character_id)
);

create index item_transfers_from_created_idx
  on public.item_transfers (from_character_id, created_at desc);
create index item_transfers_to_created_idx
  on public.item_transfers (to_character_id, created_at desc);

create table public.activities (
  id text primary key,
  location_id text not null references public.locations(id),
  name_en text not null,
  name_hi text not null,
  description_en text not null,
  description_hi text not null,
  energy_cost integer not null default 0 check (energy_cost >= 0),
  nerve_cost integer not null default 0 check (nerve_cost >= 0),
  experience_reward integer not null default 0 check (experience_reward >= 0),
  rupee_reward integer not null default 0 check (rupee_reward >= 0),
  item_reward text references public.item_definitions(id),
  item_quantity integer not null default 0 check (item_quantity >= 0),
  cooldown_seconds integer not null default 0 check (cooldown_seconds >= 0),
  enabled boolean not null default true
);

create table public.activity_cooldowns (
  character_id uuid not null references public.characters(id) on delete cascade,
  activity_id text not null references public.activities(id) on delete cascade,
  last_used_at timestamptz not null,
  primary key (character_id, activity_id)
);

insert into public.activities (
  id, location_id, name_en, name_hi, description_en, description_hi,
  energy_cost, nerve_cost, experience_reward, rupee_reward, item_reward, item_quantity
) values
  ('help-printmaker', 'rangmahal', 'Help at the printmaker''s', 'छापेख़ाने में हाथ बँटाएँ', 'Set wooden blocks and learn how colour moves through cloth.', 'लकड़ी के ठप्पे सजाएँ और कपड़े पर रंगों का सफ़र सीखें।', 8, 0, 12, 8, 'block-print-swatch', 1),
  ('river-courier', 'monsoon-ghat', 'Carry a riverside parcel', 'नदी किनारे का पार्सल पहुँचाएँ', 'Find the right courtyard using a hand-drawn map.', 'हाथ से बने नक़्शे की मदद से सही आँगन तक पहुँचें।', 12, 2, 20, 18, 'river-polished-stone', 1),
  ('market-errand', 'saffron-market', 'Run a market errand', 'बाज़ार का काम निपटाएँ', 'Help a spice seller deliver a ledger before the lunch rush.', 'दोपहर की भीड़ से पहले मसाला-विक्रेता की बही पहुँचाएँ।', 10, 0, 15, 14, null, 0),
  ('library-volunteer', 'neem-gardens', 'Volunteer at the library', 'पुस्तकालय में सेवा करें', 'Sort donated books and hear stories from the neighbourhood.', 'दान में आई किताबें सजाएँ और मोहल्ले की कहानियाँ सुनें।', 6, 0, 10, 6, null, 0)
on conflict (id) do nothing;

create table public.wallets (
  character_id uuid primary key references public.characters(id) on delete cascade,
  balance bigint not null default 0 check (balance between 0 and 9000000000000),
  version bigint not null default 0,
  updated_at timestamptz not null default now()
);

create table public.currency_ledger (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters(id),
  delta bigint not null check (delta <> 0),
  balance_after bigint not null check (balance_after between 0 and 9000000000000),
  reason text not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create index currency_ledger_character_created_idx
  on public.currency_ledger (character_id, created_at desc);

create table public.idempotency_records (
  actor_id uuid not null references auth.users(id) on delete cascade,
  command_key uuid not null,
  command_name text not null,
  request_hash text not null,
  response jsonb,
  created_at timestamptz not null default now(),
  primary key (actor_id, command_key)
);

create table public.outbox_events (
  id bigint generated always as identity primary key,
  owner_id uuid not null references auth.users(id),
  topic text not null,
  payload jsonb not null,
  created_at timestamptz not null default now(),
  delivered_at timestamptz,
  failed_at timestamptz,
  claimed_until timestamptz,
  attempts integer not null default 0 check (attempts >= 0),
  last_error text
);

create index outbox_events_due_idx on public.outbox_events (id)
  where delivered_at is null;

create table public.game_jobs (
  id uuid primary key default gen_random_uuid(),
  kind text not null,
  payload jsonb not null default '{}'::jsonb,
  run_at timestamptz not null,
  status text not null default 'pending' check (status in ('pending', 'claimed', 'done', 'dead')),
  attempts integer not null default 0 check (attempts >= 0),
  lease_until timestamptz,
  last_error text,
  created_at timestamptz not null default now()
);

create index game_jobs_due_idx on public.game_jobs (run_at, id)
  where status in ('pending', 'claimed');

create table public.factions (
  id uuid primary key default gen_random_uuid(),
  name text not null unique check (char_length(name) between 3 and 32),
  name_hi text not null check (char_length(name_hi) between 2 and 40),
  description text not null default '' check (char_length(description) <= 500),
  leader_character_id uuid not null references public.characters(id),
  member_limit integer not null default 25 check (member_limit between 2 and 100),
  created_at timestamptz not null default now()
);

alter table public.characters add constraint characters_faction_fk
  foreign key (faction_id) references public.factions(id) on delete set null;

create table public.faction_memberships (
  faction_id uuid not null references public.factions(id) on delete cascade,
  character_id uuid not null references public.characters(id) on delete cascade,
  role text not null default 'member' check (role in ('leader', 'officer', 'member')),
  joined_at timestamptz not null default now(),
  primary key (faction_id, character_id),
  unique (character_id)
);

create table public.faction_events (
  id bigint generated always as identity primary key,
  faction_id uuid not null references public.factions(id) on delete cascade,
  character_id uuid references public.characters(id) on delete set null,
  event_type text not null,
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table public.chat_channels (
  id uuid primary key default gen_random_uuid(),
  slug text unique,
  kind text not null check (kind in ('city', 'faction')),
  faction_id uuid unique references public.factions(id) on delete cascade,
  name_en text not null,
  name_hi text not null,
  created_at timestamptz not null default now(),
  check ((kind = 'city' and faction_id is null) or (kind = 'faction' and faction_id is not null))
);

insert into public.chat_channels (id, slug, kind, name_en, name_hi)
values ('00000000-0000-4000-8000-000000000001', 'city-square', 'city', 'City Square', 'नगर चौक')
on conflict (id) do nothing;

create table public.chat_messages (
  id bigint generated always as identity primary key,
  channel_id uuid not null references public.chat_channels(id) on delete cascade,
  character_id uuid not null references public.characters(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 500),
  created_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index chat_messages_channel_created_idx
  on public.chat_messages (channel_id, created_at desc);
create index chat_messages_character_created_idx
  on public.chat_messages (character_id, created_at desc);

create table public.chat_reports (
  id bigint generated always as identity primary key,
  message_id bigint not null references public.chat_messages(id) on delete cascade,
  reporter_character_id uuid not null references public.characters(id) on delete cascade,
  reason text not null check (char_length(reason) between 3 and 300),
  status text not null default 'open' check (status in ('open', 'reviewed', 'actioned', 'dismissed')),
  reviewed_by uuid references auth.users(id),
  created_at timestamptz not null default now(),
  unique (message_id, reporter_character_id)
);

create table public.market_listings (
  id uuid primary key default gen_random_uuid(),
  seller_character_id uuid not null references public.characters(id),
  item_id text not null references public.item_definitions(id),
  quantity integer not null check (quantity between 1 and 1000000),
  unit_price bigint not null check (unit_price between 1 and 1000000000),
  status text not null default 'active' check (status in ('active', 'sold', 'cancelled', 'expired')),
  expires_at timestamptz not null default (now() + interval '7 days'),
  created_at timestamptz not null default now(),
  version bigint not null default 0
);

create index market_listings_active_search_idx
  on public.market_listings (item_id, unit_price, created_at)
  where status = 'active';

create table public.market_transactions (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null references public.market_listings(id),
  buyer_character_id uuid not null references public.characters(id),
  seller_character_id uuid not null references public.characters(id),
  quantity integer not null check (quantity > 0),
  gross_amount bigint not null check (gross_amount > 0),
  fee_amount bigint not null check (fee_amount >= 0),
  created_at timestamptz not null default now()
);

create table public.combat_sessions (
  id uuid primary key default gen_random_uuid(),
  attacker_character_id uuid not null references public.characters(id),
  defender_character_id uuid not null references public.characters(id),
  winner_character_id uuid references public.characters(id),
  status text not null default 'pending' check (status in ('pending', 'active', 'finished', 'declined', 'expired')),
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '5 minutes'),
  finished_at timestamptz,
  check (attacker_character_id <> defender_character_id)
);

create unique index combat_pair_in_progress_idx
  on public.combat_sessions (
    least(attacker_character_id, defender_character_id),
    greatest(attacker_character_id, defender_character_id)
  )
  where status in ('pending', 'active');

create index combat_challenges_due_idx
  on public.combat_sessions (expires_at)
  where status = 'pending';

create table public.combat_actions (
  id bigint generated always as identity primary key,
  session_id uuid not null references public.combat_sessions(id) on delete cascade,
  actor_character_id uuid not null references public.characters(id),
  action_type text not null,
  damage integer not null default 0 check (damage >= 0),
  details jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create or replace function public.regenerate_stat(
  p_value integer,
  p_capacity integer,
  p_updated_at timestamptz,
  p_seconds_per_point integer,
  p_now timestamptz
) returns public.regenerated_stat
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_result public.regenerated_stat;
  v_elapsed bigint;
  v_points integer;
begin
  if p_value < 0 or p_capacity <= 0 or p_value > p_capacity
     or p_seconds_per_point <= 0 then
    raise exception 'invalid_stat_state' using errcode = '22023';
  end if;

  v_elapsed := greatest(0, floor(extract(epoch from (p_now - p_updated_at)))::bigint);
  v_points := floor(v_elapsed::numeric / p_seconds_per_point)::integer;
  v_result.value := least(p_capacity, p_value + v_points);
  if v_result.value = p_capacity then
    v_result.updated_at := greatest(p_now, p_updated_at);
  else
    v_result.updated_at := p_updated_at + make_interval(secs => v_points * p_seconds_per_point);
  end if;
  return v_result;
end;
$$;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_display_name text;
  v_handle text;
  v_character_id uuid;
begin
  v_display_name := left(coalesce(nullif(trim(new.raw_user_meta_data ->> 'display_name'), ''), 'Newcomer'), 40);
  if char_length(v_display_name) < 2 then
    v_display_name := 'Newcomer';
  end if;
  v_handle := 'traveller_' || replace(left(new.id::text, 8), '-', '');

  insert into public.profiles (id, handle, display_name)
  values (new.id, v_handle, v_display_name);

  insert into public.characters (owner_id, name)
  values (new.id, left(v_display_name, 32))
  returning id into v_character_id;

  insert into public.character_stats (character_id) values (v_character_id);
  insert into public.wallets (character_id, balance) values (v_character_id, 100);
  insert into public.currency_ledger (character_id, delta, balance_after, reason)
  values (v_character_id, 100, 100, 'welcome_grant');
  insert into public.inventories (character_id, item_id, quantity)
  values (v_character_id, 'cutting-chai', 2);
  insert into public.item_transfers (item_id, to_character_id, quantity, reason)
  values ('cutting-chai', v_character_id, 2, 'welcome_grant');

  return new;
end;
$$;

create trigger on_auth_user_created
after insert on auth.users
for each row execute function public.handle_new_user();

create or replace function public.my_game_state()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_character public.characters%rowtype;
  v_stats public.character_stats%rowtype;
  v_wallet public.wallets%rowtype;
  v_energy public.regenerated_stat;
  v_nerve public.regenerated_stat;
  v_health public.regenerated_stat;
begin
  select * into v_character from public.characters where owner_id = auth.uid();
  if not found then
    raise exception 'character_not_found' using errcode = 'P0002';
  end if;
  select * into v_stats from public.character_stats where character_id = v_character.id;
  select * into v_wallet from public.wallets where character_id = v_character.id;
  v_energy := public.regenerate_stat(v_stats.energy, v_stats.energy_capacity, v_stats.energy_updated_at, v_stats.energy_regen_seconds, statement_timestamp());
  v_nerve := public.regenerate_stat(v_stats.nerve, v_stats.nerve_capacity, v_stats.nerve_updated_at, v_stats.nerve_regen_seconds, statement_timestamp());
  v_health := public.regenerate_stat(v_stats.health, v_stats.health_capacity, v_stats.health_updated_at, v_stats.health_regen_seconds, statement_timestamp());

  return jsonb_build_object(
    'character', jsonb_build_object(
      'id', v_character.id, 'name', v_character.name, 'level', v_character.level,
      'experience', v_character.experience, 'location_id', v_character.location_id,
      'faction_id', v_character.faction_id, 'version', v_character.version
    ),
    'stats', jsonb_build_object(
      'energy', v_energy.value, 'energy_capacity', v_stats.energy_capacity,
      'nerve', v_nerve.value, 'nerve_capacity', v_stats.nerve_capacity,
      'health', v_health.value, 'health_capacity', v_stats.health_capacity,
      'version', v_stats.version
    ),
    'wallet', jsonb_build_object('balance', v_wallet.balance),
    'location', (select jsonb_build_object('id', id, 'name_en', name_en, 'name_hi', name_hi, 'description_en', description_en, 'description_hi', description_hi) from public.locations where id = v_character.location_id),
    'inventory', coalesce((
      select jsonb_agg(jsonb_build_object('item_id', i.item_id, 'quantity', i.quantity, 'name_en', d.name_en, 'name_hi', d.name_hi, 'description_en', d.description_en, 'description_hi', d.description_hi) order by d.name_en)
      from public.inventories i join public.item_definitions d on d.id = i.item_id
      where i.character_id = v_character.id
    ), '[]'::jsonb),
    'faction', (select jsonb_build_object('id', f.id, 'name', f.name, 'name_hi', f.name_hi) from public.factions f where f.id = v_character.faction_id)
  );
end;
$$;

create or replace function public.perform_activity(p_activity_id text, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character public.characters%rowtype;
  v_stats public.character_stats%rowtype;
  v_activity public.activities%rowtype;
  v_wallet public.wallets%rowtype;
  v_energy public.regenerated_stat;
  v_nerve public.regenerated_stat;
  v_now timestamptz := statement_timestamp();
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('activity_id', p_activity_id)::text, 'UTF8'), 'sha256'), 'hex');
  v_cached public.idempotency_records%rowtype;
  v_result jsonb;
  v_new_xp bigint;
  v_new_balance bigint;
  v_cooldown_used timestamptz;
begin
  if v_actor is null or p_command_key is null then
    raise exception 'authentication_required' using errcode = '28000';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'perform_activity' or v_cached.request_hash <> v_hash then
      raise exception 'idempotency_key_reused' using errcode = '22023';
    end if;
    return v_cached.response;
  end if;

  select * into v_character from public.characters where owner_id = v_actor for update;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  select * into v_stats from public.character_stats where character_id = v_character.id for update;
  select * into v_activity from public.activities where id = p_activity_id and enabled;
  if not found then raise exception 'activity_unavailable' using errcode = '22023'; end if;
  if v_activity.location_id <> v_character.location_id then
    raise exception 'wrong_location' using errcode = '22023';
  end if;
  if v_activity.cooldown_seconds > 0 then
    insert into public.activity_cooldowns (character_id, activity_id, last_used_at)
    values (v_character.id, v_activity.id, v_now)
    on conflict (character_id, activity_id)
    do update set last_used_at = excluded.last_used_at
      where public.activity_cooldowns.last_used_at <= v_now - make_interval(secs => v_activity.cooldown_seconds)
    returning last_used_at into v_cooldown_used;
    if not found then raise exception 'activity_cooldown' using errcode = '22023'; end if;
  end if;

  v_energy := public.regenerate_stat(v_stats.energy, v_stats.energy_capacity, v_stats.energy_updated_at, v_stats.energy_regen_seconds, v_now);
  v_nerve := public.regenerate_stat(v_stats.nerve, v_stats.nerve_capacity, v_stats.nerve_updated_at, v_stats.nerve_regen_seconds, v_now);
  if v_energy.value < v_activity.energy_cost or v_nerve.value < v_activity.nerve_cost then
    raise exception 'insufficient_resources' using errcode = '22023';
  end if;

  update public.character_stats set
    energy = v_energy.value - v_activity.energy_cost,
    energy_updated_at = case when v_energy.value = energy_capacity then v_now else v_energy.updated_at end,
    nerve = v_nerve.value - v_activity.nerve_cost,
    nerve_updated_at = case when v_nerve.value = nerve_capacity then v_now else v_nerve.updated_at end,
    version = version + 1
  where character_id = v_character.id;

  v_new_xp := v_character.experience + v_activity.experience_reward;
  update public.characters set
    experience = v_new_xp,
    level = greatest(1, floor(sqrt(v_new_xp::numeric / 100))::integer + 1),
    version = version + 1,
    updated_at = v_now
  where id = v_character.id;

  select * into v_wallet from public.wallets where character_id = v_character.id for update;
  if v_activity.rupee_reward > 0 then
    v_new_balance := v_wallet.balance + v_activity.rupee_reward;
    if v_new_balance > 9000000000000 then raise exception 'wallet_capacity' using errcode = '22023'; end if;
    update public.wallets set balance = v_new_balance, version = version + 1, updated_at = v_now where character_id = v_character.id;
    insert into public.currency_ledger (character_id, delta, balance_after, reason)
    values (v_character.id, v_activity.rupee_reward, v_new_balance, 'activity_reward:' || v_activity.id);
  else
    v_new_balance := v_wallet.balance;
  end if;

  if v_activity.item_reward is not null and v_activity.item_quantity > 0 then
    insert into public.inventories (character_id, item_id, quantity)
    values (v_character.id, v_activity.item_reward, v_activity.item_quantity)
    on conflict (character_id, item_id)
    do update set quantity = public.inventories.quantity + excluded.quantity, updated_at = v_now;
    insert into public.item_transfers (item_id, to_character_id, quantity, reason, command_key)
    values (v_activity.item_reward, v_character.id, v_activity.item_quantity, 'activity_reward:' || v_activity.id, p_command_key);
  end if;

  insert into public.outbox_events (owner_id, topic, payload)
  values (v_actor, 'activity.completed', jsonb_build_object('activity_id', v_activity.id, 'experience', v_activity.experience_reward));
  v_result := jsonb_build_object('ok', true, 'experience_gained', v_activity.experience_reward, 'rupees_gained', v_activity.rupee_reward);
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'perform_activity', v_hash, v_result);
  return v_result;
end;
$$;

create or replace function public.use_item(p_item_id text, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character_id uuid;
  v_inventory public.inventories%rowtype;
  v_stats public.character_stats%rowtype;
  v_energy public.regenerated_stat;
  v_now timestamptz := statement_timestamp();
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('item_id', p_item_id)::text, 'UTF8'), 'sha256'), 'hex');
  v_cached public.idempotency_records%rowtype;
  v_result jsonb;
begin
  if v_actor is null or p_command_key is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'use_item' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;
  select id into v_character_id from public.characters where owner_id = v_actor for update;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  select * into v_inventory from public.inventories where character_id = v_character_id and item_id = p_item_id for update;
  if not found then raise exception 'insufficient_items' using errcode = '22023'; end if;
  select * into v_stats from public.character_stats where character_id = v_character_id for update;
  v_energy := public.regenerate_stat(v_stats.energy, v_stats.energy_capacity, v_stats.energy_updated_at, v_stats.energy_regen_seconds, v_now);
  if p_item_id <> 'cutting-chai' then raise exception 'item_not_usable' using errcode = '22023'; end if;
  if v_energy.value >= v_stats.energy_capacity then raise exception 'stat_already_full' using errcode = '22023'; end if;

  update public.inventories set quantity = quantity - 1, updated_at = v_now where character_id = v_character_id and item_id = p_item_id;
  delete from public.inventories where character_id = v_character_id and item_id = p_item_id and quantity = 0;
  insert into public.item_transfers (item_id, from_character_id, quantity, reason, command_key)
  values (p_item_id, v_character_id, 1, 'item_used', p_command_key);
  update public.character_stats set
    energy = least(energy_capacity, v_energy.value + 25),
    energy_updated_at = case
      when v_energy.value + 25 >= energy_capacity then v_now
      else v_energy.updated_at
    end,
    version = version + 1
  where character_id = v_character_id;
  v_result := jsonb_build_object('ok', true, 'item_id', p_item_id, 'energy_restored', least(25, v_stats.energy_capacity - v_energy.value));
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'use_item', v_hash, v_result);
  return v_result;
end;
$$;

create or replace function public.move_character(p_location_id text, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character public.characters%rowtype;
  v_cached public.idempotency_records%rowtype;
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('location_id', p_location_id)::text, 'UTF8'), 'sha256'), 'hex');
  v_result jsonb;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if p_command_key is null then raise exception 'command_key_required' using errcode = '22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'move_character' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;
  if not exists (select 1 from public.locations where id = p_location_id) then raise exception 'location_not_found' using errcode = 'P0002'; end if;
  select * into v_character from public.characters where owner_id = v_actor for update;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  update public.characters set location_id = p_location_id, version = version + 1, updated_at = statement_timestamp() where id = v_character.id;
  v_result := jsonb_build_object('ok', true, 'location_id', p_location_id);
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'move_character', v_hash, v_result);
  return v_result;
end;
$$;

create or replace function public.create_faction(p_name text, p_name_hi text, p_description text, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character public.characters%rowtype;
  v_cached public.idempotency_records%rowtype;
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('name', trim(p_name), 'name_hi', trim(p_name_hi), 'description', coalesce(p_description, ''))::text, 'UTF8'), 'sha256'), 'hex');
  v_faction_id uuid;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if p_command_key is null then raise exception 'command_key_required' using errcode = '22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'create_faction' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;
  select * into v_character from public.characters where owner_id = v_actor for update;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  if v_character.faction_id is not null then raise exception 'already_in_faction' using errcode = '22023'; end if;
  insert into public.factions (name, name_hi, description, leader_character_id)
  values (trim(p_name), trim(p_name_hi), coalesce(p_description, ''), v_character.id)
  returning id into v_faction_id;
  insert into public.faction_memberships (faction_id, character_id, role) values (v_faction_id, v_character.id, 'leader');
  update public.characters set faction_id = v_faction_id, version = version + 1 where id = v_character.id;
  insert into public.chat_channels (kind, faction_id, name_en, name_hi)
  values ('faction', v_faction_id, trim(p_name) || ' Hall', trim(p_name_hi) || ' सभा');
  insert into public.faction_events (faction_id, character_id, event_type)
  values (v_faction_id, v_character.id, 'faction.created');
  v_result := jsonb_build_object('ok', true, 'faction_id', v_faction_id);
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'create_faction', v_hash, v_result);
  return v_result;
end;
$$;

create or replace function public.join_faction(p_faction_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character public.characters%rowtype;
  v_faction public.factions%rowtype;
  v_count integer;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  select * into v_character from public.characters where owner_id = v_actor for update;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  if v_character.faction_id is not null then raise exception 'already_in_faction' using errcode = '22023'; end if;
  select * into v_faction from public.factions where id = p_faction_id for update;
  if not found then raise exception 'faction_not_found' using errcode = 'P0002'; end if;
  select count(*) into v_count from public.faction_memberships where faction_id = p_faction_id;
  if v_count >= v_faction.member_limit then raise exception 'faction_full' using errcode = '22023'; end if;
  insert into public.faction_memberships (faction_id, character_id) values (p_faction_id, v_character.id);
  update public.characters set faction_id = p_faction_id, version = version + 1 where id = v_character.id;
  insert into public.faction_events (faction_id, character_id, event_type)
  values (p_faction_id, v_character.id, 'member.joined');
  return jsonb_build_object('ok', true, 'faction_id', p_faction_id);
end;
$$;

create or replace function public.leave_faction()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character public.characters%rowtype;
  v_role text;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  select * into v_character from public.characters where owner_id = v_actor for update;
  if not found or v_character.faction_id is null then raise exception 'not_in_faction' using errcode = '22023'; end if;
  select role into v_role from public.faction_memberships where character_id = v_character.id and faction_id = v_character.faction_id for update;
  if v_role = 'leader' and exists (select 1 from public.faction_memberships where faction_id = v_character.faction_id and character_id <> v_character.id) then
    raise exception 'leader_must_transfer_or_disband' using errcode = '22023';
  end if;
  insert into public.faction_events (faction_id, character_id, event_type)
  values (v_character.faction_id, v_character.id, 'member.left');
  delete from public.faction_memberships where character_id = v_character.id;
  update public.characters set faction_id = null, version = version + 1 where id = v_character.id;
  if v_role = 'leader' then delete from public.factions where id = v_character.faction_id; end if;
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.transfer_faction_leadership(p_target_character_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_leader_id uuid;
  v_faction_id uuid;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  select id, faction_id into v_leader_id, v_faction_id
  from public.characters where owner_id = v_actor for update;
  if not found or v_faction_id is null then raise exception 'not_in_faction' using errcode = '22023'; end if;
  perform id from public.factions where id = v_faction_id for update;
  if not exists (
    select 1 from public.faction_memberships
    where faction_id = v_faction_id and character_id = v_leader_id and role = 'leader'
  ) then raise exception 'faction_leader_required' using errcode = '42501'; end if;
  perform faction_id from public.faction_memberships
  where faction_id = v_faction_id and character_id = p_target_character_id for update;
  if not found then raise exception 'faction_member_not_found' using errcode = 'P0002'; end if;
  update public.faction_memberships set role = 'officer'
  where faction_id = v_faction_id and character_id = v_leader_id;
  update public.faction_memberships set role = 'leader'
  where faction_id = v_faction_id and character_id = p_target_character_id;
  update public.factions set leader_character_id = p_target_character_id where id = v_faction_id;
  insert into public.faction_events (faction_id, character_id, event_type, details)
  values (v_faction_id, v_leader_id, 'leadership.transferred', jsonb_build_object('new_leader_character_id', p_target_character_id));
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.can_read_chat_channel(p_channel_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.chat_channels c
    where c.id = p_channel_id
      and (c.kind = 'city' or exists (
        select 1 from public.faction_memberships m
        join public.characters ch on ch.id = m.character_id
        where m.faction_id = c.faction_id and ch.owner_id = auth.uid()
      ))
  );
$$;

create or replace function public.send_chat_message(p_channel_id uuid, p_body text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character_id uuid;
  v_message_id bigint;
  v_clean_body text := trim(p_body);
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if char_length(v_clean_body) not between 1 and 500 then raise exception 'invalid_message' using errcode = '22023'; end if;
  select id into v_character_id from public.characters where owner_id = v_actor;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  if not public.can_read_chat_channel(p_channel_id) then raise exception 'channel_forbidden' using errcode = '42501'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_character_id::text || p_channel_id::text, 0));
  if (select count(*) from public.chat_messages where character_id = v_character_id and created_at > statement_timestamp() - interval '10 seconds') >= 5 then
    raise exception 'chat_rate_limited' using errcode = '22023';
  end if;
  insert into public.chat_messages (channel_id, character_id, body)
  values (p_channel_id, v_character_id, v_clean_body)
  returning id into v_message_id;
  return jsonb_build_object('ok', true, 'message_id', v_message_id);
end;
$$;

create or replace function public.report_chat_message(p_message_id bigint, p_reason text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_character_id uuid;
begin
  select id into v_character_id from public.characters where owner_id = auth.uid();
  if v_character_id is null then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  if not exists (select 1 from public.chat_messages where id = p_message_id and deleted_at is null) then raise exception 'message_not_found' using errcode = 'P0002'; end if;
  insert into public.chat_reports (message_id, reporter_character_id, reason)
  values (p_message_id, v_character_id, trim(p_reason));
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.moderate_chat_message(p_message_id bigint, p_action text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not exists (select 1 from public.profiles where id = auth.uid() and is_moderator) then
    raise exception 'moderator_required' using errcode = '42501';
  end if;
  if p_action not in ('delete', 'restore') then raise exception 'invalid_moderation_action' using errcode = '22023'; end if;
  update public.chat_messages set deleted_at = case when p_action = 'delete' then statement_timestamp() else null end
  where id = p_message_id;
  if not found then raise exception 'message_not_found' using errcode = 'P0002'; end if;
  update public.chat_reports set status = case when p_action = 'delete' then 'actioned' else 'reviewed' end,
    reviewed_by = auth.uid()
  where message_id = p_message_id and status = 'open';
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.create_market_listing(p_item_id text, p_quantity integer, p_unit_price bigint, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_character_id uuid;
  v_listing_id uuid;
  v_inventory public.inventories%rowtype;
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('item_id', p_item_id, 'quantity', p_quantity, 'unit_price', p_unit_price)::text, 'UTF8'), 'sha256'), 'hex');
  v_cached public.idempotency_records%rowtype;
  v_result jsonb;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if p_command_key is null then raise exception 'command_key_required' using errcode = '22023'; end if;
  if p_quantity <= 0 or p_unit_price <= 0 then raise exception 'invalid_listing' using errcode = '22023'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'create_market_listing' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;
  select id into v_character_id from public.characters where owner_id = v_actor for update;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  select * into v_inventory from public.inventories where character_id = v_character_id and item_id = p_item_id for update;
  if not found or v_inventory.quantity < p_quantity then raise exception 'insufficient_items' using errcode = '22023'; end if;
  update public.inventories set quantity = quantity - p_quantity, updated_at = statement_timestamp()
    where character_id = v_character_id and item_id = p_item_id;
  delete from public.inventories where character_id = v_character_id and item_id = p_item_id and quantity = 0;
  insert into public.market_listings (seller_character_id, item_id, quantity, unit_price)
  values (v_character_id, p_item_id, p_quantity, p_unit_price)
  returning id into v_listing_id;
  insert into public.item_transfers (item_id, from_character_id, quantity, reason, reference_id, command_key)
  values (p_item_id, v_character_id, p_quantity, 'market_listing_escrow', v_listing_id, p_command_key);
  v_result := jsonb_build_object('ok', true, 'listing_id', v_listing_id);
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'create_market_listing', v_hash, v_result);
  return v_result;
end;
$$;

create or replace function public.cancel_market_listing(p_listing_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_listing public.market_listings%rowtype;
  v_owner_id uuid;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  select * into v_listing from public.market_listings where id = p_listing_id for update;
  if not found or v_listing.status <> 'active' then raise exception 'listing_unavailable' using errcode = '22023'; end if;
  select owner_id into v_owner_id from public.characters where id = v_listing.seller_character_id;
  if v_owner_id <> v_actor then raise exception 'listing_forbidden' using errcode = '42501'; end if;
  update public.market_listings set status = 'cancelled', version = version + 1 where id = p_listing_id;
  insert into public.inventories (character_id, item_id, quantity)
  values (v_listing.seller_character_id, v_listing.item_id, v_listing.quantity)
  on conflict (character_id, item_id)
  do update set quantity = public.inventories.quantity + excluded.quantity, updated_at = statement_timestamp();
  insert into public.item_transfers (item_id, to_character_id, quantity, reason, reference_id)
  values (v_listing.item_id, v_listing.seller_character_id, v_listing.quantity, 'market_listing_cancelled', p_listing_id);
  return jsonb_build_object('ok', true);
end;
$$;

create or replace function public.purchase_market_listing(p_listing_id uuid, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_buyer_id uuid;
  v_buyer_owner uuid;
  v_listing public.market_listings%rowtype;
  v_buyer_balance bigint;
  v_seller_balance bigint;
  v_gross bigint;
  v_fee bigint;
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('listing_id', p_listing_id)::text, 'UTF8'), 'hex'), 'hex');
  v_cached public.idempotency_records%rowtype;
  v_result jsonb;
begin
  if v_actor is null or p_command_key is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'purchase_market_listing' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;
  select id into v_buyer_id from public.characters where owner_id = v_actor;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  select * into v_listing from public.market_listings where id = p_listing_id for update;
  if not found or v_listing.status <> 'active' or v_listing.expires_at <= statement_timestamp() then raise exception 'listing_unavailable' using errcode = '22023'; end if;
  if v_listing.seller_character_id = v_buyer_id then raise exception 'cannot_buy_own_listing' using errcode = '22023'; end if;
  select owner_id into v_buyer_owner from public.characters where id = v_listing.seller_character_id;
  if v_buyer_owner = v_actor then raise exception 'cannot_buy_own_listing' using errcode = '22023'; end if;
  v_gross := v_listing.unit_price * v_listing.quantity;
  v_fee := greatest(1, floor(v_gross * 0.05)::bigint);

  perform character_id from public.wallets
    where character_id in (v_buyer_id, v_listing.seller_character_id)
    order by character_id for update;
  select balance into v_buyer_balance from public.wallets where character_id = v_buyer_id;
  select balance into v_seller_balance from public.wallets where character_id = v_listing.seller_character_id;
  if v_buyer_balance < v_gross then raise exception 'insufficient_funds' using errcode = '22023'; end if;
  if v_seller_balance + v_gross - v_fee > 9000000000000 then raise exception 'wallet_capacity' using errcode = '22023'; end if;

  update public.wallets set balance = balance - v_gross, version = version + 1, updated_at = statement_timestamp()
  where character_id = v_buyer_id;
  update public.wallets set balance = balance + v_gross - v_fee, version = version + 1, updated_at = statement_timestamp()
  where character_id = v_listing.seller_character_id;
  insert into public.currency_ledger (character_id, delta, balance_after, reason, reference_id)
  values (v_buyer_id, -v_gross, v_buyer_balance - v_gross, 'market_purchase', p_listing_id),
         (v_listing.seller_character_id, v_gross - v_fee, v_seller_balance + v_gross - v_fee, 'market_sale', p_listing_id);
  update public.market_listings set status = 'sold', version = version + 1 where id = p_listing_id;
  insert into public.market_transactions (listing_id, buyer_character_id, seller_character_id, quantity, gross_amount, fee_amount)
  values (p_listing_id, v_buyer_id, v_listing.seller_character_id, v_listing.quantity, v_gross, v_fee);
  insert into public.inventories (character_id, item_id, quantity)
  values (v_buyer_id, v_listing.item_id, v_listing.quantity)
  on conflict (character_id, item_id)
  do update set quantity = public.inventories.quantity + excluded.quantity, updated_at = statement_timestamp();
  insert into public.item_transfers (item_id, from_character_id, to_character_id, quantity, reason, reference_id)
  values (v_listing.item_id, v_listing.seller_character_id, v_buyer_id, v_listing.quantity, 'market_purchase', p_listing_id);
  insert into public.outbox_events (owner_id, topic, payload)
  select owner_id, 'market.listing_sold', jsonb_build_object('listing_id', p_listing_id)
  from public.characters where id = v_listing.seller_character_id;
  v_result := jsonb_build_object('ok', true, 'listing_id', p_listing_id, 'amount_paid', v_gross);
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'purchase_market_listing', v_hash, v_result);
  return v_result;
end;
$$;

create or replace function public.expire_market_listings(p_limit integer default 100)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_listing public.market_listings%rowtype;
  v_processed integer := 0;
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  for v_listing in
    select * from public.market_listings
    where status = 'active' and expires_at <= statement_timestamp()
    order by expires_at
    limit greatest(1, least(p_limit, 500))
    for update skip locked
  loop
    update public.market_listings set status = 'expired', version = version + 1 where id = v_listing.id;
    insert into public.inventories (character_id, item_id, quantity)
    values (v_listing.seller_character_id, v_listing.item_id, v_listing.quantity)
    on conflict (character_id, item_id)
    do update set quantity = public.inventories.quantity + excluded.quantity, updated_at = statement_timestamp();
    insert into public.item_transfers (item_id, to_character_id, quantity, reason, reference_id)
    values (v_listing.item_id, v_listing.seller_character_id, v_listing.quantity, 'market_listing_expired', v_listing.id);
    v_processed := v_processed + 1;
  end loop;
  return v_processed;
end;
$$;

create or replace function public.expire_pvp_challenges(p_limit integer default 100)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  with due as (
    select id from public.combat_sessions
    where status = 'pending' and expires_at <= statement_timestamp()
    order by expires_at, id
    limit greatest(1, least(p_limit, 500))
    for update skip locked
  )
  update public.combat_sessions s
  set status = 'expired', finished_at = statement_timestamp()
  from due where s.id = due.id;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

create or replace function public.request_pvp_challenge(p_target_character_id uuid, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_attacker_id uuid;
  v_attacker public.characters%rowtype;
  v_target public.characters%rowtype;
  v_session_id uuid;
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('target_character_id', p_target_character_id)::text, 'UTF8'), 'sha256'), 'hex');
  v_cached public.idempotency_records%rowtype;
  v_result jsonb;
begin
  if v_actor is null or p_command_key is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'request_pvp_challenge' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;

  select id into v_attacker_id from public.characters where owner_id = v_actor;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  if v_attacker_id = p_target_character_id then raise exception 'cannot_attack_self' using errcode = '22023'; end if;
  perform id from public.characters where id in (v_attacker_id, p_target_character_id) order by id for update;
  select * into v_attacker from public.characters where owner_id = v_actor;
  select * into v_target from public.characters where id = p_target_character_id;
  if not found then raise exception 'target_not_found' using errcode = 'P0002'; end if;
  if v_attacker.location_id <> v_target.location_id then raise exception 'wrong_location' using errcode = '22023'; end if;
  if v_attacker.faction_id is not null and v_attacker.faction_id = v_target.faction_id then raise exception 'cannot_attack_faction_mate' using errcode = '22023'; end if;
  if exists (
    select 1 from public.combat_sessions
    where status in ('pending', 'active')
      and least(attacker_character_id, defender_character_id) = least(v_attacker.id, v_target.id)
      and greatest(attacker_character_id, defender_character_id) = greatest(v_attacker.id, v_target.id)
  ) then raise exception 'combat_already_in_progress' using errcode = '22023'; end if;

  insert into public.combat_sessions (attacker_character_id, defender_character_id)
  values (v_attacker.id, v_target.id)
  returning id into v_session_id;
  v_result := jsonb_build_object('ok', true, 'session_id', v_session_id);
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'request_pvp_challenge', v_hash, v_result);
  insert into public.outbox_events (owner_id, topic, payload)
  values (v_target.owner_id, 'combat.challenge', jsonb_build_object('session_id', v_session_id));
  return v_result;
end;
$$;

create or replace function public.respond_pvp_challenge(p_session_id uuid, p_accept boolean)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_session public.combat_sessions%rowtype;
  v_character_id uuid;
  v_attacker_owner uuid;
begin
  if v_actor is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  if p_accept is null then raise exception 'invalid_challenge_response' using errcode = '22023'; end if;
  select id into v_character_id from public.characters where owner_id = v_actor;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  select * into v_session from public.combat_sessions where id = p_session_id for update;
  if not found or v_session.defender_character_id <> v_character_id then raise exception 'challenge_not_found' using errcode = 'P0002'; end if;
  if v_session.status <> 'pending' or v_session.expires_at <= statement_timestamp() then raise exception 'challenge_expired' using errcode = '22023'; end if;
  update public.combat_sessions set
    status = case when p_accept then 'active' else 'declined' end,
    finished_at = case when p_accept then null else statement_timestamp() end
  where id = p_session_id;
  select owner_id into v_attacker_owner from public.characters where id = v_session.attacker_character_id;
  insert into public.outbox_events (owner_id, topic, payload)
  values (v_attacker_owner, 'combat.challenge_response', jsonb_build_object('session_id', p_session_id, 'accepted', p_accept));
  return jsonb_build_object('ok', true, 'accepted', p_accept);
end;
$$;

create or replace function public.pvp_attack(p_target_character_id uuid, p_session_id uuid, p_command_key uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_actor uuid := auth.uid();
  v_attacker_id uuid;
  v_target_owner_id uuid;
  v_target public.characters%rowtype;
  v_attacker public.characters%rowtype;
  v_session public.combat_sessions%rowtype;
  v_a_stats public.character_stats%rowtype;
  v_d_stats public.character_stats%rowtype;
  v_a_energy public.regenerated_stat;
  v_a_nerve public.regenerated_stat;
  v_d_health public.regenerated_stat;
  v_damage integer;
  v_hash text := encode(extensions.digest(convert_to(jsonb_build_object('target_character_id', p_target_character_id, 'session_id', p_session_id)::text, 'UTF8'), 'sha256'), 'hex');
  v_cached public.idempotency_records%rowtype;
  v_result jsonb;
  v_won boolean;
begin
  if v_actor is null or p_command_key is null then raise exception 'authentication_required' using errcode = '28000'; end if;
  perform pg_advisory_xact_lock(hashtextextended(v_actor::text || p_command_key::text, 0));
  select * into v_cached from public.idempotency_records where actor_id = v_actor and command_key = p_command_key;
  if found then
    if v_cached.command_name <> 'pvp_attack' or v_cached.request_hash <> v_hash then raise exception 'idempotency_key_reused' using errcode = '22023'; end if;
    return v_cached.response;
  end if;

  select id into v_attacker_id from public.characters where owner_id = v_actor;
  if not found then raise exception 'character_not_found' using errcode = 'P0002'; end if;
  if v_attacker_id = p_target_character_id then raise exception 'cannot_attack_self' using errcode = '22023'; end if;
  perform id from public.characters where id in (v_attacker_id, p_target_character_id) order by id for update;
  select * into v_attacker from public.characters where id = v_attacker_id;
  select * into v_target from public.characters where id = p_target_character_id;
  if not found then raise exception 'target_not_found' using errcode = 'P0002'; end if;
  select * into v_session from public.combat_sessions where id = p_session_id for update;
  if not found or v_session.status <> 'active'
     or not (
       (v_session.attacker_character_id = v_attacker_id and v_session.defender_character_id = p_target_character_id)
       or (v_session.defender_character_id = v_attacker_id and v_session.attacker_character_id = p_target_character_id)
     ) then raise exception 'combat_not_active' using errcode = '22023'; end if;
  if v_attacker.location_id <> v_target.location_id then raise exception 'wrong_location' using errcode = '22023'; end if;
  if v_attacker.faction_id is not null and v_attacker.faction_id = v_target.faction_id then raise exception 'cannot_attack_faction_mate' using errcode = '22023'; end if;
  if v_attacker.last_pvp_at > statement_timestamp() - interval '30 seconds' then raise exception 'pvp_cooldown' using errcode = '22023'; end if;
  v_target_owner_id := v_target.owner_id;

  perform character_id from public.character_stats where character_id in (v_attacker.id, v_target.id) order by character_id for update;
  select * into v_a_stats from public.character_stats where character_id = v_attacker.id;
  select * into v_d_stats from public.character_stats where character_id = v_target.id;
  v_a_energy := public.regenerate_stat(v_a_stats.energy, v_a_stats.energy_capacity, v_a_stats.energy_updated_at, v_a_stats.energy_regen_seconds, statement_timestamp());
  v_a_nerve := public.regenerate_stat(v_a_stats.nerve, v_a_stats.nerve_capacity, v_a_stats.nerve_updated_at, v_a_stats.nerve_regen_seconds, statement_timestamp());
  v_d_health := public.regenerate_stat(v_d_stats.health, v_d_stats.health_capacity, v_d_stats.health_updated_at, v_d_stats.health_regen_seconds, statement_timestamp());
  if v_a_energy.value < 10 or v_a_nerve.value < 2 then raise exception 'insufficient_resources' using errcode = '22023'; end if;
  if v_d_health.value <= 0 then raise exception 'target_defeated' using errcode = '22023'; end if;

  v_damage := 8 + floor(random() * 9)::integer;
  v_won := v_d_health.value <= v_damage;
  update public.character_stats set
    energy = v_a_energy.value - 10,
    energy_updated_at = case when v_a_energy.value = energy_capacity then statement_timestamp() else v_a_energy.updated_at end,
    nerve = v_a_nerve.value - 2,
    nerve_updated_at = case when v_a_nerve.value = nerve_capacity then statement_timestamp() else v_a_nerve.updated_at end,
    version = version + 1 where character_id = v_attacker.id;
  update public.character_stats set
    health = greatest(0, v_d_health.value - v_damage),
    health_updated_at = case when v_d_health.value = health_capacity then statement_timestamp() else v_d_health.updated_at end,
    version = version + 1 where character_id = v_target.id;
  update public.characters set last_pvp_at = statement_timestamp(), version = version + 1 where id = v_attacker.id;
  update public.combat_sessions set
    status = case when v_won then 'finished' else 'active' end,
    winner_character_id = case when v_won then v_attacker.id else null end,
    finished_at = case when v_won then statement_timestamp() else null end
  where id = p_session_id;
  insert into public.combat_actions (session_id, actor_character_id, action_type, damage, details)
  values (p_session_id, v_attacker.id, 'strike', v_damage, jsonb_build_object('target_character_id', v_target.id));

  v_result := jsonb_build_object(
    'ok', true, 'session_id', p_session_id, 'damage', v_damage,
    'target_health', greatest(0, v_d_health.value - v_damage), 'finished', v_won
  );
  insert into public.idempotency_records (actor_id, command_key, command_name, request_hash, response)
  values (v_actor, p_command_key, 'pvp_attack', v_hash, v_result);
  insert into public.outbox_events (owner_id, topic, payload)
  values
    (v_actor, 'combat.action', jsonb_build_object('session_id', p_session_id, 'damage', v_damage, 'as', 'attacker')),
    (v_target_owner_id, 'combat.action', jsonb_build_object('session_id', p_session_id, 'damage', v_damage, 'as', 'defender'));
  return v_result;
end;
$$;

create or replace function public.claim_due_jobs(p_limit integer default 50)
returns setof public.game_jobs
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  return query
  with due as (
    select id from public.game_jobs
    where run_at <= statement_timestamp()
      and attempts < 8
      and (status = 'pending' or (status = 'claimed' and lease_until < statement_timestamp()))
    order by run_at, id
    limit greatest(1, least(p_limit, 100))
    for update skip locked
  )
  update public.game_jobs j
  set status = 'claimed', lease_until = statement_timestamp() + interval '2 minutes', attempts = attempts + 1
  from due where j.id = due.id
  returning j.*;
end;
$$;

create or replace function public.claim_outbox_events(p_limit integer default 100)
returns setof public.outbox_events
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  return query
  with due as (
    select id from public.outbox_events
    where delivered_at is null and failed_at is null and attempts < 12
    and (claimed_until is null or claimed_until < statement_timestamp())
    order by id limit greatest(1, least(p_limit, 200))
    for update skip locked
  )
  update public.outbox_events e
  set claimed_until = statement_timestamp() + interval '2 minutes', attempts = attempts + 1
  from due where e.id = due.id
  returning e.*;
end;
$$;

create or replace function public.complete_outbox_event(p_event_id bigint)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  update public.outbox_events set delivered_at = statement_timestamp(), claimed_until = null
  where id = p_event_id and delivered_at is null;
end;
$$;

create or replace function public.fail_outbox_event(p_event_id bigint, p_error text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  update public.outbox_events set
    claimed_until = case when attempts >= 12 then null else statement_timestamp() + make_interval(secs => least(3600, 30 * power(2, least(attempts, 6))::integer)) end,
    last_error = left(p_error, 1000),
    failed_at = case when attempts >= 12 then statement_timestamp() else null end
  where id = p_event_id and delivered_at is null;
end;
$$;

create or replace function public.complete_game_job(p_job_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  update public.game_jobs set status = 'done', lease_until = null, last_error = null
  where id = p_job_id and status = 'claimed';
end;
$$;

create or replace function public.fail_game_job(p_job_id uuid, p_error text)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.role() <> 'service_role' then raise exception 'service_role_required' using errcode = '42501'; end if;
  update public.game_jobs set
    status = case when attempts >= 8 then 'dead' else 'pending' end,
    run_at = statement_timestamp() + make_interval(secs => least(3600, 30 * power(2, least(attempts, 6))::integer)),
    lease_until = null,
    last_error = left(p_error, 1000)
  where id = p_job_id and status = 'claimed';
end;
$$;

create or replace function public.can_read_faction(p_faction_id uuid)
returns boolean
language sql stable security definer set search_path = ''
as $$
  select exists (
    select 1 from public.faction_memberships m
    join public.characters c on c.id = m.character_id
    where m.faction_id = p_faction_id and c.owner_id = auth.uid()
  );
$$;

alter table public.profiles enable row level security;
alter table public.locations enable row level security;
alter table public.characters enable row level security;
alter table public.character_stats enable row level security;
alter table public.item_definitions enable row level security;
alter table public.inventories enable row level security;
alter table public.item_transfers enable row level security;
alter table public.activities enable row level security;
alter table public.wallets enable row level security;
alter table public.currency_ledger enable row level security;
alter table public.idempotency_records enable row level security;
alter table public.outbox_events enable row level security;
alter table public.game_jobs enable row level security;
alter table public.factions enable row level security;
alter table public.faction_memberships enable row level security;
alter table public.faction_events enable row level security;
alter table public.chat_channels enable row level security;
alter table public.chat_messages enable row level security;
alter table public.chat_reports enable row level security;
alter table public.market_listings enable row level security;
alter table public.market_transactions enable row level security;
alter table public.combat_sessions enable row level security;
alter table public.combat_actions enable row level security;

create policy "Profiles are publicly readable" on public.profiles for select to authenticated using (true);
create policy "Users update their own profile" on public.profiles for update to authenticated using (id = auth.uid()) with check (id = auth.uid());
create policy "Locations are readable" on public.locations for select to authenticated using (true);
create policy "Characters are publicly readable" on public.characters for select to authenticated using (true);
create policy "Character stats are private" on public.character_stats for select to authenticated using (exists (select 1 from public.characters c where c.id = character_id and c.owner_id = auth.uid()));
create policy "Item definitions are readable" on public.item_definitions for select to authenticated using (true);
create policy "Own inventory is readable" on public.inventories for select to authenticated using (exists (select 1 from public.characters c where c.id = character_id and c.owner_id = auth.uid()));
create policy "Own item transfers are readable" on public.item_transfers for select to authenticated using (
  exists (
    select 1 from public.characters c
    where c.id in (from_character_id, to_character_id) and c.owner_id = auth.uid()
  )
);
create policy "Activities are readable" on public.activities for select to authenticated using (enabled);
create policy "Own wallet is readable" on public.wallets for select to authenticated using (exists (select 1 from public.characters c where c.id = character_id and c.owner_id = auth.uid()));
create policy "Own ledger is readable" on public.currency_ledger for select to authenticated using (exists (select 1 from public.characters c where c.id = character_id and c.owner_id = auth.uid()));
create policy "Factions are readable" on public.factions for select to authenticated using (true);
create policy "Own or fellow memberships are readable" on public.faction_memberships for select to authenticated using (public.can_read_faction(faction_id) or exists (select 1 from public.characters c where c.id = character_id and c.owner_id = auth.uid()));
create policy "Faction events are member readable" on public.faction_events for select to authenticated using (public.can_read_faction(faction_id));
create policy "Authorized chat channels are readable" on public.chat_channels for select to authenticated using (kind = 'city' or public.can_read_faction(faction_id));
create policy "Channel messages are member readable" on public.chat_messages for select to authenticated using (
  (deleted_at is null and public.can_read_chat_channel(channel_id))
  or exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_moderator)
);
create policy "Moderators review reports" on public.chat_reports for select to authenticated using (exists (select 1 from public.profiles p where p.id = auth.uid() and p.is_moderator));
create policy "Active market listings are readable" on public.market_listings for select to authenticated using (status = 'active' or exists (select 1 from public.characters c where c.id = seller_character_id and c.owner_id = auth.uid()));
create policy "Own market transactions are readable" on public.market_transactions for select to authenticated using (
  exists (select 1 from public.characters c where c.id = buyer_character_id and c.owner_id = auth.uid())
  or exists (select 1 from public.characters c where c.id = seller_character_id and c.owner_id = auth.uid())
);
create policy "Combatants read their sessions" on public.combat_sessions for select to authenticated using (
  exists (select 1 from public.characters c where c.id in (attacker_character_id, defender_character_id) and c.owner_id = auth.uid())
);
create policy "Combatants read their actions" on public.combat_actions for select to authenticated using (
  exists (select 1 from public.combat_sessions s join public.characters c on c.id in (s.attacker_character_id, s.defender_character_id) where s.id = session_id and c.owner_id = auth.uid())
);

revoke all on all tables in schema public from anon, authenticated;
grant select on public.profiles, public.locations, public.characters, public.character_stats,
  public.item_definitions, public.inventories, public.activities, public.wallets,
  public.item_transfers,
  public.currency_ledger, public.factions, public.faction_memberships, public.faction_events,
  public.chat_channels, public.chat_messages, public.chat_reports, public.market_listings, public.market_transactions,
  public.combat_sessions, public.combat_actions to authenticated;
grant update (display_name, locale) on public.profiles to authenticated;

revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.my_game_state() from public, anon;
revoke all on function public.perform_activity(text, uuid) from public, anon;
revoke all on function public.use_item(text, uuid) from public, anon;
revoke all on function public.move_character(text, uuid) from public, anon;
revoke all on function public.create_faction(text, text, text, uuid) from public, anon;
revoke all on function public.join_faction(uuid) from public, anon;
revoke all on function public.leave_faction() from public, anon;
revoke all on function public.transfer_faction_leadership(uuid) from public, anon;
revoke all on function public.send_chat_message(uuid, text) from public, anon;
revoke all on function public.report_chat_message(bigint, text) from public, anon;
revoke all on function public.moderate_chat_message(bigint, text) from public, anon;
revoke all on function public.create_market_listing(text, integer, bigint, uuid) from public, anon;
revoke all on function public.cancel_market_listing(uuid) from public, anon;
revoke all on function public.purchase_market_listing(uuid, uuid) from public, anon;
revoke all on function public.request_pvp_challenge(uuid, uuid) from public, anon;
revoke all on function public.respond_pvp_challenge(uuid, boolean) from public, anon;
revoke all on function public.pvp_attack(uuid, uuid, uuid) from public, anon;
revoke all on function public.expire_market_listings(integer) from public, anon, authenticated;
revoke all on function public.expire_pvp_challenges(integer) from public, anon, authenticated;
revoke all on function public.claim_due_jobs(integer) from public, anon, authenticated;
revoke all on function public.claim_outbox_events(integer) from public, anon, authenticated;
revoke all on function public.complete_outbox_event(bigint) from public, anon, authenticated;
revoke all on function public.fail_outbox_event(bigint, text) from public, anon, authenticated;
revoke all on function public.complete_game_job(uuid) from public, anon, authenticated;
revoke all on function public.fail_game_job(uuid, text) from public, anon, authenticated;
revoke all on function public.can_read_faction(uuid) from public, anon;
revoke all on function public.can_read_chat_channel(uuid) from public, anon;

grant execute on function public.my_game_state() to authenticated;
grant execute on function public.perform_activity(text, uuid) to authenticated;
grant execute on function public.use_item(text, uuid) to authenticated;
grant execute on function public.move_character(text, uuid) to authenticated;
grant execute on function public.create_faction(text, text, text, uuid) to authenticated;
grant execute on function public.join_faction(uuid) to authenticated;
grant execute on function public.leave_faction() to authenticated;
grant execute on function public.transfer_faction_leadership(uuid) to authenticated;
grant execute on function public.send_chat_message(uuid, text) to authenticated;
grant execute on function public.report_chat_message(bigint, text) to authenticated;
grant execute on function public.moderate_chat_message(bigint, text) to authenticated;
grant execute on function public.create_market_listing(text, integer, bigint, uuid) to authenticated;
grant execute on function public.cancel_market_listing(uuid) to authenticated;
grant execute on function public.purchase_market_listing(uuid, uuid) to authenticated;
grant execute on function public.request_pvp_challenge(uuid, uuid) to authenticated;
grant execute on function public.respond_pvp_challenge(uuid, boolean) to authenticated;
grant execute on function public.pvp_attack(uuid, uuid, uuid) to authenticated;
grant execute on function public.expire_market_listings(integer) to service_role;
grant execute on function public.expire_pvp_challenges(integer) to service_role;
grant execute on function public.claim_due_jobs(integer) to service_role;
grant execute on function public.claim_outbox_events(integer) to service_role;
grant execute on function public.complete_outbox_event(bigint) to service_role;
grant execute on function public.fail_outbox_event(bigint, text) to service_role;
grant execute on function public.complete_game_job(uuid) to service_role;
grant execute on function public.fail_game_job(uuid, text) to service_role;
grant execute on function public.can_read_faction(uuid) to authenticated;
grant execute on function public.can_read_chat_channel(uuid) to authenticated;

alter publication supabase_realtime add table public.chat_messages;

create policy "Users receive private outbox broadcasts"
  on realtime.messages for select to authenticated
  using (
    extension = 'broadcast'
    and realtime.topic() = 'user:' || auth.uid()::text
  );
