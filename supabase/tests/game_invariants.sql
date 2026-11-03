begin;

select plan(11);

select is(
  (public.regenerate_stat(4, 10, to_timestamp(0), 60, to_timestamp(149))).value,
  6,
  'stat regeneration adds completed intervals'
);

select is(
  (public.regenerate_stat(9, 10, to_timestamp(0), 60, to_timestamp(600))).updated_at,
  to_timestamp(600),
  'a capped stat does not bank regeneration time'
);

select throws_ok(
  $$ select public.regenerate_stat(11, 10, to_timestamp(0), 60, to_timestamp(600)) $$,
  '22023',
  'invalid_stat_state',
  'invalid stat state is rejected'
);

insert into auth.users (
  id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, email_change, email_change_token_new, recovery_token
) values
  (
    '00000000-0000-4000-8000-000000000101', 'authenticated', 'authenticated',
    'maya-test-one@example.invalid', 'test-only-password', now(),
    '{"provider":"email","providers":["email"]}', '{"display_name":"Asha"}',
    now(), now(), '', '', '', ''
  ),
  (
    '00000000-0000-4000-8000-000000000102', 'authenticated', 'authenticated',
    'maya-test-two@example.invalid', 'test-only-password', now(),
    '{"provider":"email","providers":["email"]}', '{"display_name":"Kabir"}',
    now(), now(), '', '', '', ''
  );

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);

select is(
  (select count(*)::integer from public.character_stats),
  1,
  'row-level security exposes only the signed-in traveller stats'
);

select is(
  public.perform_activity(
    'help-printmaker',
    '00000000-0000-4000-8000-000000000201'
  ),
  public.perform_activity(
    'help-printmaker',
    '00000000-0000-4000-8000-000000000201'
  ),
  'retrying an activity with the same idempotency key returns the same result'
);

select is(
  (select energy from public.character_stats),
  92,
  'replayed activity only consumes energy once'
);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
select is(
  (select count(*)::integer from public.character_stats),
  1,
  'row-level security isolates a second traveller'
);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
select is(
  public.request_pvp_challenge(
    (select id from public.characters where owner_id = '00000000-0000-4000-8000-000000000102'),
    '00000000-0000-4000-8000-000000000202'
  ),
  public.request_pvp_challenge(
    (select id from public.characters where owner_id = '00000000-0000-4000-8000-000000000102'),
    '00000000-0000-4000-8000-000000000202'
  ),
  'retrying a challenge request returns the same challenge'
);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000102', true);
select lives_ok(
  $$ select public.respond_pvp_challenge(
    (select id from public.combat_sessions where defender_character_id =
      (select id from public.characters where owner_id = '00000000-0000-4000-8000-000000000102')
      and status = 'pending'),
    true
  ) $$,
  'only the challenged player accepts the pending spar'
);

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);
select lives_ok(
  $$ select public.pvp_attack(
    (select id from public.characters where owner_id = '00000000-0000-4000-8000-000000000102'),
    (select id from public.combat_sessions where attacker_character_id =
      (select id from public.characters where owner_id = '00000000-0000-4000-8000-000000000101')
      and status = 'active'),
    '00000000-0000-4000-8000-000000000203'
  ) $$,
  'a turn is accepted only in the active challenge'
);

select is(
  (select count(*)::integer from public.combat_actions),
  1,
  'accepted spar records its server-resolved action'
);

select * from finish();
rollback;
