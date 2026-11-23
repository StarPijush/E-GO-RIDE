-- Stage 0 foundation. Business transitions and privileged writes are intentionally not exposed.
begin;

create schema if not exists extensions;
create extension if not exists postgis with schema extensions;

create type public.account_role as enum ('passenger', 'driver', 'admin');
create type public.admin_role as enum ('owner', 'helper', 'support_viewer');
create type public.driver_status as enum ('pending', 'approved', 'suspended', 'rejected');
create type public.driver_freshness as enum ('fresh', 'stale', 'offline');
create type public.vehicle_status as enum ('pending', 'approved', 'rejected', 'suspended');
create type public.ride_request_state as enum (
  'quote_pending', 'driver_accepted', 'expired', 'cancelled_passenger', 'superseded'
);
create type public.trip_state as enum (
  'driver_accepted', 'arriving', 'in_progress', 'completed',
  'cancelled_passenger', 'cancelled_driver', 'cancelled_admin'
);
create type public.ride_offer_state as enum ('pending', 'accepted', 'declined', 'timeout', 'retracted', 'lost_race');
create type public.booking_intent_state as enum ('new', 'booked', 'failed', 'superseded');
create type public.cash_status as enum ('pending', 'collected');
create type public.cash_entry_kind as enum ('fare_expected', 'fare_collected', 'fare_pending_dispute');
create type public.event_actor as enum ('driver', 'passenger', 'admin', 'system');
create type public.outbox_state as enum ('pending', 'dispatched', 'dead');

do $$
begin
  if not exists (select 1 from pg_catalog.pg_roles where rolname = 'e_go_api') then
    create role e_go_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
  else
    alter role e_go_api nologin noinherit nosuperuser nocreatedb nocreaterole noreplication nobypassrls;
  end if;
end
$$;
grant authenticated to e_go_api;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  role public.account_role not null default 'passenger',
  admin_role public.admin_role,
  display_name text,
  locale text not null default 'bn',
  created_at timestamptz not null default now(),
  last_seen_at timestamptz,
  constraint profiles_admin_role_consistent check ((role = 'admin') = (admin_role is not null)),
  constraint profiles_display_name_length check (display_name is null or char_length(display_name) between 1 and 100),
  constraint profiles_locale_supported check (locale in ('bn', 'en'))
);

create function public.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, role)
  values (new.id, 'passenger')
  on conflict (id) do nothing;
  insert into public.passenger_profiles (user_id)
  values (new.id)
  on conflict (user_id) do nothing;
  return new;
end;
$$;
revoke all on function public.create_profile_for_auth_user() from public, anon, authenticated;
create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.create_profile_for_auth_user();

create table public.passenger_profiles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  saved_places jsonb not null default '[]'::jsonb,
  home_place jsonb,
  work_place jsonb,
  notify_contacts jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default now(),
  constraint passenger_saved_places_array check (jsonb_typeof(saved_places) = 'array'),
  constraint passenger_notify_contacts_array check (jsonb_typeof(notify_contacts) = 'array')
);

create table public.service_areas (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  center extensions.geography(point, 4326) not null,
  radius_m integer not null check (radius_m > 0),
  boundary extensions.geography(multipolygon, 4326),
  active boolean not null default false,
  created_at timestamptz not null default now(),
  constraint service_area_name_length check (char_length(name) between 1 and 100)
);
create index service_areas_active_idx on public.service_areas (active) where active;
create index service_areas_center_gist on public.service_areas using gist (center);

create table public.drivers (
  user_id uuid primary key references public.profiles(id) on delete restrict,
  status public.driver_status not null default 'pending',
  freshness_state public.driver_freshness not null default 'offline',
  service_area_id uuid references public.service_areas(id) on delete restrict,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint driver_approval_fields check (status <> 'approved' or (approved_at is not null and approved_by is not null)),
  constraint driver_approval_area check (status <> 'approved' or service_area_id is not null)
);
create index drivers_dispatch_eligibility_idx on public.drivers (service_area_id, user_id)
  where status = 'approved' and freshness_state = 'fresh';

create table public.vehicles (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(user_id) on delete restrict,
  vehicle_type text not null default 'toto' check (vehicle_type = 'toto'),
  registration_number text not null,
  registration_normalized text not null,
  status public.vehicle_status not null default 'pending',
  license_document_path text,
  vehicle_photo_path text,
  owner_proof_path text,
  approved_at timestamptz,
  approved_by uuid references public.profiles(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint vehicle_registration_length check (char_length(registration_number) between 3 and 20),
  constraint vehicle_registration_unique unique (registration_normalized),
  constraint vehicle_approval_fields check (status <> 'approved' or (approved_at is not null and approved_by is not null))
);
create index vehicles_driver_status_idx on public.vehicles (driver_id, status);

create table public.driver_sessions (
  id uuid primary key default gen_random_uuid(),
  driver_id uuid not null references public.drivers(user_id) on delete restrict,
  device_id text not null,
  started_at timestamptz not null default now(),
  last_heartbeat_at timestamptz not null default now(),
  ended_at timestamptz,
  constraint driver_session_device_length check (char_length(device_id) between 1 and 200),
  constraint driver_session_end_order check (ended_at is null or ended_at >= started_at)
);
create index driver_sessions_live_heartbeat_idx on public.driver_sessions (last_heartbeat_at)
  where ended_at is null;
create index driver_sessions_driver_live_idx on public.driver_sessions (driver_id)
  where ended_at is null;

create table public.driver_locations (
  driver_id uuid primary key references public.drivers(user_id) on delete cascade,
  location extensions.geography(point, 4326) not null,
  heading_degrees real,
  recorded_at timestamptz not null,
  received_at timestamptz not null default now(),
  constraint driver_location_heading_range check (heading_degrees is null or heading_degrees >= 0 and heading_degrees < 360),
  constraint driver_location_not_future check (recorded_at <= received_at + interval '30 seconds')
);
create index driver_locations_location_gist on public.driver_locations using gist (location);
create index driver_locations_freshness_idx on public.driver_locations (received_at desc);

create table public.ride_requests (
  id uuid primary key default gen_random_uuid(),
  passenger_id uuid not null references public.profiles(id) on delete restrict,
  pickup_location extensions.geography(point, 4326) not null,
  pickup_label text not null,
  drop_location extensions.geography(point, 4326) not null,
  drop_label text not null,
  route_preview jsonb,
  requested_at timestamptz not null default now(),
  state public.ride_request_state not null default 'quote_pending',
  config_snapshot jsonb not null default '{}'::jsonb,
  constraint ride_request_labels check (char_length(pickup_label) between 1 and 200 and char_length(drop_label) between 1 and 200),
  constraint ride_request_minimum_distance check (extensions.st_distance(pickup_location, drop_location) >= 50),
  constraint ride_request_route_object check (route_preview is null or jsonb_typeof(route_preview) = 'object'),
  constraint ride_request_config_object check (jsonb_typeof(config_snapshot) = 'object')
);
create index ride_requests_passenger_recent_idx on public.ride_requests (passenger_id, requested_at desc);
create index ride_requests_state_time_idx on public.ride_requests (state, requested_at);
create unique index ride_requests_one_open_per_passenger_idx on public.ride_requests (passenger_id)
  where state = 'quote_pending';
create index ride_requests_pickup_gist on public.ride_requests using gist (pickup_location);

create table public.booking_intents (
  id uuid primary key,
  passenger_id uuid not null references public.profiles(id) on delete restrict,
  request_id uuid references public.ride_requests(id) on delete restrict,
  idempotency_key text not null,
  quote_id uuid,
  state public.booking_intent_state not null default 'new',
  created_at timestamptz not null default now(),
  settled_request_id uuid references public.ride_requests(id) on delete restrict,
  constraint booking_intent_key_unique unique (passenger_id, idempotency_key),
  constraint booking_intent_key_length check (char_length(idempotency_key) between 1 and 200),
  constraint booking_intent_settlement check ((state = 'booked') = (settled_request_id is not null))
);
create index booking_intents_passenger_recent_idx on public.booking_intents (passenger_id, created_at desc);
create unique index booking_intents_quote_consumed_once_idx on public.booking_intents (quote_id)
  where quote_id is not null and state = 'booked';

create table public.fare_quotes (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.ride_requests(id) on delete restrict,
  driver_id uuid not null references public.drivers(user_id) on delete restrict,
  fare_rupees integer not null check (fare_rupees > 0),
  valid_until timestamptz not null,
  displacement_threshold_m integer not null check (displacement_threshold_m >= 0),
  created_at timestamptz not null default now(),
  consumed_at timestamptz,
  constraint fare_quote_expiry check (valid_until > created_at),
  constraint fare_quote_consumption check (consumed_at is null or consumed_at >= created_at)
);
create index fare_quotes_request_recent_idx on public.fare_quotes (request_id, created_at desc);
create index fare_quotes_driver_recent_idx on public.fare_quotes (driver_id, created_at desc);
alter table public.booking_intents
  add constraint booking_intent_quote_fk foreign key (quote_id) references public.fare_quotes(id) on delete restrict;

create table public.ride_offers (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null references public.ride_requests(id) on delete restrict,
  driver_id uuid not null references public.drivers(user_id) on delete restrict,
  quote_id uuid references public.fare_quotes(id) on delete restrict,
  state public.ride_offer_state not null default 'pending',
  offered_at timestamptz not null default now(),
  expires_at timestamptz not null,
  attempt_no integer not null check (attempt_no > 0),
  constraint ride_offer_expiry check (expires_at > offered_at),
  constraint ride_offer_attempt_unique unique (request_id, driver_id, attempt_no)
);
create index ride_offers_request_state_idx on public.ride_offers (request_id, state);
create index ride_offers_driver_pending_idx on public.ride_offers (driver_id, expires_at) where state = 'pending';
create unique index ride_offers_one_winner_per_request_idx on public.ride_offers (request_id) where state = 'accepted';

create table public.trips (
  id uuid primary key default gen_random_uuid(),
  request_id uuid not null unique references public.ride_requests(id) on delete restrict,
  quote_id uuid not null references public.fare_quotes(id) on delete restrict,
  passenger_id uuid not null references public.profiles(id) on delete restrict,
  driver_id uuid not null references public.drivers(user_id) on delete restrict,
  fare_rupees integer not null check (fare_rupees > 0),
  pickup_location extensions.geography(point, 4326) not null,
  drop_location extensions.geography(point, 4326) not null,
  distance_m integer check (distance_m is null or distance_m > 0),
  pickup_code_hash text not null,
  drop_code_hash text,
  state public.trip_state not null default 'driver_accepted',
  revision integer not null default 0 check (revision >= 0),
  cash_status public.cash_status not null default 'pending',
  dispute_open boolean not null default false,
  started_at timestamptz,
  ended_at timestamptz,
  cancelled_by public.event_actor,
  cancel_reason text,
  share_token_hash text unique,
  share_token_expires_at timestamptz,
  share_token_revoked_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint trip_lifecycle_timestamps check (ended_at is null or started_at is null or ended_at >= started_at),
  constraint trip_terminal_time check ((state in ('completed', 'cancelled_passenger', 'cancelled_driver', 'cancelled_admin')) = (ended_at is not null)),
  constraint trip_cancel_actor check (
    (state not in ('cancelled_passenger', 'cancelled_driver', 'cancelled_admin')) or cancelled_by is not null
  ),
  constraint trip_cancel_actor_matches_state check (
    (state <> 'cancelled_passenger' or cancelled_by = 'passenger') and
    (state <> 'cancelled_driver' or cancelled_by = 'driver') and
    (state <> 'cancelled_admin' or cancelled_by = 'admin')
  ),
  constraint trip_share_expiry check ((share_token_hash is null) = (share_token_expires_at is null)),
  constraint trip_share_revocation check (share_token_revoked_at is null or share_token_hash is not null)
);
create index trips_passenger_state_recent_idx on public.trips (passenger_id, state, created_at desc);
create index trips_driver_state_recent_idx on public.trips (driver_id, state, created_at desc);
create unique index trips_one_active_per_driver_idx on public.trips (driver_id)
  where state in ('driver_accepted', 'arriving', 'in_progress');

create table public.ride_event_log (
  id bigint generated always as identity primary key,
  trip_id uuid not null references public.trips(id) on delete restrict,
  revision integer not null check (revision > 0),
  from_state public.trip_state,
  to_state public.trip_state not null,
  actor public.event_actor not null,
  at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb,
  constraint ride_event_payload_object check (jsonb_typeof(payload) = 'object'),
  constraint ride_event_revision_unique unique (trip_id, revision)
);
create index ride_event_log_trip_timeline_idx on public.ride_event_log (trip_id, revision);

create table public.cash_ledger (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid not null references public.trips(id) on delete restrict,
  kind public.cash_entry_kind not null,
  amount_rupees integer not null check (amount_rupees <> 0),
  declared_by public.event_actor not null check (declared_by in ('driver', 'admin')),
  declared_at timestamptz not null default now(),
  source text not null check (source in ('driver_app', 'admin_console', 'system')),
  idempotency_key text,
  correction_of uuid references public.cash_ledger(id) on delete restrict,
  created_at timestamptz not null default now(),
  constraint cash_ledger_idempotency_unique unique (trip_id, idempotency_key),
  constraint cash_ledger_correction_actor check (correction_of is null or declared_by = 'admin'),
  constraint cash_ledger_initial_amount_positive check (correction_of is not null or amount_rupees > 0)
);
create index cash_ledger_trip_time_idx on public.cash_ledger (trip_id, created_at);
create index cash_ledger_kind_time_idx on public.cash_ledger (kind, created_at desc);

create table public.idempotency_records (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid not null references public.profiles(id) on delete restrict,
  operation text not null,
  idempotency_key text not null,
  response_status integer,
  response_body jsonb,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null,
  constraint idempotency_operation_length check (char_length(operation) between 1 and 150),
  constraint idempotency_key_unique unique (actor_id, operation, idempotency_key),
  constraint idempotency_expiry check (expires_at > created_at)
);
create index idempotency_expiry_idx on public.idempotency_records (expires_at);

create table public.outbox_events (
  id bigint generated always as identity primary key,
  topic text not null,
  payload jsonb not null,
  state public.outbox_state not null default 'pending',
  created_at timestamptz not null default now(),
  dispatched_at timestamptz,
  attempts smallint not null default 0 check (attempts between 0 and 5),
  constraint outbox_payload_object check (jsonb_typeof(payload) = 'object'),
  constraint outbox_dispatch_state check ((state = 'dispatched') = (dispatched_at is not null))
);
create index outbox_pending_idx on public.outbox_events (created_at) where state = 'pending';

create table public.admin_audit_events (
  id bigint generated always as identity primary key,
  admin_user_id uuid not null references public.profiles(id) on delete restrict,
  action text not null,
  entity_type text not null,
  entity_id text not null,
  before jsonb,
  after jsonb,
  at timestamptz not null default now(),
  constraint admin_audit_action_length check (char_length(action) between 1 and 100),
  constraint admin_audit_entity_type_length check (char_length(entity_type) between 1 and 100)
);
create index admin_audit_entity_timeline_idx on public.admin_audit_events (entity_type, entity_id, at desc);
create index admin_audit_actor_timeline_idx on public.admin_audit_events (admin_user_id, at desc);

create table public.support_tickets (
  id uuid primary key default gen_random_uuid(),
  trip_id uuid references public.trips(id) on delete restrict,
  opened_by uuid references public.profiles(id) on delete set null,
  category text not null check (category in ('fare', 'driver', 'lost_item', 'other')),
  status text not null default 'open' check (status in ('open', 'closed')),
  note text not null,
  created_at timestamptz not null default now(),
  closed_at timestamptz,
  constraint support_ticket_note_length check (char_length(note) between 1 and 4000),
  constraint support_ticket_closed_at check ((status = 'closed') = (closed_at is not null))
);
create index support_tickets_status_recent_idx on public.support_tickets (status, created_at desc);
create index support_tickets_trip_idx on public.support_tickets (trip_id) where trip_id is not null;

create function public.reject_append_only_mutation()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  raise exception '% is append-only; write a compensating row instead', tg_table_name
    using errcode = '55000';
end;
$$;
revoke all on function public.reject_append_only_mutation() from public, anon, authenticated;
create trigger cash_ledger_append_only before update or delete on public.cash_ledger
  for each row execute function public.reject_append_only_mutation();
create trigger admin_audit_append_only before update or delete on public.admin_audit_events
  for each row execute function public.reject_append_only_mutation();
create trigger ride_event_log_append_only before update or delete on public.ride_event_log
  for each row execute function public.reject_append_only_mutation();

-- Revoke inherited/default API access. Only explicitly safe self-service reads/updates are granted.
revoke all on all tables in schema public from anon, authenticated;
revoke all on all sequences in schema public from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from public, anon, authenticated;
alter default privileges for role postgres in schema public grant all on tables to service_role;
alter default privileges for role postgres in schema public grant all on sequences to service_role;
grant select on public.profiles to authenticated;
grant update (display_name, locale) on public.profiles to authenticated;
grant select, update on public.passenger_profiles to authenticated;
grant select on public.drivers, public.vehicles to authenticated;
grant select on public.service_areas to authenticated;
grant usage on schema public, extensions to authenticated;

alter table public.profiles enable row level security;
alter table public.passenger_profiles enable row level security;
alter table public.service_areas enable row level security;
alter table public.drivers enable row level security;
alter table public.vehicles enable row level security;
alter table public.driver_sessions enable row level security;
alter table public.driver_locations enable row level security;
alter table public.ride_requests enable row level security;
alter table public.booking_intents enable row level security;
alter table public.fare_quotes enable row level security;
alter table public.ride_offers enable row level security;
alter table public.trips enable row level security;
alter table public.ride_event_log enable row level security;
alter table public.cash_ledger enable row level security;
alter table public.idempotency_records enable row level security;
alter table public.outbox_events enable row level security;
alter table public.admin_audit_events enable row level security;
alter table public.support_tickets enable row level security;

create policy profiles_read_self on public.profiles for select to authenticated using (id = (select auth.uid()));
create policy profiles_update_self on public.profiles for update to authenticated
  using (id = (select auth.uid())) with check (id = (select auth.uid()));
create policy passenger_profiles_read_self on public.passenger_profiles for select to authenticated
  using (user_id = (select auth.uid()));
create policy passenger_profiles_update_self on public.passenger_profiles for update to authenticated
  using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy drivers_read_self on public.drivers for select to authenticated
  using (user_id = (select auth.uid()));
create policy vehicles_read_self on public.vehicles for select to authenticated
  using (driver_id = (select auth.uid()));
create policy service_areas_read_active on public.service_areas for select to authenticated using (active);

-- All ride, offer, location, ledger, audit, and admin writes/reads are withheld from app roles
-- until trusted, transaction-bound API operations and the open staff matrix are approved.
grant all privileges on all tables in schema public to service_role;
grant usage, select on all sequences in schema public to service_role;

commit;
