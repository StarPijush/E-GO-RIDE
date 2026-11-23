begin;
select plan(30);

select has_table('public', 'profiles', 'profiles exists');
select has_table('public', 'passenger_profiles', 'passenger profiles exist');
select has_table('public', 'service_areas', 'service areas exist');
select has_table('public', 'drivers', 'drivers exists');
select has_table('public', 'vehicles', 'vehicles exist');
select has_table('public', 'driver_sessions', 'driver sessions exist');
select has_table('public', 'driver_locations', 'spatial location table exists');
select has_table('public', 'ride_requests', 'booking request table exists');
select has_table('public', 'booking_intents', 'booking intents exist');
select has_table('public', 'fare_quotes', 'fare quote table exists');
select has_table('public', 'ride_offers', 'ride offers exist');
select has_table('public', 'trips', 'trip table exists');
select has_table('public', 'ride_event_log', 'ride event history exists');
select has_table('public', 'cash_ledger', 'cash ledger exists');
select has_table('public', 'idempotency_records', 'idempotency records exist');
select has_table('public', 'outbox_events', 'outbox exists');
select has_table('public', 'admin_audit_events', 'admin audit events exist');
select has_table('public', 'support_tickets', 'support tickets exist');
select has_fk('public', 'trips', 'trips_request_id_fkey', 'trip references a request');
select has_fk('public', 'trips', 'trips_driver_id_fkey', 'trip references a driver');
select has_index('public', 'driver_locations', 'driver_locations_location_gist', 'driver locations have a spatial GiST index');
select has_index('public', 'ride_offers', 'ride_offers_one_winner_per_request_idx', 'only one accepted offer can win per request');
select has_index('public', 'trips', 'trips_one_active_per_driver_idx', 'one active trip per driver is indexed');
select has_trigger('public', 'cash_ledger', 'cash_ledger_append_only', 'cash ledger has an append-only trigger');
select has_trigger('public', 'ride_event_log', 'ride_event_log_append_only', 'ride event history has an append-only trigger');
select has_trigger('public', 'admin_audit_events', 'admin_audit_append_only', 'admin audit history has an append-only trigger');
select ok(
  (select count(*) = 18 from pg_class c join pg_namespace n on n.oid = c.relnamespace where n.nspname = 'public' and c.relkind = 'r' and c.relrowsecurity),
  'RLS is enabled on every Stage 0 application table'
);
select ok(
  exists (select 1 from pg_constraint where conrelid = 'public.cash_ledger'::regclass and conname = 'cash_ledger_initial_amount_positive'),
  'cash ledger validates positive original entries'
);
select throws_ok(
  $$insert into public.service_areas (name, center, radius_m) values ('invalid-radius', extensions.st_point(86.98, 22.45)::extensions.geography, 0)$$,
  '23514', null, 'service area radius constraint rejects zero'
);
select ok(
  extensions.st_distance(
    extensions.st_point(0, 0)::extensions.geography,
    extensions.st_point(0, 0.001)::extensions.geography
  ) > 100,
  'PostGIS geography distance operation returns meters'
);

select * from finish();
rollback;
