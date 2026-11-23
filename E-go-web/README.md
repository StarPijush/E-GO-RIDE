# E-GO Web

Customer web app for **E-GO**, a local Toto (E-Rickshaw) and Bike ride-hailing
demo for **Jhargram, West Bengal**. The app reproduces the core customer
journey of the Flutter app in a responsive Next.js application.

> This is a browser demo. No real driver is dispatched, no GPS or SMS is used,
> no payment is taken, and the emergency features do not contact anyone.

## Stack

- Next.js 16.4 (App Router, Turbopack, typed routes)
- React 19.3 and TypeScript 5.9 (strict)
- Tailwind CSS 4 with the E-GO tokens
- Zustand 5 with browser persistence
- Zod 4, React Hook Form
- react-leaflet 5 / Leaflet 1.9 with OpenStreetMap, loaded client-side only
- Vitest 5, Testing Library, jsdom

## Quick start

```powershell
cd E-go-web
npm install
Copy-Item .env.example .env.local
npm run dev
```

Open <http://localhost:3000>.

The seeded demo account:

| Field | Value |
| --- | --- |
| Phone | `9000000001` |
| Password | `EgoDemo@123` |
| OTP | `123456` |

The demo card and the OTP hint appear only while demo auth is enabled. The
values are read from server-only `DEMO_LOGIN_*` variables and passed to the
login/OTP pages; they are not embedded in the production client or server
bundles. Demo auth is disabled when `NODE_ENV=production`, so a production
build is a verification artifact, not a real authentication deployment.

Copy `.env.example` to `.env.local` before using the demo. The server-only
values must not be prefixed with `NEXT_PUBLIC_`.

## Commands

```powershell
npm run dev        # development server
npm run lint       # ESLint
npm run typecheck  # tsc --noEmit
npm test           # Vitest suite
npm run build      # production build
npm run check:secrets  # reject demo credentials in the build output
npm run verify     # lint + typecheck + test + build + secret check
```

## Routes

Public routes: `/`, `/onboarding`, `/onboarding-2`, `/onboarding-3`,
`/login`, `/create-account`, `/register` (alias), `/otp`, `/profile-setup`.

Protected routes: `/home`, `/pickup-selection`, `/destination-selection`,
`/saved-places`, `/vehicle-selection`, `/fare-details`,
`/booking-confirmation`, `/searching-driver`, `/driver-assigned`,
`/ride-tracking`, `/trip-completed`, `/ride-rating`, `/my-rides`,
`/ride-details/[id]`, `/profile`, `/edit-profile`, `/payment-methods`,
`/notifications`, `/help-support`, `/settings`, `/about`, `/safety`.

## What is implemented

- Three-slide onboarding, phone/password login, demo login, OTP login,
  account creation and profile setup.
- Home map with active-ride banner, pickup/destination selection, saved
  places, searchable Jhargram places and a map-click selector.
- Toto/Bike selection, transparent fare breakdown, booking confirmation,
  simulated driver search, assignment, arrival, trip progress and receipt.
- Persisted booking state machine with refresh recovery, cancellation and
  late rating of a completed ride.
- My Rides filters (All / Completed / Cancelled), ride details, rating from
  history (`/ride-rating?rideId=...`).
- Profile editing, cash-only payment methods, notification read state,
  settings (demo data reset, logout, language and notification switches),
  help/report dialog, FAQ, simulated safety tools and About page.
- Accessible focus states, labeled controls, responsive mobile/tablet/desktop
  layouts, loading/empty/error states, route boundaries and a map fallback.

## Simulation and data

Everything is local to the browser:

- Accounts live in `localStorage` under `ego:db:v1`; passwords are stored as
  salted PBKDF2-SHA-256 verifiers, never plaintext.
- Seed data contains one demo user, three historical rides (one rated, one
  awaiting rating, one cancelled), saved places, notifications and drivers.
- The booking lifecycle is deadline-based: search 6 s, assigned 4 s, arriving
  12 s, arrived (manual start or 30 s auto-start), trip 15 s, completed 0.5 s,
  cancellation 0.3 s.
- Clearing demo data in Settings removes the local database and session.
- There is no SMS gateway. Outside demo mode the generated OTP is shown in a
  clearly-labelled "Mock OTP (not sent by SMS)" card so account creation and
  OTP login remain usable. The code is held in memory only and is never
  persisted or placed in a URL.
- The seeded demo account itself exists only while demo auth is enabled; a
  production build has no pre-seeded shared login.

## Architecture

- `src/app` – routes, metadata, loading/error/not-found boundaries.
- `src/components` – screens, layout shell, auth/booking/account/ride/support
  features and the UI kit.
- `src/lib/domain` – types, schemas, booking FSM, fare/geo helpers, labels.
- `src/lib/repositories` – the only screen-facing data API; mock adapters sit
  behind it.
- `src/lib/mock` – local database, seed data, auth/ride/payment/notification
  adapters and simulation helpers.
- `src/stores` – Zustand auth, booking and preference stores with persistence.
- `tests` – unit, repository, store and component tests.

See the approved specs in `../docs/web/`:
[product research](../docs/web/ego_web_product_research.md),
[architecture](../docs/web/ego_web_architecture.md), and
[implementation plan](../docs/web/ego_web_implementation_plan.md).

## Security and honesty

- Demo credentials and the fixed demo OTP are allowed only when
  `NEXT_PUBLIC_ENABLE_DEMO_AUTH=true` and `NODE_ENV !== 'production'`.
- The demo password/OTP are sourced from server-only environment values.
  `npm run check:secrets` (part of `verify`) fails if plaintext
  `EgoDemo@123` or the fixed demo OTP appears in `.next/static` or
  `.next/server`.
- All dispatch, GPS, SMS, payment and emergency behavior is simulated and
  labeled as such.
- Cash is the only selectable payment method. No card data is collected.
- The mock session is not a real security boundary; a production backend
  would need server-side auth, httpOnly cookies and real rate limiting.
