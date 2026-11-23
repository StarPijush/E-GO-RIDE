# 07 — Architecture Audit

- **Date:** 2026-11-23
- **Scope:** Whole monorepo (`E-go`, `E-go-web`, `E-go-rider`, `E-go-admin`, `backend`, `packages`, `infrastructure`, `docs`, `toto-go-blueprint`)
- **Snapshot:** working tree at commit `bbe6aa1` plus uncommitted changes
- **Mode:** read-only static audit; no application, test, migration, or dependency was executed or changed
- **Decision basis:** owner-approved direction — Supabase backend, Flutter passenger + driver as canonical clients, blueprint normative over frontend drift, reports 07 and 13 first
- **Status:** architecture assessment for owner review; this report does not authorize implementation

## 1. Executive summary

The repository currently contains **two customer-facing demos and no backend**. The Flutter passenger app and the Next.js web app both implement substantial UI and local simulation, but neither has a server, a database, real authentication, real dispatch, or real location tracking. The driver app, admin console, backend, shared packages, and infrastructure directories are empty scaffolds.

The blueprint architecture is materially stronger than the code. It defines a server-authoritative Postgres system, an OTP-only auth model, a nearest-first dispatch ladder, fare quotes, idempotent booking, a cash ledger, append-only audit/event logs, and explicit failure recovery. That design is coherent enough to build against, but it is **not implemented**.

The central architectural defect is that both clients treat their own 16-state booking FSM as the source of truth. The blueprint requires a different server FSM, server-issued transitions, revisions, idempotency keys, and reconciliation after network ambiguity. The current clients cannot be connected to the target backend without redesigning the booking state boundary.

**Architecture verdict:** blueprint design is a reasonable MVP architecture; the repository is **not integration-ready**. It is ready to begin **Stage 0 (contract, schema, shared core, CI)** only after the owner freezes MVP scope and records the remaining platform decisions. It is not ready for a pilot.

## 2. Evidence and classification

| Label | Meaning |
|---|---|
| VERIFIED | Directly observed in the repository at the cited location |
| PARTIALLY VERIFIED | Some implementation exists, but a required part is absent or simulated |
| INFERRED | Conclusion follows from multiple observed facts, not a runtime test |
| MISSING | No implementation was found |
| CONFLICT | Two repository sources disagree |
| NOT TESTED | No execution, device, network, or database verification was performed |

This audit is static. It did not run `flutter test`, `flutter analyze`, `npm test`, `npm run verify`, a database, a device, or any external service. Test counts in this report are static counts of test declarations, not proof of passing behavior. No secret values are reproduced.

The blueprint is treated as normative because `EGO-AGENT-INSTRUCTIONS.md:33-34` says the blueprint wins over summaries and behavior not covered by it must be raised as a decision, not invented.

## 3. Current-state architecture

### 3.1 Repository map

| Area | Current state | Classification | Evidence |
|---|---|---|---|
| `E-go` | Flutter passenger demo; 148 Dart files; only a `web/` platform folder; 45 test files / 317 test declarations | PARTIALLY VERIFIED | directory inspection; `E-go/pubspec.yaml:12-16`; `E-go/lib/app/app.dart:34` |
| `E-go-web` | Next.js customer web demo; 241 TS/TSX files; mock repositories; 32 test files / 268 test declarations | PARTIALLY VERIFIED | `E-go-web/package.json:22-33`; `E-go-web/src/lib/repositories/index.ts:54-64` |
| `E-go-rider` | Only `.gitkeep` files under `lib/` and `test/` | MISSING | directory inspection |
| `E-go-admin` | Only `.gitkeep` files under `lib/app`, `lib/core`, `lib/features`, `lib/shared`, `test` | MISSING | directory inspection |
| `backend` | Only `.gitkeep` files under `migrations`, `src/api`, `src/common`, `src/modules`, `src/workers`, `tests` | MISSING | directory inspection |
| `packages` | Only `.gitkeep` under `e_go_core/lib/src` and `e_go_design_system/lib` | MISSING | directory inspection |
| `infrastructure` | Only `.gitkeep` under `ci-cd`, `database`, `docker`, `env-templates`, `monitoring` | MISSING | directory inspection |
| `docs` | Product, booking, web, and cleanup documents; some claims are stale | PARTIALLY VERIFIED | `docs/repository_cleanup/repository_inventory.md:8`; `docs/web/ego_web_audit_report.md:6` |
| `toto-go-blueprint` | Complete 00–22 design set | VERIFIED | file inventory |
| `rapido-analysis` | Competitive evidence, explicitly read-only and not reusable | VERIFIED | `EGO-AGENT-INSTRUCTIONS.md:15-18` |

The root README describes `E-go` as Flutter for Android, iOS, and Web (`README.md:11`), but the repository contains only `E-go/web/`; `E-go/android/` and `E-go/ios/` are absent. The same README says backend, packages, and infrastructure are “scaffolded” (`README.md:52-53`), but they contain only `.gitkeep` placeholders. These are documentation conflicts, not implementation evidence.

### 3.2 Flutter passenger app — as built

**Runtime shape**

```
Flutter widgets
    -> Provider ChangeNotifier (AppState)
        -> mock auth repository
        -> mock vehicle repository
        -> mock driver repository
        -> mock booking repository
        -> current-location service (always unavailable)
        -> composite route service -> public OSRM HTTP API
        -> shared_preferences (onboarding flag only)
```

`AppState` constructs mock repositories by default (`E-go/lib/app/app_state.dart:41-49`). It owns auth state, booking state, fare state, route state, selected driver, and current ride (`E-go/lib/app/app_state.dart:82-114`). This is a monolithic client controller, not a server-mirroring architecture.

**Booking state**

The client FSM has 16 states (`E-go/lib/core/booking_state.dart:5-22`) and a hard-coded transition table (`E-go/lib/core/booking_state.dart:25-87`). It includes UI-selection states (`selectingPickup`, `selectingVehicle`, `reviewingFare`), a local search state (`searchingDriver`), and post-trip UI states (`tripCompleted`, `awaitingRating`, `rated`).

It does not include the server’s `quote_pending`, `expired`, `not_found`, or actor-specific cancellation states. It also has no transition out of `tripInProgress` except `tripCompleted` (`E-go/lib/core/booking_state.dart:75`), while the blueprint permits confirmed cancellation during an in-progress trip (`toto-go-blueprint/20-STATE-MACHINE.md:31-33`).

**Booking and dispatch simulation**

`placeOrder()` creates a local ride record with a timestamp-derived ID, stores it in an in-memory list, and returns success without any network call (`E-go/lib/app/app_state.dart:643-698`; `E-go/lib/features/booking/data/booking_repository.dart:122-126`). `startDriverSearch()` waits, asks a mock repository for a hard-coded driver, updates the local record, and transitions the local FSM (`E-go/lib/app/app_state.dart:710-787`; `E-go/lib/features/booking/data/driver_repository.dart:34-69`).

This is a deterministic demo, not a dispatch implementation. It has no booking intent, idempotency key, server timeout, reconciling state, offer model, accept race, or server revision.

**Auth**

`AUTH_MODE` defaults to `mock` (`E-go/lib/core/config/auth_config.dart:10-13`). Mock auth is development-only and release builds throw if mock mode is used (`E-go/lib/features/auth/data/auth_repository_factory.dart:11-20`). The API mode throws `UnimplementedError` (`E-go/lib/features/auth/data/auth_repository_factory.dart:21-25`). Accounts and sessions are in memory; only onboarding completion is persisted (`E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:1-4`, `218-228`). The OTP is a fixed development constant and no SMS is sent (`E-go/lib/features/auth/data/services/mock_otp_service.dart:5-12`).

The app also implements a password login path (`E-go/lib/app/app_state.dart:271-293`; `E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:62-93`). The blueprint requires phone OTP with no password for passengers and drivers (`toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:12`; `toto-go-blueprint/10-AUTH-AND-SECURITY.md:3-6`). This is a direct architecture conflict.

**Location, maps, and routing**

There is no geolocation package. The default current-location service always returns “unavailable” and explicitly refuses to invent a coordinate (`E-go/lib/features/location/data/current_location_service.dart:1-5`, `64-69`). Routing uses the public `https://router.project-osrm.org` endpoint with no backend proxy or provider abstraction (`E-go/lib/features/routing/data/services/osrm_route_service.dart:12-18`, `38-43`). This is not a production location stack.

**Vehicle, fare, and payment drift**

The Flutter app offers Bike and Toto (`E-go/lib/core/mock_pricing.dart:9`; `E-go/lib/features/booking/data/vehicle_repository.dart:57-74`). It offers Cash and a selectable demo UPI option (`E-go/lib/features/booking/data/booking_repository.dart:9-11`; `E-go/lib/features/booking/presentation/place_order_screen.dart:148-170`; `E-go/lib/features/account/presentation/payment_methods_screen.dart:8-76`). It also contains a “Pick up now / Schedule for later” selector and time picker (`E-go/lib/features/location/presentation/widgets/pickup_timing_selector.dart:3-5`; `E-go/lib/features/location/presentation/location_selection_screen.dart:37-40`, `172-211`, `503-557`).

The scheduled time is local screen state and is not passed into `AppState` when continuing (`E-go/lib/features/location/presentation/location_selection_screen.dart:399-441`). The blueprint’s MVP is Toto-only, cash-only, and explicitly excludes scheduled rides and UPI (`toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:14-24`; `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:3-4`). These are scope conflicts, not merely missing features.

**Localization and platform**

The app supports only `Locale('en', 'US')` (`E-go/lib/app/app.dart:34`). The Bengali selector changes local screen text only and is not connected to localization (`E-go/lib/features/account/presentation/settings_screen.dart:17`, `22-63`). The blueprint requires Bengali-first UI and ARB-based localization (`toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:29-30`; `toto-go-blueprint/04-MOBILE-APP-ARCHITECTURE.md:47-48`).

The absence of `android/` and `ios/` means the Flutter app currently has no mobile build target despite the product being Android-first (`toto-go-blueprint/02-SYSTEM-CONTEXT-AND-ASSUMPTIONS.md:17-19`).

### 3.3 Next.js web app — as built

**Runtime shape**

```
Next.js App Router screens
    -> Zustand stores (auth, booking, preferences)
        -> getRepositories()
            -> mock auth / rides / places / payments / notifications
                -> localStorage mock DB (`ego:db:v1`)
                -> deterministic simulation timers
```

The repository factory returns mock adapters for every data domain (`E-go-web/src/lib/repositories/index.ts:54-64`). HTTP adapters exist as stubs that return `NOT_IMPLEMENTED_ERROR` (`E-go-web/src/lib/repositories/http/auth-repository.ts:18-23`). The mock DB is a versioned `localStorage` payload (`E-go-web/src/lib/mock/db.ts:4-10`, `147-165`). Auth sessions are persisted in browser storage (`E-go-web/src/stores/auth-store.ts:8-10`, `263-273`).

**Domain and lifecycle**

The web FSM is explicitly a line-for-line port of the Flutter FSM (`E-go-web/src/lib/domain/booking-fsm.ts:1-13`; `E-go-web/src/lib/domain/types.ts:18-40`). It therefore inherits the same mismatch with the server FSM. The ride orchestrator is a clean, pure simulation with absolute deadlines and refresh recovery (`E-go-web/src/lib/domain/ride-orchestrator.ts:1-10`, `149-242`), but it simulates state changes locally rather than mirroring server events.

**Auth and security posture**

Web auth is mock-only: accounts live in `localStorage`, OTPs live in memory, and there is no server session (`E-go-web/src/lib/mock/auth-mock.ts:1-18`, `250-340`). Passwords are stored as PBKDF2-SHA-256 verifiers with 10,000 iterations (`E-go-web/src/lib/mock/auth-mock.ts:51-52`, `125-159`). Demo auth is disabled in production (`E-go-web/src/lib/config/env.ts:66-71`), and the web README correctly describes the app as a demo (`E-go-web/README.md:7-8`, `127-139`).

However, plaintext demo credentials are committed in `.env.example` and printed in both READMEs (`E-go-web/.env.example:19-23`; `E-go-web/README.md:31-43`; `E-go/README.md:5-8`). They are demo values, but they are still credentials and must not be treated as production secrets or copied into deployment environments. The 10,000-iteration PBKDF2 work factor is also demo-grade, not a production password policy.

**Vehicle, payment, and scope drift**

The web app also offers Bike and Toto (`E-go-web/src/lib/domain/types.ts:14-16`). Its payment enum includes `cash`, `upi`, `card`, and `wallet` (`E-go-web/src/lib/domain/types.ts:45-47`), but the payment screen only allows cash and marks UPI “Coming soon” (`E-go-web/src/components/account/payment-methods-screen.tsx:19-24`, `91-107`). This is less severe than the Flutter UPI path, but the domain still carries non-MVP payment concepts.

The web app is a **customer demo**, not an admin console. The root README calls it a customer web portal (`README.md:12`), and its routes and screens are passenger-facing. Any plan to reuse it as the operations console requires a separate re-scope and design.

### 3.4 What is actually missing

- No backend service, API implementation, database schema, migration, seed, worker, or queue.
- No driver application or admin console implementation.
- No shared Dart package or design-system package implementation.
- No real authentication, SMS, session, role, or RLS policy.
- No real dispatch, offers, fare quotes, accept race, or driver freshness.
- No realtime channel, push notification, or location ingestion.
- No server-side cash ledger, audit log, event log, or outbox.
- No CI/CD, deployment configuration, monitoring, backup, or environment separation.
- No Android or iOS build target for the Flutter app.
- No production map/route provider decision or implementation.

## 4. Target architecture

### 4.1 Decision context

The owner approved **Supabase** as the backend platform, resolving blueprint D1. The blueprint itself records Supabase as the recommendation, not a locked decision (`toto-go-blueprint/11-PLATFORM-INFRASTRUCTURE-AND-COSTS.md:4-14`; `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:9`). D2–D9 remain owner decisions and are listed in section 7.

The target is a **server-authoritative, contract-first MVP**:

```
Flutter passenger ─┐
Flutter driver ────┼── HTTPS + Realtime ── Supabase
Next.js admin ─────┘                         ├─ Auth (phone OTP)
                                             ├─ Postgres + PostGIS
                                             ├─ Edge Functions / RPC
                                             ├─ Realtime channels
                                             ├─ Storage (driver documents)
                                             └─ Cron / scheduled jobs
External: SMS gateway, FCM, OSM tiles, OSRM/route provider
```

Clients do not write ride state directly to tables. Trusted mutations go through Edge Functions or Postgres RPCs that validate the caller, the FSM edge, the revision, and the idempotency key. RLS protects reads and role scope; it is not a substitute for transition validation.

### 4.2 Component responsibilities

| Component | Responsibility | Target source |
|---|---|---|
| Flutter passenger | Booking, offers, tracking, history, rating, profile | blueprint 04; `E-go` UI reused |
| Flutter driver | Online/offline, offers, accept, start/complete, cash declaration, ledger | blueprint 04, 08, 09 |
| Next.js admin | Driver approval, live monitor, tickets, config, ledger, audit | blueprint 12; current web re-scope required |
| Supabase Auth | Phone OTP, access/refresh sessions, role claims | blueprint 10; Supabase recommendation |
| Postgres/PostGIS | Users, drivers, locations, requests, offers, quotes, trips, events, cash, audit, outbox | blueprint 05 |
| Edge Functions/RPC | Trusted booking, dispatch, transitions, cash, admin mutations | blueprint 06, 13 |
| Realtime | `trip:{id}`, `offers:{driver_id}`, request events | blueprint 05, 13, 20 |
| Scheduled jobs | Offer expiry, radius expansion, freshness, outbox retry, retention | blueprint 06, 07, 22 |
| Storage | License/vehicle/owner-proof documents, signed access | blueprint 05, 10 |
| FCM | Offer/state wake-up nudges, not sole truth | blueprint 20 |
| SMS gateway | OTP delivery and DLT compliance | blueprint 03, 10 |
| Map/route adapter | Map rendering, route preview, geocoding | blueprint 04, 11 |

### 4.3 Data ownership and trust boundaries

| Data | System of record | Client access | Rule |
|---|---|---|---|
| Auth identity and sessions | Supabase Auth | Tokens only | No client-side credential database |
| User/profile | Postgres | Own row via RLS | Admin reads only with role |
| Driver documents | Storage + Postgres metadata | Driver upload; admin approval | Signed URLs; no public bucket |
| Driver location | Postgres, written by trusted endpoint | Driver writes own; dispatch reads | Freshness-gated; no client-to-client tracking |
| Ride request/offers/quotes | Postgres | Read own request/offers | Server writes only |
| Trip state | Postgres + `ride_event_log` | Read own trip; realtime mirror | Server transitions only |
| Cash ledger | Postgres append-only | Driver/admin read; admin corrections | Completion does not imply collection |
| Audit/outbox | Postgres append-only | Admin read; worker processes | Same transaction as triggering write |
| App config | Postgres | Read-only via API | Server-controlled intervals/radii/flags |
| `active_trip` | Flutter local DB | Client cache | Derived from server; never authoritative |
| Web `localStorage` | Browser | Demo only | Must never be migrated as production truth |

The blueprint’s data model is the starting point: `users`, `passenger_profiles`, `drivers`, `driver_location`, `service_areas`, `ride_requests`, `ride_offers`, `trips`, `trip_points`, `ratings`, `support_tickets`, `app_config`, `otp_requests` (`toto-go-blueprint/05-DATA-MODEL.md:5-32`), plus the v2 entities `fare_quotes`, `booking_intents`, `ride_event_log`, `cash_ledger`, `admin_audit_events`, `outbox_events`, and `driver_sessions` (`toto-go-blueprint/05-DATA-MODEL.md:54-87`).

### 4.4 State-machine placement

The server FSM in `toto-go-blueprint/20-STATE-MACHINE.md:7-39` is the single authority. Its states are `quote_pending`, `driver_accepted`, `arriving`, `in_progress`, `completed`, `cancelled_passenger`, `cancelled_driver`, `cancelled_admin`, `expired`, and `not_found`.

Target client behavior:

- The passenger app mirrors the server state and adds only local UI states (`idle`, location selection, submitting, reconciling, rating).
- The driver app mirrors `offline`, `online_idle`, `offer_present`, `offer_submitted`, `accepted`, `arriving`, `in_progress`, `completed_pending_cash`, and `sanctioned_off` (`toto-go-blueprint/20-STATE-MACHINE.md:51-57`).
- Every transition is submitted as an intent and adopted only after the server response.
- `revision` protects against stale writes; `If-Match` mismatch returns `409` and forces a re-sync (`toto-go-blueprint/06-BACKEND-ARCHITECTURE.md:46-48`; `toto-go-blueprint/13-API-CONTRACTS.md:67-68`).
- Realtime is the primary event channel; polling is the fallback, with a server-configured minimum interval (`toto-go-blueprint/20-STATE-MACHINE.md:59-63`; `toto-go-blueprint/18-BOOKING-FAILURE-AND-RECOVERY-REQUIREMENTS.md:58`).

The existing 16-state FSM can remain useful as a **UI flow model**, but it must not be the server contract. The transition table should be split into UI navigation and server-mirror states rather than ported wholesale into the backend.

### 4.5 Booking and idempotency

Target booking flow:

1. Passenger confirms; client generates a UUIDv7 booking intent and persists it locally before the first request.
2. Client sends the intent as `X-Idempotency-Key`.
3. Server stores the intent and replays the first result for the same key.
4. Server creates a `ride_request` in `quote_pending` and starts the dispatch ladder.
5. Client timeout is at most 15 seconds; on ambiguity it enters `reconciling` and polls with the same intent, never silently re-books.
6. Driver acceptance is a compare-and-swap on the offer; exactly one driver wins.
7. Fare quotes are server-stamped, expiring artifacts; an expired quote returns `410` and requires explicit re-confirmation.
8. Trip transitions carry a revision and an idempotency key.

This is specified in `toto-go-blueprint/18-BOOKING-FAILURE-AND-RECOVERY-REQUIREMENTS.md:5-16`, `toto-go-blueprint/05-DATA-MODEL.md:59-69`, `toto-go-blueprint/07-MATCHING-AND-DISPATCH.md:49-53`, and `toto-go-blueprint/13-API-CONTRACTS.md:63-102`.

The current local order ID (`EGO-<milliseconds>`) and in-memory ride list do not satisfy this design (`E-go/lib/features/booking/data/booking_repository.dart:122-126`; `E-go/lib/app/app_state.dart:643-698`).

### 4.6 Dispatch

Target dispatch is a server-side nearest-first ladder:

- Base radius 1,500 m, step 750 m, maximum 6,000 m.
- Offer window 20 seconds; dispatch tick 2 seconds.
- Only approved, online, fresh drivers with no active trip and a matching vehicle are eligible.
- Each driver holds at most one pending offer.
- Timeout/decline expands the radius; exhaustion expires the request.
- Acceptance is transactional; the loser receives a clean race-lost result.
- Driver freshness is heartbeat-based, not a UI toggle.

Sources: `toto-go-blueprint/07-MATCHING-AND-DISPATCH.md:6-17`, `44-58`; `toto-go-blueprint/06-BACKEND-ARCHITECTURE.md:42-48`; `toto-go-blueprint/20-STATE-MACHINE.md:41-49`.

Supabase implementation shape: dispatch state is persisted in Postgres; request creation triggers the first attempt; a scheduled function or `pg_cron` tick handles expiry/expansion; Edge Functions/RPCs perform CAS accepts and write the outbox event in the same transaction. If a 2-second scheduled tick proves unreliable on the chosen Supabase plan, add one small always-on worker that uses the same Postgres database; do not introduce a microservice mesh.

### 4.7 Auth and sessions

Target auth is phone OTP only for passengers and drivers:

- 6-digit OTP, server-side rate limits, hashed codes, single use, attempt cap.
- Short-lived access token plus rotating refresh token.
- Tokens in platform secure storage, never `shared_preferences` or `localStorage`.
- Role claims for passenger, driver, and admin; admin uses a separate console login with password + TOTP.
- Server-side authorization on every mutation; no trust in client role or state.

Sources: `toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:12`; `toto-go-blueprint/10-AUTH-AND-SECURITY.md:3-15`, `32-42`; `toto-go-blueprint/13-API-CONTRACTS.md:5-10`, `73-74`.

Supabase Auth can provide phone OTP and sessions. The SMS provider/DLT route remains D3. If the provider cannot satisfy the required rate-limit/lockout behavior directly, wrap OTP issue/verify in an Edge Function while still using Supabase-issued sessions.

### 4.8 Cash ledger

The ledger, not the trip row, is authoritative:

- `fare_expected` is recorded from the accepted quote.
- Completion leaves `cash_status = pending`.
- Driver declares cash separately; declaration is idempotent.
- A declaration within 24 hours closes `collected`; later declaration opens a dispute.
- Admin corrections append ledger rows; history is never overwritten.
- Daily driver rollups are server-computed and cacheable offline.

Sources: `toto-go-blueprint/09-PAYMENTS-AND-CASH.md:25-34`; `toto-go-blueprint/05-DATA-MODEL.md:75-77`; `toto-go-blueprint/18-BOOKING-FAILURE-AND-RECOVERY-REQUIREMENTS.md:56`.

The current apps have no ledger; Flutter stores a payment enum on a local ride record (`E-go/lib/features/booking/data/booking_repository.dart:9-42`). That is display data, not accounting evidence.

### 4.9 Client packaging and shared core

Target structure:

```
E-go/                  Flutter passenger app (existing UI, new data layer)
E-go-rider/            Flutter driver app (currently empty)
packages/e_go_core/    models, API client, config, storage, geo, FSM mirror
packages/e_go_design_system/
E-go-admin/            Flutter or web admin (currently empty)
E-go-web/              demo / UX reference; candidate admin after re-scope
backend/               Supabase migrations, functions, tests
infrastructure/        CI, env templates, monitoring
```

The blueprint calls for two Flutter targets sharing a core package (`toto-go-blueprint/03-TECH-STACK.md:4-9`) and a layered feature structure (`toto-go-blueprint/04-MOBILE-APP-ARCHITECTURE.md:3-16`). The current Flutter app is a standalone monolith with no shared package. Extracting `e_go_core` is a prerequisite for the driver app, not a later cleanup.

### 4.10 Deployment, CI, and observability

Target deployment:

- Separate Supabase projects for dev/staging/prod; no shared production data.
- Versioned SQL migrations in `backend/migrations`; Edge Functions in `backend/src`; tests in `backend/tests`.
- CI in `infrastructure/ci-cd`: Flutter analyze/format/test; web lint/typecheck/test/build; SQL migration dry-run; contract tests; secret scan.
- Staging smoke flow: OTP → request → offer → accept → start → complete with cash → rating (`toto-go-blueprint/22-OPERATIONS-RUNBOOK.md:6`).
- Structured backend logs, Sentry/Crashlytics, `ride_event_log`, admin digest, backup/restore drill.
- Secrets only in server-side environment/vault; no service-role key in Flutter or browser code.

Sources: `toto-go-blueprint/03-TECH-STACK.md:21-27`; `toto-go-blueprint/21-IMPLEMENTATION-ROADMAP-AND-READINESS.md:5-20`, `33-49`; `toto-go-blueprint/10-AUTH-AND-SECURITY.md:44-49`.

### 4.11 Security zones

| Zone | Trust | Required controls |
|---|---|---|
| Flutter/browser clients | Untrusted | No service-role key; validate all inputs; secure token storage; no authoritative state |
| Edge Functions/RPC | Trusted | JWT/role validation; schema validation; FSM guard; idempotency; revision check |
| Postgres | Trusted | RLS for reads; constraints/partial indexes for invariants; append-only ledgers |
| Storage | Restricted | Private buckets, signed URLs, document retention |
| Admin console | High trust | Separate auth, TOTP, role split, atomic audit |
| SMS/FCM/map providers | External | Server-held keys; least-privilege; no PII beyond need |

The most important security rule is that **RLS alone is not enough** for ride state. A passenger must not be able to update `trips.state` directly. Trusted transitions must go through a function that locks the row, validates the current state, checks revision/idempotency, writes the event/outbox, and returns the new state.

## 5. Architecture gaps and risks

| ID | Severity | Gap | Evidence | Architectural consequence |
|---|---|---|---|---|
| ARCH-01 | P0 | No backend, API, database, or migrations | empty `backend/`; `E-go/lib/features/auth/data/auth_repository_factory.dart:21-25`; `E-go-web/src/lib/repositories/http/auth-repository.ts:18-23` | No server authority; no integration path today |
| ARCH-02 | P0 | Client FSM conflicts with canonical server FSM | `E-go/lib/core/booking_state.dart:5-87`; `E-go-web/src/lib/domain/booking-fsm.ts:1-38`; `toto-go-blueprint/20-STATE-MACHINE.md:7-39` | Cannot adopt server transitions without redesign |
| ARCH-03 | P0 | Auth model is incompatible | password path `E-go/lib/app/app_state.dart:271-293`; mock OTP `E-go/lib/features/auth/data/services/mock_otp_service.dart:5-12`; blueprint `10-AUTH-AND-SECURITY.md:3-6` | OTP-only, rate-limited server auth must replace mock/password auth |
| ARCH-04 | P0 | MVP scope drift | bike/toto `E-go/lib/core/mock_pricing.dart:9`; UPI `E-go/lib/features/booking/presentation/place_order_screen.dart:160-170`; schedule `E-go/lib/features/location/presentation/location_selection_screen.dart:37-40`; blueprint `01-PRODUCT-REQUIREMENTS.md:14-24` | Backend schema/UI must be frozen to Toto + cash + no scheduled rides |
| ARCH-05 | P0 | No mobile targets or geolocation | only `E-go/web/`; no `android/`/`ios/`; `E-go/lib/features/location/data/current_location_service.dart:1-5` | Cannot ship the Android-first product or track drivers |
| ARCH-06 | P0 | No realtime, push, or tracking | no FCM/foreground service in `E-go/pubspec.yaml:9-16`; no realtime in web | Dispatch and live ride UX cannot work |
| ARCH-07 | P0 | Mock persistence and demo auth are the only data layer | `E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:1-4`; `E-go-web/src/lib/mock/db.ts:4-10`; `E-go-web/src/stores/auth-store.ts:8-10` | No durable cross-device accounts, rides, or audit |
| ARCH-08 | P0 | No server-side security model | no RLS/migrations; demo credentials in `.env.example:19-23` and READMEs | No production authorization, rate limiting, or secret boundary |
| ARCH-09 | P0 | No CI, infrastructure, or observability | empty `infrastructure/`; no backend tests | Cannot verify migrations, contracts, or releases |
| ARCH-10 | P1 | Shared core is absent | empty `packages/`; standalone `E-go` | Driver/passenger duplication and inconsistent models |
| ARCH-11 | P1 | Map/route provider undecided; public OSRM used | `E-go/lib/features/routing/data/services/osrm_route_service.dart:14`; D2 open in `15-DECISIONS-AND-OPEN-QUESTIONS.md:10` | Routing availability, cost, and SLA are unowned |
| ARCH-12 | P1 | Documentation contradicts the tree | `README.md:11`, `25-35`, `52-53`; `docs/repository_cleanup/repository_inventory.md:8` | Reviewers and implementers can make wrong assumptions |

Severity is architecture impact, not a production incident rating. ARCH-01 through ARCH-09 block a real pilot; ARCH-10 through ARCH-12 block clean delivery and should be fixed in Stage 0.

## 6. Migration path

This is a recommended sequence, not an authorization to build. It follows the blueprint’s staged order (`toto-go-blueprint/21-IMPLEMENTATION-ROADMAP-AND-READINESS.md:5-20`).

### Stage 0 — freeze and scaffold

- Owner freezes MVP: Toto-only, cash-only, OTP-only, no scheduled rides, no UPI/wallet/card, Android first.
- Record D2–D9 decisions or explicit defaults.
- Create Supabase dev/staging projects.
- Implement the contract skeleton from blueprint 13 and the schema from blueprint 05.
- Extract `e_go_core` and decide the shared package boundary.
- Add CI, secret scanning, migration dry-run, and environment templates.
- Correct the root README and inventory claims.

**Exit:** contract and schema reviewed; CI green on an empty skeleton; no client calls a mock in staging.

### Stage 1 — auth and config

- Phone OTP, sessions, refresh, rate limits, lockout.
- Profiles and role claims.
- `app_config` endpoint with typed defaults.
- Secure token storage in Flutter.
- Replace mock auth and demo credentials in all non-demo builds.

**Exit:** V-1.1–V-1.3 and the relevant security checks pass on staging.

### Stage 2 — dispatch and trip lifecycle

- `ride_requests`, `ride_offers`, `fare_quotes`, `trips`.
- Dispatch ladder, freshness worker, offer CAS, expiry.
- Booking intent/idempotency and reconciling state.
- Trip transitions, pickup/drop codes, revisions, event log, outbox.
- Realtime channels and poll fallback.

**Exit:** booking-integrity, accept-race, stale-driver, and FSM tests pass.

### Stage 3 — cash, driver, admin

- Cash ledger and declarations.
- Driver app: online/offline, offers, accept, start/complete, cash.
- Admin: driver approval, live monitor, tickets, config, ledger, audit.
- FCM and foreground service.

**Exit:** end-to-end staging flow and audit trail pass.

### Stage 4 — replace demos and verify

- Point Flutter and web repositories at the real API.
- Remove production access to mock data and demo credentials.
- Add device tests, network-chaos tests, and browser/device E2E.
- Run the blueprint’s acceptance matrix and launch gates.

**Exit:** G-1..G-5 pass; no mock path remains in production builds.

## 7. Decisions still required

D1 is resolved to Supabase by owner approval. The following blueprint decisions remain open and affect architecture:

| ID | Decision | Current default / impact |
|---|---|---|
| D2 | Map and route provider | flutter_map + OSRM recommended; current public OSRM is not a production SLA |
| D3 | SMS gateway and DLT route | Required before real OTP; affects auth cost and delivery |
| D4 | Fare floors/caps | Affects fare validation and dispute policy |
| D5 | Cancel-before-arrival fee | Affects cancellation UX and ledger rules |
| D6 | iOS support | Default v2; no iOS target today |
| D7 | Static UPI QR | Default v1.1; MVP remains cash-only |
| D8 | Passenger max-fare preference | Default off |
| D9 | Play Store distribution | Default direct APK for pilot |

Source: `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:6-17`. D10–D15 have recorded design defaults in the blueprint, but they still require owner acceptance before pilot.

## 8. Architecture readiness assessment

| Dimension | Assessment | Rationale |
|---|---|---|
| Product/specification coherence | Strong | Blueprint has requirements, data model, API, FSM, failure requirements, tests, and ops |
| Client implementation | Prototype | Substantial UI and local simulation; no server integration |
| Server authority | Absent | No backend, DB, migrations, or trusted transitions |
| Data model implementation | Absent | Schema exists only on paper |
| Security architecture | Prototype | Good demo hygiene in web; no production auth/RLS |
| Operability | Absent | No CI, deployment, monitoring, backup, or runbook execution |
| Integration readiness | Not ready | Contract, schema, clients, and mocks are not aligned |
| Stage 0 readiness | Conditional | Can start after scope freeze and D2–D9 handling |

**Recommendation:** approve the target architecture and authorize **Stage 0 only**. Do not connect the current clients to a production backend, and do not treat either demo as a pilot artifact.

## 9. Key evidence index

| Topic | Evidence |
|---|---|
| MVP scope and non-goals | `toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:11-24` |
| Client stack and shared package | `toto-go-blueprint/03-TECH-STACK.md:4-9` |
| Data model | `toto-go-blueprint/05-DATA-MODEL.md:5-105` |
| Backend logical services and consistency | `toto-go-blueprint/06-BACKEND-ARCHITECTURE.md:3-54` |
| Dispatch ladder | `toto-go-blueprint/07-MATCHING-AND-DISPATCH.md:6-58` |
| Lifecycle and restore | `toto-go-blueprint/08-BOOKING-AND-RIDE-LIFECYCLE.md:3-35` |
| Cash ledger | `toto-go-blueprint/09-PAYMENTS-AND-CASH.md:25-34` |
| Auth and security | `toto-go-blueprint/10-AUTH-AND-SECURITY.md:3-49` |
| Supabase recommendation | `toto-go-blueprint/11-PLATFORM-INFRASTRUCTURE-AND-COSTS.md:4-14` |
| Admin scope | `toto-go-blueprint/12-OPERATIONS-AND-ADMIN.md:3-52` |
| API contracts | `toto-go-blueprint/13-API-CONTRACTS.md:5-110` |
| Decisions | `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:3-53` |
| Failure requirements | `toto-go-blueprint/18-BOOKING-FAILURE-AND-RECOVERY-REQUIREMENTS.md:5-69` |
| Acceptance tests and gates | `toto-go-blueprint/19-MVP-ACCEPTANCE-TESTS.md:5-99` |
| Canonical FSM | `toto-go-blueprint/20-STATE-MACHINE.md:7-99` |
| Build order and readiness | `toto-go-blueprint/21-IMPLEMENTATION-ROADMAP-AND-READINESS.md:5-49` |
| Flutter FSM | `E-go/lib/core/booking_state.dart:5-87` |
| Flutter mock auth | `E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:1-232` |
| Flutter mock booking | `E-go/lib/app/app_state.dart:643-787` |
| Web mock repositories | `E-go-web/src/lib/repositories/index.ts:54-64` |
| Web mock DB/auth | `E-go-web/src/lib/mock/db.ts:4-231`; `E-go-web/src/lib/mock/auth-mock.ts:1-463` |
| Web demo audit caveat | `docs/web/ego_web_audit_report.md:6-12` |

## 10. Audit limitations

- No code was executed; no test, build, lint, typecheck, database, or device result is claimed.
- No external service was contacted; no production endpoint was called.
- No backend, database, migration, or infrastructure exists to inspect.
- The working tree is dirty; line references reflect the working tree at the time of audit and may drift after edits.
- The existing web audit report claims engineering PASS, but its own text says independent audit sign-off is unavailable (`docs/web/ego_web_audit_report.md:6-12`). That claim was not independently reproduced here.
- Demo credential values are intentionally not reproduced in this report. Their presence in repository files is still a finding.
- This report does not resolve product policy, fare rules, provider selection, or owner decisions. It records them for decision.
