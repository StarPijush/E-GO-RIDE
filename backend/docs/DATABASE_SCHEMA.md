# Database schema

Migration: `supabase/migrations/20261123000100_stage0_foundation.sql`. PostgreSQL timestamps use `timestamptz` (UTC instants); identifiers are UUID except monotonic event/outbox/audit sequence IDs. Coordinates use PostGIS `geography` in SRID 4326. Fare values are signed integer whole INR rupees where stored in the ledger; fare proposals and expected fares are positive integers. No floating-point monetary column exists.

## Tables and relationships

| Table | Purpose and required fields | Key relationships / constraints |
|---|---|---|
| `profiles` | E-GO account role, admin role, display name, locale, timestamps | PK/FK `id → auth.users`; default passenger; role/admin-role consistency; supported locale; trigger-created, never self-inserted |
| `passenger_profiles` | Saved places and contact preferences | PK/FK `user_id → profiles`; JSON arrays checked; self read/update only |
| `service_areas` | Active operating areas | UUID PK; required name, geography center, positive radius; optional geography multipolygon |
| `drivers` | Driver approval and freshness state | PK/FK to profile; FK service area and approving profile; approved records require approver/time |
| `vehicles` | Toto registration and verification document paths | FK driver and approver; unique normalized registration; only `toto`; approved records require approver/time |
| `driver_sessions` | Device session and heartbeat timestamps | FK driver; end time cannot precede start |
| `driver_locations` | Latest driver location | PK/FK driver; geography point, recorded/received UTC times; heading range and future-time guard |
| `ride_requests` | Passenger booking intent and pickup/drop snapshots | FK passenger; request state; checked JSON objects; one `quote_pending` request per passenger |
| `booking_intents` | Durable booking dedupe identity and result association | UUIDv7-compatible client intent ID PK; FK passenger/request/settled request/quote; unique passenger+key; one booked intent per quote |
| `fare_quotes` | Server-stamped driver proposal and expiry | FK request/driver; positive whole-rupee fare; valid expiry; consumption timestamp |
| `ride_offers` | Dispatch attempt and offer outcome | FK request/driver/quote; unique request+driver+attempt; at most one accepted offer per request |
| `trips` | Current authoritative ride row and revision | FK request (unique), quote, passenger, driver; trip state; revision; two code hashes; unique share-token hash with expiry/revocation; one active trip per driver |
| `ride_event_log` | Revisioned transition evidence | FK trip; unique trip+revision; JSON object payload; append-only trigger |
| `cash_ledger` | Expected, collected, or disputed cash entries | FK trip and optional self-FK `correction_of`; signed integer rupees; driver/admin actor; source and optional idempotency key; append-only trigger; initial rows positive, admin contra rows may be signed |
| `idempotency_records` | Replay result for future state-changing endpoints | FK actor; unique actor+operation+key; expiry after creation |
| `outbox_events` | Durable side-effect delivery queue | State, JSON payload, bounded attempts, dispatch timestamp consistency |
| `admin_audit_events` | Admin before/after audit record | FK actor; entity/action; append-only trigger |
| `support_tickets` | Trip-linked issue record | Optional trip/opening profile FKs; category/status/note checks; closure timestamp consistency |

## Indexes

- Spatial GiST: active service-area center, driver location, ride pickup.
- Dispatch: approved/fresh drivers by service area, pending offers by driver/expiry, requests by state/time.
- Lifecycle/history: trip by passenger or driver/state/recent time; event timeline by trip/revision.
- Reliability/ops: pending outbox, idempotency expiry, ledger by trip/time and kind/time, audit by entity or actor/time, ticket status/time.
- Uniqueness/guards: single open request per passenger, offer attempt, one accepted offer per request, one active trip per driver, one trip per request, one booked intent per quote, unique vehicle registration.

## RLS and grants

RLS is enabled on every public table. `authenticated` receives narrowly scoped self access for profiles, passenger settings, driver/vehicle self-read, and active service-area read. No client table privileges are granted for ride requests, offers, quotes, trips, locations, sessions, events, ledger, idempotency, outbox, audit, or tickets. Service-role access is for trusted server code only. Database constraints do not implement the state machine; trusted transaction-bound operations must enforce it.

The migration also creates the non-login `e_go_api` role with `NOINHERIT` and `NOBYPASSRLS`, and grants it membership in `authenticated`. Operators provision the separate login role without committing its password. `WithUserTx` in Go uses `SET LOCAL ROLE authenticated` and transaction-local claims derived from the verified JWT subject.

## Deferred entities/features

`trip_points` (raw point retention), ratings, full app configuration and OTP rate-limit rows are deferred. Supabase Auth owns OTP verification; the product must not persist plaintext OTPs. There is no fare policy table because D4 remains open and the Stage 0 schema does not enforce fare caps/floors. Driver live location ingestion and 90-day pruning are also deferred to the tracking feature stage.
