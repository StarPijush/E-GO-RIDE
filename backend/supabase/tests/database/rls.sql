begin;
select plan(14);

insert into auth.users (id, aud, role, email, created_at, updated_at)
values
  ('00000000-0000-4000-8000-000000000001', 'authenticated', 'authenticated', 'stage0-a@example.invalid', now(), now()),
  ('00000000-0000-4000-8000-000000000002', 'authenticated', 'authenticated', 'stage0-b@example.invalid', now(), now()),
  ('00000000-0000-4000-8000-000000000003', 'authenticated', 'authenticated', 'stage0-c@example.invalid', now(), now());

insert into public.service_areas (name, center, radius_m, active)
values
  ('test-active', extensions.st_point(86.98, 22.45)::extensions.geography, 1000, true),
  ('test-inactive', extensions.st_point(86.98, 22.45)::extensions.geography, 1000, false);

insert into public.drivers (user_id)
values ('00000000-0000-4000-8000-000000000002');
insert into public.vehicles (driver_id, registration_number, registration_normalized)
values ('00000000-0000-4000-8000-000000000002', 'WB-X-0001', 'WBX0001');
update public.profiles
set role = 'admin', admin_role = 'owner'
where id = '00000000-0000-4000-8000-000000000003';
insert into public.admin_audit_events (admin_user_id, action, entity_type, entity_id)
values ('00000000-0000-4000-8000-000000000003', 'stage0_fixture', 'test', '1');

set local role anon;
select throws_ok('select * from public.profiles', '42501', null, 'anonymous profile access is denied');
reset role;

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);

select is((select count(*)::integer from public.profiles), 1, 'profile reads are limited to the authenticated user');
select is((select count(*)::integer from public.passenger_profiles), 1, 'passenger settings read is self-scoped');
select is((select count(*)::integer from public.drivers), 0, 'passenger cannot read another user driver profile');
select is((select count(*)::integer from public.vehicles), 0, 'passenger cannot read another user vehicle');
select is((select count(*)::integer from public.service_areas), 1, 'only active service areas are visible');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000002', true);
select is((select count(*)::integer from public.drivers), 1, 'driver can read own driver profile');
select is((select count(*)::integer from public.vehicles), 1, 'driver can read own vehicle');
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000001', true);
select throws_ok(
  $$update public.profiles set role = 'admin' where id = auth.uid()$$,
  '42501', null, 'authenticated users cannot update their role'
);
select throws_ok(
  $$insert into public.outbox_events (topic, payload) values ('test', '{}'::jsonb)$$,
  '42501', null, 'authenticated users cannot write privileged outbox events'
);
select throws_ok('select * from public.trips', '42501', null, 'clients have no direct trip access');
select throws_ok('select * from public.driver_locations', '42501', null, 'clients have no broad live-location access');
select throws_ok('delete from public.cash_ledger', '42501', null, 'clients cannot mutate the cash ledger');

reset role;
set local role service_role;
select throws_ok(
  $$update public.admin_audit_events set action = 'tampered' where action = 'stage0_fixture'$$,
  '55000', null, 'even service_role cannot mutate append-only audit history'
);
reset role;

select * from finish();
rollback;
