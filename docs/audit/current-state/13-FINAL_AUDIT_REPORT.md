# 13 — Final Audit Report

- **Date:** 2026-11-23
- **Repository:** `D:\E-RICKSHAW RIDE`
- **Snapshot:** commit `bbe6aa1` plus uncommitted working-tree changes
- **Audit type:** read-only static architecture and readiness audit
- **Report status:** current final synthesis for owner review; not an implementation authorization
- **Companion report:** `docs/audit/current-state/07-ARCHITECTURE_AUDIT.md`

## 1. Final verdict

### NO-GO for pilot or production

The repository must not be used for real passengers, real drivers, real cash, app-store release, or a public pilot. It has no backend, database, driver app, admin console, real authentication, real dispatch, real location tracking, realtime channel, push notification, cash ledger, or production infrastructure.

### CONDITIONAL GO for Stage 0 and Stage 1

The owner can authorize the first backend stage after accepting the conditions in section 11. The blueprint is strong enough to build against, Supabase is approved, and the existing Flutter/web UI contains reusable work. The correct next step is to freeze MVP scope, create the Supabase schema and API contract, extract the shared Flutter core, and establish CI — not to connect the current demos to production.

### Bottom line

| Question | Answer |
|---|---|
| Is there a working end-to-end product? | No. There are two client demos with local simulation. |
| Is the target architecture defined? | Yes, in the blueprint, with Supabase approved by the owner. |
| Is the repository ready for integration? | No. Contract, schema, clients, and mocks do not align. |
| Can backend work start? | Conditionally, at Stage 0 only, after scope and decisions are frozen. |
| Can a pilot start? | No. P0 blockers remain. |
| Is the existing UI reusable? | Yes, with data-layer replacement and scope cleanup. |

The overall implementation score is **1.5 / 5 — prototype**. The design documentation scores substantially higher, approximately **4 / 5**, but documentation is not implementation.

## 2. Scope and method

### 2.1 Scope

Reviewed:

- `E-go` Flutter passenger app
- `E-go-web` Next.js web app
- `E-go-rider` driver scaffold
- `E-go-admin` admin scaffold
- `backend`, `packages`, and `infrastructure` scaffolds
- `toto-go-blueprint` documents 00–22
- `rapido-analysis` reference documents
- Root and project READMEs, architecture notes, web audit reports, and repository inventory

Not reviewed or executed:

- No backend, database, migration, or deployed environment exists to inspect
- No runtime, device, network, load, penetration, or accessibility test was performed
- No production service or third-party API was contacted
- No test suite was run

### 2.2 Evidence labels

| Label | Meaning |
|---|---|
| VERIFIED | Directly observed at the cited file and line |
| PARTIALLY VERIFIED | Some implementation exists; a required part is missing or simulated |
| INFERRED | Conclusion follows from multiple observed facts |
| MISSING | No implementation found |
| CONFLICT | Repository sources disagree |
| NOT TESTED | No runtime verification performed |

No secret values are reproduced in this report. Demo credentials are referenced by location only.

## 3. Repository state

### 3.1 What exists

| Area | State | Classification |
|---|---|---|
| Flutter passenger app | Substantial UI, local simulation, mock auth, only `web/` platform | PARTIALLY VERIFIED |
| Next.js web app | Substantial customer UI, local simulation, mock auth, mock repositories | PARTIALLY VERIFIED |
| Driver app | Empty scaffold | MISSING |
| Admin console | Empty scaffold | MISSING |
| Backend/API | Empty scaffold | MISSING |
| Database/migrations | Empty scaffold | MISSING |
| Shared Dart packages | Empty scaffold | MISSING |
| Infrastructure/CI | Empty scaffold | MISSING |
| Blueprint | Complete design set | VERIFIED |
| Rapido reference | Evidence only; not reusable code | VERIFIED |

### 3.2 Static inventory

| Measure | Value | Basis |
|---|---|---|
| Flutter `lib` files | 148 | file count |
| Flutter test files | 45 | file count |
| Flutter test declarations | 317 | static count |
| Web `src` files | 241 | file count |
| Web test files | 32 | file count |
| Web test declarations | 268 | static count |
| Flutter mobile targets | 0 | no `android/` or `ios/` |
| Backend source files | 0 | only `.gitkeep` |
| Driver app source files | 0 | only `.gitkeep` |
| Admin source files | 0 | only `.gitkeep` |

Static counts are not proof of passing behavior. The web audit report claims a 32-file/268-test engineering PASS, but its own text says independent audit sign-off is unavailable (`docs/web/ego_web_audit_report.md:6-12`). The Flutter README claims 317 tests (`E-go/README.md:35`), but the suite was not independently executed for this audit.

### 3.3 Git and documentation state

- Branch `main`; remote `https://github.com/StarPijush/E-RICKSHAW-RIDE.git`.
- Three commits; latest `bbe6aa1`.
- Many modified and untracked files in `E-go` and `E-go-web`.
- `docs/repository_cleanup/repository_inventory.md:8` still says two commits — stale.
- Root `README.md:11` claims Android, iOS, and Web for `E-go`; only `E-go/web/` exists.
- Root `README.md:25-35` claims phone OTP as the primary auth path; the Flutter app also implements password login.
- Root `README.md:52-53` calls backend/packages/infrastructure “scaffolded”; they contain only `.gitkeep` files.
- `E-go-web/README.md` correctly scopes the web app as a demo, but exposes demo credentials in plaintext.

## 4. Findings by layer

### 4.1 Product scope

**Classification: CONFLICT**

The blueprint MVP is Toto-only, cash-only, phone-OTP-only, and explicitly excludes scheduled rides and UPI (`toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:14-24`; `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:3-4`). The clients do not match:

- Flutter offers Bike and Toto (`E-go/lib/core/mock_pricing.dart:9`).
- Flutter offers selectable UPI (`E-go/lib/features/booking/presentation/place_order_screen.dart:148-170`).
- Flutter has a scheduled-pickup selector and time picker (`E-go/lib/features/location/presentation/location_selection_screen.dart:37-40`, `172-211`).
- Web offers Bike and Toto (`E-go-web/src/lib/domain/types.ts:14-16`).
- Web’s payment enum includes UPI, card, and wallet, although the UI only enables cash (`E-go-web/src/lib/domain/types.ts:45-47`; `E-go-web/src/components/account/payment-methods-screen.tsx:19-24`).

These are not harmless extras. They change vehicle eligibility, fare rules, payment state, UI flow, and backend schema. Scope must be frozen before schema work.

### 4.2 Flutter passenger app

**Classification: PARTIALLY VERIFIED — prototype**

Strengths:

- Coherent screen flow for pickup, destination, vehicle, review, searching, tracking, completion, rating, history, and profile.
- Clean theme and reusable widgets.
- Provider-based state is understandable.
- FSM transition table is explicit.
- Mock pricing is centralized.
- OSRM adapter is isolated.
- 45 test files / 317 static declarations.

Critical limits:

- Only `web/` platform exists; no Android or iOS target.
- `AppState` owns auth, booking, fare, route, driver, and ride state in one controller (`E-go/lib/app/app_state.dart:41-49`, `82-114`).
- Mock auth is the default; API auth is unimplemented (`E-go/lib/features/auth/data/auth_repository_factory.dart:11-25`).
- Accounts and sessions are in memory; only onboarding is persisted (`E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:1-4`, `218-228`).
- OTP is a fixed development code (`E-go/lib/features/auth/data/services/mock_otp_service.dart:5-12`).
- Password login is implemented (`E-go/lib/app/app_state.dart:271-293`), conflicting with OTP-only.
- Booking creates a local ride with a timestamp ID and no network call (`E-go/lib/app/app_state.dart:643-698`; `E-go/lib/features/booking/data/booking_repository.dart:122-126`).
- Driver search returns a hard-coded mock driver (`E-go/lib/app/app_state.dart:710-787`; `E-go/lib/features/booking/data/driver_repository.dart:34-69`).
- Current location always returns unavailable (`E-go/lib/features/location/data/current_location_service.dart:1-5`, `64-69`).
- Routing uses public OSRM (`E-go/lib/features/routing/data/services/osrm_route_service.dart:12-18`).
- Bengali is cosmetic; only `en_US` is supported (`E-go/lib/app/app.dart:34`; `E-go/lib/features/account/presentation/settings_screen.dart:17`, `22-63`).
- No FCM, secure storage, local database, or background location in `pubspec.yaml`.

### 4.3 Next.js web app

**Classification: PARTIALLY VERIFIED — demo**

Strengths:

- Clear App Router structure and reusable UI.
- Domain schemas and pure orchestrator are well isolated.
- Mock repositories are behind a single factory, so replacement is feasible.
- HTTP adapter stubs exist.
- Demo auth is disabled in production.
- 32 test files / 268 static declarations.

Critical limits:

- Every repository is mock (`E-go-web/src/lib/repositories/index.ts:54-64`).
- HTTP adapters return `NOT_IMPLEMENTED_ERROR` (`E-go-web/src/lib/repositories/http/auth-repository.ts:18-23`).
- Mock DB is browser `localStorage` (`E-go-web/src/lib/mock/db.ts:4-10`, `147-165`).
- Auth sessions are browser-persisted (`E-go-web/src/stores/auth-store.ts:8-10`, `263-273`).
- The FSM is a port of the Flutter client FSM, not the server FSM (`E-go-web/src/lib/domain/booking-fsm.ts:1-13`).
- The app is a customer demo, not an admin console (`README.md:12`; `docs/web/ego_web_architecture.md:5`).
- Demo credentials are committed in `.env.example` and README files.
- PBKDF2 uses 10,000 iterations, which is demo-grade (`E-go-web/src/lib/mock/auth-mock.ts:51-52`).

The web app is valuable as a UX reference and as a possible foundation for a future admin console, but it is not a production passenger client and not an operations console today.

### 4.4 Backend, database, and infrastructure

**Classification: MISSING**

- `backend/` contains only `.gitkeep` files in `migrations`, `src/api`, `src/common`, `src/modules`, `src/workers`, and `tests`.
- No schema, migration, seed, function, worker, queue, or API exists.
- No Postgres/PostGIS, RLS policy, index, constraint, trigger, or transaction exists.
- No auth service, OTP delivery, session store, or role model exists.
- No dispatch loop, offer expiry, driver freshness, fare quote, booking intent, trip event, cash ledger, audit log, or outbox exists.
- `infrastructure/` contains only `.gitkeep` files in `ci-cd`, `database`, `docker`, `env-templates`, and `monitoring`.
- No CI pipeline, deployment, secret management, backup, monitoring, or alerting exists.

The blueprint defines the target, but none of it is implemented. This is the largest gap.

### 4.5 Driver and admin

**Classification: MISSING**

- `E-go-rider` has only `.gitkeep` files under `lib/` and `test/`.
- `E-go-admin` has only `.gitkeep` files under `lib/app`, `lib/core`, `lib/features`, `lib/shared`, and `test`.

The driver app is not optional for a ride-hailing pilot. It must support online/offline, offers, accept, navigation handoff, start, complete, cash declaration, earnings, and sanctions. The admin console must support driver approval, live monitoring, support, config, ledger review, and audit. Neither exists.

### 4.6 Authentication and security

**Classification: CONFLICT / MISSING**

- Flutter defaults to mock auth and implements password login (`E-go/lib/features/auth/data/auth_repository_factory.dart:11-20`; `E-go/lib/app/app_state.dart:271-293`).
- Flutter OTP is a fixed development constant (`E-go/lib/features/auth/data/services/mock_otp_service.dart:5-12`).
- Flutter release builds throw if mock auth is used, which is good, but there is no real replacement.
- Web auth is mock-only and browser-persisted (`E-go-web/src/lib/mock/auth-mock.ts:1-18`; `E-go-web/src/stores/auth-store.ts:8-10`).
- Web demo auth is disabled in production (`E-go-web/src/lib/config/env.ts:66-71`), which is good.
- No server-side rate limit, lockout, OTP attempt cap, session rotation, revocation, or device binding exists.
- No RLS, role claim, admin TOTP, or audit trail exists.
- No secure storage exists in Flutter; web tokens live in browser storage.
- Plaintext demo credentials are committed in `E-go-web/.env.example:19-23`, `E-go-web/README.md:31-43`, and `E-go/README.md:5-8`.

The demo security is adequate for a local demo and inadequate for production. The committed demo credentials must be removed or clearly isolated before the repository becomes public or is deployed.

### 4.7 Dispatch, lifecycle, and cash

**Classification: MISSING / PARTIALLY VERIFIED**

The blueprint requires:

- Server-side nearest-first dispatch with radius expansion (`toto-go-blueprint/07-MATCHING-AND-DISPATCH.md:6-17`).
- Transactional offer acceptance with exactly one winner (`toto-go-blueprint/07-MATCHING-AND-DISPATCH.md:49-58`).
- Booking intent, idempotency, 15-second timeout, and reconciling state (`toto-go-blueprint/18-BOOKING-FAILURE-AND-RECOVERY-REQUIREMENTS.md:5-16`).
- Server FSM with revisions and event log (`toto-go-blueprint/20-STATE-MACHINE.md:7-39`).
- Cash ledger separate from trip completion (`toto-go-blueprint/09-PAYMENTS-AND-CASH.md:25-34`).

The clients have:

- A local 16-state UI FSM (`E-go/lib/core/booking_state.dart:5-87`; `E-go-web/src/lib/domain/booking-fsm.ts:1-38`).
- Deterministic simulated driver assignment after a timer.
- Local ride records and local payment enum.
- No offer, quote, revision, idempotency, event log, or ledger.

The current simulation is useful for UI demonstration and test choreography. It is not a dispatch or accounting implementation.

### 4.8 Quality, testing, and operations

**Classification: PARTIALLY VERIFIED / MISSING**

- Flutter has 45 test files / 317 static declarations.
- Web has 32 test files / 268 static declarations.
- No test was run for this audit.
- No contract test, integration test, migration test, device test, network-chaos test, or end-to-end booking test exists.
- No CI workflow exists.
- No staging environment exists.
- No observability, alerting, backup, or restore drill exists.
- No accessibility or Bengali localization verification exists.
- No performance or load test exists.

The test suites are a credible starting point, but they test mocks and simulations. They do not prove server integration, security, or production behavior.

## 5. P0 blockers

P0 means **must be resolved before any pilot with real users, drivers, or cash**. These are not style issues.

| ID | Blocker | Evidence | Exit condition |
|---|---|---|---|
| BLK-01 | No backend, API, database, or migrations | empty `backend/`; `E-go/lib/features/auth/data/auth_repository_factory.dart:21-25`; `E-go-web/src/lib/repositories/http/auth-repository.ts:18-23` | Supabase schema, migrations, functions, and staging API exist and pass contract tests |
| BLK-02 | No server-authoritative FSM or idempotent booking | `E-go/lib/core/booking_state.dart:5-87`; `E-go/lib/app/app_state.dart:643-698`; blueprint 18 and 20 | Server owns transitions, revisions, idempotency, booking intent, and reconciliation |
| BLK-03 | Auth is mock/password, not OTP-only | `E-go/lib/features/auth/data/auth_repository_factory.dart:11-25`; `E-go/lib/app/app_state.dart:271-293`; `E-go/lib/features/auth/data/services/mock_otp_service.dart:5-12`; blueprint 10 | Phone OTP, rate limits, lockout, secure sessions, role claims, and logout/revocation work on staging |
| BLK-04 | No driver application | empty `E-go-rider/` | Driver can go online, receive offers, accept, start, complete, and declare cash |
| BLK-05 | No admin console | empty `E-go-admin/` | Admin can approve drivers, monitor live rides, handle support, edit config, and review ledger/audit |
| BLK-06 | No Android/iOS target or real location | only `E-go/web/`; `E-go/lib/features/location/data/current_location_service.dart:1-5` | Android build installs; foreground/background location works within policy |
| BLK-07 | No dispatch, realtime, or push | no server dispatch; no FCM in `E-go/pubspec.yaml:9-16`; mock timers in `E-go/lib/app/app_state.dart:710-787` | Offers, expiry, radius expansion, realtime trip updates, and push wake-up work end to end |
| BLK-08 | No cash ledger | no backend; local payment enum only (`E-go/lib/features/booking/data/booking_repository.dart:9-11`) | Completion, cash declaration, 24-hour rule, dispute, admin correction, and daily rollup work |
| BLK-09 | Demo-only persistence and security | `E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:1-4`; `E-go-web/src/lib/mock/db.ts:4-10`; `E-go-web/.env.example:19-23` | Production builds have no mock auth, localStorage DB, demo credentials, or client-trusted state |
| BLK-10 | No CI, infrastructure, or observability | empty `infrastructure/` | CI gates, migration dry-run, staging deploy, logs, crash reporting, alerts, backup, and restore exist |
| BLK-11 | MVP scope drift | bike/toto, UPI, schedule, card/wallet in `E-go` and `E-go-web` | Scope frozen to Toto + cash + OTP + no scheduled rides; non-MVP UI removed or flagged |

## 6. Major issues (P1)

P1 means **must be resolved before production or public launch**, but does not necessarily block a controlled staging build.

| ID | Issue | Evidence | Required action |
|---|---|---|---|
| ISS-01 | Shared Flutter core absent | empty `packages/`; standalone `E-go` | Extract models, API client, config, storage, geo, and FSM mirror into `e_go_core` |
| ISS-02 | Map/route provider undecided | `E-go/lib/features/routing/data/services/osrm_route_service.dart:14`; blueprint D2 | Choose provider, SLA, cost, attribution, and failure behavior |
| ISS-03 | Bengali localization incomplete | `E-go/lib/app/app.dart:34`; cosmetic selector `E-go/lib/features/account/presentation/settings_screen.dart:17`, `22-63` | Add ARB/localization and Bengali-first copy review |
| ISS-04 | Web admin path undefined | web is customer demo (`README.md:12`; `docs/web/ego_web_architecture.md:5`) | Re-scope web as admin or keep as demo; do not call it an admin console |
| ISS-05 | Demo credentials committed | `E-go-web/.env.example:19-23`; `E-go-web/README.md:31-43`; `E-go/README.md:5-8` | Remove plaintext values; use placeholders; rotate if ever used outside demo |
| ISS-06 | Documentation contradicts tree | `README.md:11`, `25-35`, `52-53`; `docs/repository_cleanup/repository_inventory.md:8` | Correct platform, auth, scaffold, and commit claims |
| ISS-07 | Test claims not independently verified | `docs/web/ego_web_audit_report.md:6-12`; `E-go/README.md:35` | Re-run in CI and record exact commands/results |
| ISS-08 | No privacy/retention/compliance design | no backend; no consent, retention, or deletion flow | Define PII, consent, retention, deletion, and DLT/SMS compliance before pilot |

## 7. Security and privacy assessment

### 7.1 Current posture

| Control | Current state | Risk |
|---|---|---|
| Transport | Not verified | Unknown |
| Authentication | Mock/password; fixed dev OTP | Critical for production |
| Session storage | Flutter memory; web localStorage | Critical for production |
| Authorization | Client-side only | Critical |
| RLS / row security | None | Critical |
| Rate limiting / lockout | None | Critical |
| Secret management | Demo credentials committed | High |
| Password hashing | PBKDF2 10,000 iterations, demo only | Medium for demo; not production policy |
| Admin audit | No admin console | Critical for operations |
| PII/retention | Undefined | High |
| Location privacy | No real tracking | Not yet implemented |
| Payment security | No real payment | Cash-only MVP reduces scope |

### 7.2 Security conclusions

- The current system has **no production trust boundary**. All state is client-side or mock.
- The demo credentials are not production secrets, but their presence in the repository is a hygiene and release risk. They must not be copied into staging/production or reused.
- The target must use short-lived access tokens, rotating refresh tokens, secure storage, server-side role checks, RLS, rate limits, and audit logs.
- The target must never expose a Supabase service-role key to Flutter, the browser, or a public build.
- Ride-state changes must be server-validated; RLS alone cannot enforce a booking FSM.
- A privacy review is required before collecting driver documents, precise location, phone numbers, or trip histories.

## 8. Blueprint alignment

| Area | Alignment | Evidence |
|---|---|---|
| Product scope | CONFLICT | Bike, UPI, and schedule exist in clients; blueprint MVP is Toto/cash/no schedule |
| Platform choice | PARTIALLY VERIFIED | Supabase approved by owner; not implemented |
| Client stack | PARTIALLY VERIFIED | Flutter and Next.js exist; driver/admin/shared packages do not |
| Data model | MISSING | Blueprint 05 defined; no migrations |
| Backend architecture | MISSING | Blueprint 06 defined; empty `backend/` |
| Dispatch | MISSING | Blueprint 07 defined; client simulates |
| Lifecycle | PARTIALLY VERIFIED | Client FSM/simulation only; no server lifecycle |
| Cash | MISSING | Blueprint 09 defined; no ledger |
| Auth/security | CONFLICT | Password/mock auth vs OTP-only server auth |
| Admin | MISSING | Blueprint 12 defined; empty `E-go-admin/` |
| Driver | MISSING | Blueprint 08/04 defined; empty `E-go-rider/` |
| Failure recovery | MISSING | Blueprint 18 defined; no intent/idempotency/reconciling |
| Acceptance tests | PARTIALLY VERIFIED | Blueprint 19 defined; only mock unit/widget tests exist |
| Operations | MISSING | Blueprint 22 defined; empty `infrastructure/` |
| Documentation | CONFLICT | Several README/inventory claims are stale |

## 9. Reusable assets

| Asset | Reuse potential | Conditions |
|---|---|---|
| Flutter screens, theme, widgets | High | Replace data layer; remove bike/UPI/schedule; add Android; localize |
| Flutter FSM transition table | Medium | Keep as UI flow reference; do not use as server contract |
| Flutter mock pricing | Medium | Replace with server fare quote; keep as test fixture |
| Flutter OSRM adapter | Low | Replace or proxy behind a provider abstraction |
| Flutter tests | Medium | Adapt to real repositories; add integration/device tests |
| Web UI and design system | Medium | Keep as demo/UX reference; re-scope before admin use |
| Web domain schemas | Medium | Reuse types where they match the contract; remove non-MVP payment types |
| Web ride orchestrator | Medium | Use as simulation/reference; server must own transitions |
| Web mock repositories | Low | Useful for demos/tests; never production |
| Web PBKDF2 demo auth | Low | Do not productionize; replace with OTP sessions |
| Blueprint 00–22 | High | Normative design source |
| Rapido analysis | Reference only | No code, assets, keys, or endpoints may be copied |

The highest-value reuse is the UI and domain modeling work. The lowest-value reuse is the mock persistence/auth layer.

## 10. Test and quality assessment

### 10.1 What is credible

- Both clients have meaningful unit/widget test structure.
- Web has pure domain tests for FSM, fare, and orchestration.
- Flutter has tests across auth, booking, tracking, history, and profile.
- The web mock layer is deterministic and suitable for UI demos.
- The blueprint has a detailed acceptance matrix and launch gates (`toto-go-blueprint/19-MVP-ACCEPTANCE-TESTS.md:5-99`; `toto-go-blueprint/21-IMPLEMENTATION-ROADMAP-AND-READINESS.md:33-49`).

### 10.2 What is missing

- No server/contract/integration tests.
- No database migration tests.
- No realtime/reconnect tests.
- No offer-race or dispatch-expiry tests against a real database.
- No device/background-location tests.
- No Android build test.
- No Bengali localization test.
- No security/authorization tests.
- No load/performance tests.
- No CI execution evidence.

### 10.3 Test-count caveat

The web report’s PASS claim (`docs/web/ego_web_audit_report.md:6-12`) and the Flutter README’s 317-test claim (`E-go/README.md:35`) were not independently reproduced. Static counts match the files, but passing status is **NOT TESTED** in this audit.

## 11. Go/no-go conditions

### 11.1 NO-GO

Do not proceed to:

- Public pilot
- Real passenger or driver onboarding
- Real cash collection
- App-store submission
- Production marketing
- Production data migration
- Connecting the current clients to a production backend

until all P0 blockers are closed and the launch gates pass.

### 11.2 CONDITIONAL GO

Authorize only Stage 0 and, after its exit criteria, Stage 1. Conditions:

1. Owner freezes MVP: Toto-only, cash-only, OTP-only, no scheduled rides, no UPI/wallet/card.
2. Owner accepts the target architecture and Supabase as the platform.
3. Owner records D2–D9 decisions or explicit defaults.
4. Supabase dev/staging projects and versioned migrations exist.
5. API contract and schema are reviewed and frozen for Stage 1.
6. `e_go_core` boundary and Flutter package layout are approved.
7. CI, secret scanning, and migration dry-run are active.
8. Demo credentials are removed from committed docs/env examples.
9. No client calls a mock in staging.
10. A staging smoke path is defined: OTP → request → offer → accept → start → complete with cash → rating.

### 11.3 What can proceed now

- Documentation correction.
- Contract/schema design review.
- Supabase project setup in non-production.
- Shared package extraction planning.
- CI and secret-scan setup.
- Scope cleanup in UI (remove or flag non-MVP features).
- Test inventory and acceptance-test mapping.

No backend implementation should begin until the owner reviews this report and authorizes Stage 0.

## 12. Decisions

### 12.1 Resolved

| ID | Decision | Status |
|---|---|---|
| D1 | Backend platform | Supabase approved by owner; blueprint recommendation is Supabase (`toto-go-blueprint/11-PLATFORM-INFRASTRUCTURE-AND-COSTS.md:4-14`; `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:9`) |

### 12.2 Open

| ID | Decision | Impact | Blueprint default / recommendation |
|---|---|---|---|
| D2 | Map and route provider | Cost, SLA, attribution, offline behavior | flutter_map + OSRM recommended; public OSRM is not a production SLA |
| D3 | SMS gateway and DLT route | OTP delivery, cost, compliance | Required before real auth |
| D4 | Fare floors/caps | Fare validation, disputes | Owner decision |
| D5 | Cancel-before-arrival fee | Cancellation UX, ledger | Owner decision |
| D6 | iOS support | Build scope, cost | Default v2 |
| D7 | Static UPI QR | Payment scope | Default v1.1; MVP cash-only |
| D8 | Passenger max-fare preference | Dispatch/UX | Default off |
| D9 | Play Store distribution | Pilot distribution | Default direct APK for pilot |

Source: `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:6-17`. D10–D15 have recorded design defaults but still require owner acceptance before pilot.

## 13. Recommended next actions

### Owner

1. Read reports 07 and 13.
2. Freeze MVP scope and reject non-MVP client features for the pilot.
3. Approve the target architecture and Supabase.
4. Decide D2–D9 or explicitly delegate them.
5. Authorize Stage 0 only, with a review gate before Stage 1.

### Engineering

1. Create Supabase dev/staging projects and the `backend/` migration/function skeleton.
2. Translate blueprint 05 and 13 into schema and contract drafts.
3. Define the `e_go_core` package boundary and shared models.
4. Add Android target and a location strategy spike.
5. Add CI, secret scan, migration dry-run, and staging smoke test.
6. Remove or isolate demo credentials and stale documentation claims.
7. Map existing tests to blueprint acceptance tests; mark gaps.
8. Do not connect production clients to mocks or mock clients to production.

### Stop point

This audit stops before backend implementation. The next action requires owner review and explicit authorization.

## 14. Key evidence index

| Topic | Evidence |
|---|---|
| MVP scope | `toto-go-blueprint/01-PRODUCT-REQUIREMENTS.md:11-24` |
| Client stack | `toto-go-blueprint/03-TECH-STACK.md:4-9` |
| Data model | `toto-go-blueprint/05-DATA-MODEL.md:5-105` |
| Backend architecture | `toto-go-blueprint/06-BACKEND-ARCHITECTURE.md:3-54` |
| Dispatch | `toto-go-blueprint/07-MATCHING-AND-DISPATCH.md:6-58` |
| Lifecycle | `toto-go-blueprint/08-BOOKING-AND-RIDE-LIFECYCLE.md:3-35` |
| Cash | `toto-go-blueprint/09-PAYMENTS-AND-CASH.md:25-34` |
| Auth/security | `toto-go-blueprint/10-AUTH-AND-SECURITY.md:3-49` |
| Supabase | `toto-go-blueprint/11-PLATFORM-INFRASTRUCTURE-AND-COSTS.md:4-14` |
| Admin | `toto-go-blueprint/12-OPERATIONS-AND-ADMIN.md:3-52` |
| API contracts | `toto-go-blueprint/13-API-CONTRACTS.md:5-110` |
| Decisions | `toto-go-blueprint/15-DECISIONS-AND-OPEN-QUESTIONS.md:3-53` |
| Failure requirements | `toto-go-blueprint/18-BOOKING-FAILURE-AND-RECOVERY-REQUIREMENTS.md:5-69` |
| Acceptance tests | `toto-go-blueprint/19-MVP-ACCEPTANCE-TESTS.md:5-99` |
| Canonical FSM | `toto-go-blueprint/20-STATE-MACHINE.md:7-99` |
| Roadmap/readiness | `toto-go-blueprint/21-IMPLEMENTATION-ROADMAP-AND-READINESS.md:5-49` |
| Ops runbook | `toto-go-blueprint/22-OPERATIONS-RUNBOOK.md:6` |
| Flutter dependencies | `E-go/pubspec.yaml:9-16` |
| Flutter auth | `E-go/lib/features/auth/data/auth_repository_factory.dart:11-25` |
| Flutter mock auth | `E-go/lib/features/auth/data/repositories/mock_auth_repository.dart:1-232` |
| Flutter booking | `E-go/lib/app/app_state.dart:643-787` |
| Flutter FSM | `E-go/lib/core/booking_state.dart:5-87` |
| Flutter location | `E-go/lib/features/location/data/current_location_service.dart:1-69` |
| Flutter routing | `E-go/lib/features/routing/data/services/osrm_route_service.dart:12-43` |
| Flutter schedule UI | `E-go/lib/features/location/presentation/location_selection_screen.dart:37-40`, `172-211`, `399-441` |
| Web repositories | `E-go-web/src/lib/repositories/index.ts:54-64` |
| Web HTTP stubs | `E-go-web/src/lib/repositories/http/auth-repository.ts:18-23` |
| Web mock DB | `E-go-web/src/lib/mock/db.ts:4-10`, `147-165` |
| Web mock auth | `E-go-web/src/lib/mock/auth-mock.ts:1-18`, `51-52`, `250-340` |
| Web auth store | `E-go-web/src/stores/auth-store.ts:8-10`, `263-273` |
| Web demo credentials | `E-go-web/.env.example:19-23`; `E-go-web/README.md:31-43` |
| Web audit caveat | `docs/web/ego_web_audit_report.md:6-12` |
| Stale inventory | `docs/repository_cleanup/repository_inventory.md:8` |
| Root README conflicts | `README.md:11`, `25-35`, `52-53` |

## 15. Audit limitations

- Static audit only; no code, test, build, database, device, or external service was executed.
- No backend or infrastructure exists to inspect; findings about missing server behavior are based on the absence of implementation and the presence of mock paths.
- The working tree is dirty; line references reflect the current working tree and may drift after edits.
- The 01–06 and 08–12 reports have not yet been written; this report is the current synthesis and should be re-issued if those reports change the evidence.
- Existing test-pass claims were not independently reproduced.
- No legal, privacy, DLT, or payment-compliance certification is provided.
- No secret values are reproduced; the presence of demo credentials is reported by file and line only.
- This report records owner decisions; it does not make them.

## 16. Final statement

The repository has strong design documentation and usable UI prototypes, but it is not a ride-hailing system yet. The honest verdict is **NO-GO for pilot** and **CONDITIONAL GO for Stage 0**. The fastest safe path is to freeze scope, build the Supabase contract/schema, extract the shared Flutter core, and establish CI before adding more UI or connecting any client to a real backend.
