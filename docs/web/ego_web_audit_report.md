# E-GO Web — Audit Report

- **Date:** 2026-11-20
- **Scope:** `E-go-web/` customer web app (Next.js 16, React 19, TypeScript)
- **Audit basis:** approved architecture, implementation plan, user requirements, acceptance criteria
- **Result:** Engineering verification **PASS**; independent audit sign-off **UNAVAILABLE**

> The Auditor agent could not run (`Model is unavailable`, then
> `Model not found: opencode/glm-5.3-flash-free`). A `reasoner` review was run
> instead but stopped at its step limit and returned `REVIEW INCOMPLETE —
> provisional FAIL`. Every actionable finding from that review was fixed and
> re-verified below. This report does not claim a complete independent audit.

## 1. Verified evidence

| Gate | Result |
| --- | --- |
| `npm run lint` | Pass (part of `npm run verify`) |
| `npm run typecheck` | Pass (part of `npm run verify`) |
| `npm test` | Pass — 32 test files, 268 tests |
| `npm run build` | Pass — 34 generated pages, 31 app routes |
| Secret check | Pass — `npm run check:secrets` finds no `EgoDemo@123`, `Demo OTP: 123456`, or quoted `123456` in `.next/static` or `.next/server` |
| Route/alias check | `/register` redirect present; `/about`, `/help-support`, `/safety` present |
| Demo gate | Dev-only seeded demo account; production build has no seeded shared login |
| Production runtime | `next start` served `/login` and `/otp` with 200 responses and no demo card/code |

Reproduce:

```powershell
cd E-go-web
npm run verify
Get-ChildItem .next -Recurse -File | Select-String -SimpleMatch 'EgoDemo@123'
```

## 2. Findings and resolutions

| ID | Severity | Finding | Resolution | Status |
| --- | --- | --- | --- | --- |
| AUD-01 | High | Demo password/OTP could appear in server chunks because literals lived in source. | Replaced with PBKDF2 verifiers; plaintext demo values now come from server-only `DEMO_LOGIN_*` env and are passed as page props. | Fixed |
| AUD-02 | Medium | StrictMode double-mount could mark stores hydrated before the first read finished. | `StoreHydrator` now shares one hydration promise and sets flags only after it settles. | Fixed |
| AUD-03 | Medium | OTP cooldown display reset on refresh/arrival from login. | `OtpForm` initializes the countdown from `otpCooldownUntil`. | Fixed |
| AUD-04 | Low | Seeded notification named a different driver than the cancelled ride. | Seed text now names `Madan Mahato`. | Fixed |
| AUD-05 | Medium | Non-demo OTP was generated but never shown, leaving registration/login dead after account creation. | `requestOtp` stores the mock code in memory; the OTP screen shows a labelled “Mock OTP (not sent by SMS)” card. It is never persisted or put in a URL. | Fixed |
| AUD-06 | Medium | Skip-rating failure still navigated away, hiding the error. | `handleSkip` returns on failure; only skips navigation on success. | Fixed |
| AUD-07 | Medium | Historical rating could leave a stale active booking banner. | Clears the booking when the rated ride is the current active ride. | Fixed |
| AUD-08 | Low | Login page linked to protected `/help-support`, producing a redirect loop. | Dead Help link removed. | Fixed |
| AUD-09 | Low | Architecture/plan text described the old lazy plaintext demo credentials. | Updated architecture, implementation plan, code comments and README. | Fixed |
| AUD-10 | Info | A test/lint run timed out under CPU contention and produced three false failures. | Reran lint, typecheck and the full suite alone; all 268 tests pass. | Closed |

## 3. Confirmed behaviors

- Protected routes redirect unauthenticated visitors to `/login` with a
  sanitized `returnTo`; public auth/onboarding routes remain reachable.
- Booking transitions are deadline-based and recover after refresh; live ride
  routes are guarded, while completed/unrated rides remain ratable.
- Ride details are ownership-checked; seeded demo data belongs to the demo
  user.
- Saved places, notifications, profile edits and settings changes persist and
  survive reload; corrupt local storage is archived and reset safely.
- Cash is the only selectable payment method; no card fields exist.
- Simulated labels are present for dispatch, GPS, SMS and emergency actions.
- All 31 app routes render from the production build; `/_not-found` and
  `/icon.png` are included in the generated-page count.

## 4. Residual limitations

1. **Mock-only backend.** Accounts, rides and sessions live in browser
   `localStorage`. There is no server-side authorization, rate limiting or
   cross-device account.
2. **Production demo account disabled by design.** `NODE_ENV=production`
   removes the seeded demo login. New accounts can still use the labelled mock
   OTP, but the seeded demo credentials are local-development only.
3. **No real integrations.** No driver dispatch, GPS, SMS, payments or
   emergency calls; all are explicitly simulated.
4. **No browser E2E suite.** Verification is jsdom/Vitest plus production
   build checks; no Playwright/visual regression run.
5. **Public OSM tiles.** The default tile provider is subject to the
   OpenStreetMap usage policy and is not a production SLA.
6. **No CSP nonce or server hardening.** Basic headers are set, but a real
   deployment needs a backend, HTTPS, CSP and real authentication.

## 5. Sign-off

Engineering acceptance criteria are met and the tree is build-clean. The app
is suitable for local demo and stakeholder review. It is **not** cleared for a
real production deployment until the mock backend and integrations in section
4 are replaced. A complete independent audit remains outstanding because the
Auditor agent model was unavailable.
