# E-GO Web — Approved Implementation Plan

Status: **APPROVED** · Orchestrator · 2026-11-15
Architecture: [`ego_web_architecture.md`](./ego_web_architecture.md) (approved with amendments A1–A14 below)
Product research: [`research_a_auth_ux.md`](./research_a_auth_ux.md), [`research_b_booking_map.md`](./research_b_booking_map.md), [`research_c_rides_data.md`](./research_c_rides_data.md), consolidated in [`ego_web_product_research.md`](./ego_web_product_research.md)

## 1. Mission

Build `D:\E-RICKSHAW RIDE\E-go-web`, a separate Next.js 16 / React 19 / TypeScript customer application that reproduces the essential E-GO Flutter customer experience: onboarding, mock auth, home/map, place selection, vehicles, fare, booking lifecycle, ride history, rating, profile and support. Mobile-first responsive with intentional desktop layouts. All dispatch/tracking/payment behavior is explicitly simulated.

## 2. Approved amendments to the architecture

| ID | Decision |
|----|----------|
| A1 | TypeScript `~5.9` (installed 5.9.3), ESLint 9. No TS 7 upgrade during this mission. |
| A2 | Map: react-leaflet 5 + Leaflet 1.9 with `ssr: false`; fallback to Leaflet direct mount if StrictMode issues arise. OSM tiles, attribution preserved, env-overridable. |
| A3 | `/help-support`, `/about` and `/safety` live inside the protected app shell (consistent web UX). `/register` redirects to `/create-account`. |
| A4 | Demo auth is enabled only when `NEXT_PUBLIC_ENABLE_DEMO_AUTH=true` **and** `NODE_ENV !== 'production'`. Credentials documented in README/.env.example. Production build must not contain `EgoDemo@123` or mock OTP. |
| A5 | Registration: name + phone + optional email + password. Account is created then OTP-verified. New users then complete `/profile-setup`; demo user goes straight to `/home`. |
| A6 | Registered accounts may sign in with their password. The mock DB stores a salted SHA-256 hash (Web Crypto) only — never plaintext. Demo account is seeded with the approved demo password. OTP remains `123456` in demo mode with 30 s cooldown. |
| A7 | Demo account is seeded with 3 historical rides (2 completed incl. 1 unrated, 1 cancelled) so My Rides and Ride Details are demonstrable. New registrations start with no history. |
| A8 | Lifecycle timings: searching 6 s → assigned 4 s → arriving 12 s → arrived (manual "Start trip", auto 30 s) → in progress 15 s → completed 0.5 s → awaiting rating. Cancellation 0.3 s. Constants in `lib/config/constants.ts`, deadline-based (`nextTransitionAt`), refresh-recoverable. |
| A9 | Payments: Cash is the default and only selectable method for booking; UPI/other methods are visible as "coming soon" in Payment Methods, matching Flutter's FAQ. Never collect card data. |
| A10 | My Rides filters: All / Completed / Cancelled plus an active-ride banner. Flutter's "Shared" filter is omitted because shared rides are unsupported (honest empty filter is not a feature). |
| A11 | Ride Details route is `/ride-details/[id]` (deep-linkable). Flutter's object argument is not portable. |
| A12 | Rating supports stars 1–5 (required), optional comment; skip is allowed and preserves an unrated completed ride that can be rated later. |
| A13 | Map interactions: OSM display; search list is primary selector; map tap selects nearest seeded POI (mock reverse geocode) with confirm bar; simulated route is a dashed straight polyline labelled "Approx. route · simulated". |
| A14 | Flutter's duplicate/dead screens (legacy phone login/onboarding, duplicate my_rides re-export) are not recreated. Safety screen is routed. |

## 3. Delivery batches

| Batch | Scope | Owner | Acceptance |
|-------|-------|-------|------------|
| 0 | Scaffold: Next app, strict TS, Tailwind 4 tokens, local Poppins/Inter, branding assets, Vitest/RTL harness, `.env` gating, security headers | Orchestrator | `typecheck`, `lint`, `test`, `build` green (done) |
| 1 | Domain + data: types/Zod, geo + fare, booking FSM, orchestrator, labels/copy, env/constants, utils, repositories, mock DB/seeds, auth hashing, tests | Developer | Fare goldens, 16×16 FSM matrix, phone/OTP/auth/repo tests green; no UI imports |
| 2 | Design system + shell: UI primitives, layout (sidebar/bottom nav/top bar), auth guard/hydration, toasts, error/loading/not-found | Developer | Primitives accessible; guard redirect test; responsive shell at 375/768/1440 |
| 3 | Auth + onboarding: splash gate, 3 onboarding slides, login, create account, OTP, profile setup, demo card, returnTo | Developer | Demo login → home; register → OTP → profile setup → home; errors/cooldown/visibility |
| 4 | Booking flow: home, pickup/destination/saved places, vehicle selection, fare, confirmation, searching/retry/cancel, driver assigned, trip completion, rating | Developer | End-to-end booking; FSM valid only; refresh resumes; simulated labels |
| 5 | Map + live tracking: Leaflet integration, markers/polyline, selection, fallback, tracking UI, desktop split layout | Developer | Map lazy-loaded; no SSR errors; fallback + text summary; responsive |
| 6 | Rides + account: my rides (filters/empty), ride details, profile/edit, payment methods, notifications, help/support, settings, about, safety | Developer | History persists; rate from history; profile updates; clear demo data; deep links |
| 7 | Hardening: full test pass, responsive QA, a11y, build grep for demo creds, docs, README | Auditor + Developer | `npm run verify` green; audit findings resolved; final report |

Batches execute sequentially. Only one agent edits a given file at a time. Batch 1 freezes `src/lib/domain/*` contracts; changes require Orchestrator approval. Batch 2 freezes `globals.css` tokens.

## 4. Required routes (31 including alias)

Public: `/`, `/onboarding`, `/onboarding-2`, `/onboarding-3`, `/login`, `/create-account`, `/otp`, `/profile-setup`.
Protected: `/home`, `/pickup-selection`, `/destination-selection`, `/saved-places`, `/vehicle-selection`, `/fare-details`, `/booking-confirmation`, `/searching-driver`, `/driver-assigned`, `/ride-tracking`, `/trip-completed`, `/ride-rating`, `/my-rides`, `/ride-details/[id]`, `/profile`, `/edit-profile`, `/payment-methods`, `/notifications`, `/help-support`, `/settings`, `/about`, `/safety`.
Alias: `/register` → `/create-account`.

## 5. Quality gates

- `npm run lint`, `npm run typecheck`, `npm test`, `npm run build` must pass on every batch.
- No imports from `E-go`, no Dart, no `dangerouslySetInnerHTML` for user data.
- Simulated behavior labeled; no claims of real SMS/payments/dispatch/GPS.
- Demo credentials dev-only and absent from production bundle.
- Mobile 320/375/390, tablet 768, desktop 1024/1440 verified.
- Accessibility: labeled controls, keyboard flows, visible focus, `aria-live` for status, map text fallback.

## 6. Documentation deliverables

- `docs/web/ego_web_product_research.md` (consolidated)
- `docs/web/ego_web_architecture.md` (approved)
- `docs/web/ego_web_implementation_plan.md` (this file)
- `docs/web/ego_web_audit_report.md` (Auditor)
- `docs/web/ego_web_final_report.md` (Orchestrator)
- `E-go-web/README.md` (setup, commands, env, demo credentials, mock behavior, architecture)
