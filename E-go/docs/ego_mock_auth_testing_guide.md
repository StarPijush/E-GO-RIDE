# E-GO Mock Authentication Testing Guide

Development-only authentication for the E-GO customer Flutter app. This guide
covers the demo account, registration, OTP, sessions, route protection, tests,
and the limits of the mock implementation.

> **Not production authentication.** Accounts and sessions live in memory. No
> SMS is sent. Passwords are not hashed for storage because nothing is stored
> beyond the current app process. Mock mode refuses to run in a release build.

---

## 1. Run the app

```powershell
cd "D:\E-RICKSHAW RIDE\E-go"
flutter pub get
flutter run --dart-define=AUTH_MODE=mock
```

`AUTH_MODE` is a compile-time flag (`String.fromEnvironment`):

| Value | Behaviour |
| --- | --- |
| `mock` (default for local development) | In-memory mock repository with demo account and fixed OTP |
| `api` | Throws `UnimplementedError` until a real API repository is added |
| anything else | Throws `StateError` |

In a **release build**, `AUTH_MODE=mock` throws during app startup instead of
silently shipping fake authentication.

---

## 2. Demo account

| Field | Value |
| --- | --- |
| Phone | `9000000001` |
| Password | `EgoDemo@123` |
| Name | `E-GO Demo User` |
| Email | `demo@ego.local` |

Accepted phone formats include `9000000001`, `+91 90000 00001`,
`919000000001`, and `09000000001`; all normalize to `+919000000001`.

Demo login goes **directly to customer Home**. Login does not require OTP.

### Login rules

- Phone must normalize to a valid 10-digit Indian mobile number starting 6–9.
- Any non-empty password may be submitted; the mock repository still compares it
  with the stored mock account. A wrong password fails.
- Exact errors:
  - Invalid phone: `Please enter a valid 10-digit mobile number.`
  - Wrong credentials: `Incorrect phone number or password. Please try again.`
  - Unknown account: `No account found. Please create an account first.`

---

## 3. Registration flow

1. Open **Create your account** from Login.
2. Enter full name, 10-digit Indian phone number, password, and optional email.
3. Tap **Create account**.
4. Enter the mock OTP on the verification screen.
5. Success goes to customer Home.

Registration password policy: at least **8 characters** and not whitespace-only.
Emails are optional but must be plausible when supplied. Duplicate phone numbers
are rejected with:

`An account with this phone number already exists. Please log in.`

### Mock OTP

| Field | Value |
| --- | --- |
| OTP | `123456` |
| Resend cooldown | 30 seconds |
| Resend action | Restarts the mock cooldown; no SMS is sent |

An invalid OTP shows `Invalid OTP. Please try again.` and clears the fields. The
account remains signed out until OTP succeeds.

The OTP hint banner is shown only when mock mode is active.

---

## 4. Session and onboarding behaviour

- A successful demo login creates an in-memory session.
- A successful registration creates the account, but the session is only
  created after OTP verification.
- Session restore works within the running app/process.
- **Killing and restarting the app clears accounts and sessions.** The demo
  account is re-seeded automatically; accounts registered in a previous run are
  gone.
- Onboarding completion is the only auth-related value persisted, under the
  SharedPreferences key `ego_onboarding_complete`. It survives logout and app
  restarts, so onboarding is not shown again.
- Logout clears the session and profile and routes directly to Login.
- No password, session token, or OTP value is written to SharedPreferences or
  logs.

---

## 5. Protected routes

When navigating through the real app router, an unauthenticated customer is
redirected to Login for these routes:

- Home and location selection (`/home`, pickup, destination, saved places)
- Booking lifecycle (vehicle selection through rating)
- My rides and ride details
- Profile, edit profile, payment methods, notifications, settings

Public routes that remain accessible without auth include onboarding, Login,
registration, OTP, Help & Support, and About.

Route protection is applied in `lib/app/app.dart` by passing an authentication
callback to `EGoRouter.generateRoute`. Test/preview code that calls the router
without the callback keeps direct route access, which preserves existing widget
tests.

---

## 6. Automated tests

Run the full suite:

```powershell
cd "D:\E-RICKSHAW RIDE\E-go"
flutter analyze
flutter test
```

Relevant test files:

| File | Coverage |
| --- | --- |
| `test/unit/auth_repository_test.dart` | Demo login, phone normalization, wrong/unknown credentials, registration, duplicate phone, OTP, onboarding persistence, no credentials in prefs, validators |
| `test/widget/auth_screens_flow_test.dart` | Login → Home, exact login errors, invalid phone, registration → OTP → Home, invalid OTP, duplicate phone |
| `test/integration/auth_flow_test.dart` | Protected-route redirect, public Help route, logout → Login, onboarding survives logout |
| `test/widget/phone_login_screen_test.dart` | Existing visual/responsive tests plus non-empty-password policy |
| `test/widget/create_account_screen_test.dart` | Existing registration visual/responsive tests |
| `test/widget/onboarding_flow_test.dart` | Onboarding → Login persistence |

Existing screenshots remain in `test/screenshots/`:

- `login_screen_393x852.png`
- `login_screen_375x667.png`
- `login_screen_412x915.png`
- `register_screen_393x852.png`
- `register_screen_375x667.png`
- `register_screen_412x915.png`

---

## 7. Manual smoke test

1. Launch with mock mode.
2. Log in with the demo account → Home appears; no OTP screen.
3. Log out from Profile or Settings → Login appears.
4. Submit a wrong demo password → exact wrong-credentials message.
5. Submit an unregistered valid phone → exact account-not-found message.
6. Create an account with a new phone, valid password, optional email.
7. Enter `000000` → invalid OTP error; fields clear.
8. Enter `123456` → Home appears and the new account is signed in.
9. Restart the app → demo account still works; the newly registered account is
   gone; onboarding is not repeated.
10. Try to open a protected route while logged out → Login.

---

## 8. Replacing the mock with a real backend

Implement `AuthRepository` from
`lib/features/auth/domain/repositories/auth_repository.dart`, then return it from
`createAuthRepository()` for `AuthMode.api` in
`lib/features/auth/data/auth_repository_factory.dart`.

Production requirements:

- Verify credentials server-side; never persist or log raw passwords.
- Send a real OTP through an SMS provider and enforce server-side expiry,
  attempt limits, and resend cooldowns.
- Use secure token storage (for example platform keystore/keychain), not
  SharedPreferences.
- Prefer OTP-based login to match the approved UI copy
  (“We'll send a 6-digit verification code via SMS.”).
- Remove the demo account seed and mock OTP hint from release paths.
- Keep the release guard that rejects mock authentication.
