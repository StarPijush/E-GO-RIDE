# E-GO Web — Consolidated Product Research (Verified against Flutter source)

Status: **FINAL** · Source of truth: `D:\E-RICKSHAW RIDE\E-go` (Flutter customer app, read-only) · Companion docs: [`ego_web_architecture.md`](./ego_web_architecture.md), [`ego_web_implementation_plan.md`](./ego_web_implementation_plan.md)
Method: every claim below was read from Dart source; file paths (and line ranges where useful) are cited. Items that could not be verified are explicitly marked **UNVERIFIED**. Superseded skeletons: `research_a_auth_ux.md`, `research_b_booking_map.md`, `research_c_rides_data.md` (their screen inventory was partially corrected here).

## 1. Verified screen inventory

Router: `E-go/lib/app/router.dart` (`EGoRouter.generateRoute`, :101-285). Unauthenticated access to a protected route renders `LoginScreen` under route name `/login` (:105-112) **only when** an `isAuthenticated` callback is supplied (the real app supplies it; tests omit it). `protectedRoutes` (:74-94) contains exactly **19** routes: home, pickup/destination/saved-places, vehicle/fare/confirmation/searching/assigned/tracking/completed/rating, my-rides, ride-details, profile, edit-profile, payment-methods, notifications, settings. **`/help-support`, `/about`, `/profile-setup` are NOT protected in Flutter.** Unknown route → scaffold "Not Found" / "No route defined for {name}" (:271-283).

### 1.1 Routed screens (30 routes + 1 alias = the web's 31 routes)

| # | Route | Flutter screen (file under `E-go/lib/`) | Auth | Purpose | Web disposition |
|---|---|---|---|---|---|
| 1 | `/` | SplashScreen — `features/auth/presentation/splash_screen.dart` | No | 2 s brand splash + session gate | Recreated as `/` splash gate |
| 2 | `/onboarding` | OnboardingScreenOne — `features/onboarding/presentation/screens/onboarding_screen_one.dart` | No | Onboarding step 1 "Move your way, every day" | Recreated |
| 3 | `/onboarding-2` | OnboardingScreenTwo — `.../onboarding_screen_two.dart` | No | Step 2 "Fast bike rides, anytime" | Recreated |
| 4 | `/onboarding-3` | OnboardingScreenThree — `.../onboarding_screen_three.dart` | No | Step 3 "Ride across Jhargram" | Recreated |
| 5 | `/login` | LoginScreen → PhoneLoginScreen — `features/auth/presentation/login_screen.dart` (wrapper, :27) → `features/auth/presentation/screens/phone_login_screen.dart` | No | Phone + password login | Recreated |
| 6 | `/create-account` | CreateAccountScreen — `features/auth/presentation/screens/create_account_screen.dart` | No | Registration (name/phone/password/optional email) | Recreated |
| 7 | `/register` | **alias** of CreateAccountScreen (`router.dart:141-146`) | No | Duplicate path | Recreated as redirect → `/create-account` (plan A3) |
| 8 | `/otp` | OtpScreen(phone) — `features/auth/presentation/otp_screen.dart` | No | 6-digit OTP verify (arg: `String phone`, default `''`, :148) | Recreated |
| 9 | `/profile-setup` | ProfileSetupScreen — `features/auth/presentation/profile_setup_screen.dart` | No (public in Flutter) | Post-OTP name/email capture | Recreated (plan A5 makes it reachable; see §7 gap G4) |
| 10 | `/home` | EGoHomeScreen — `features/home/presentation/home_screen.dart` | Yes | Map home + booking panel + bottom nav | Recreated |
| 11 | `/pickup-selection` | PickupSelectionScreen — `features/location/presentation/pickup_selection_screen.dart` | Yes | Map pin / search pickup | Recreated |
| 12 | `/destination-selection` | DestinationSelectionScreen — `features/location/presentation/destination_selection_screen.dart` | Yes | Search + recents + suggestions | Recreated |
| 13 | `/saved-places` | SavedPlacesScreen — `features/location/presentation/saved_places_screen.dart` | Yes | Manage Home/Work/favourites | Recreated |
| 14 | `/vehicle-selection` | VehicleSelectionScreen — `features/booking/presentation/vehicle_selection_screen.dart` | Yes | Bike vs Toto with fares | Recreated |
| 15 | `/fare-details` | FareDetailsScreen — `features/booking/presentation/fare_details_screen.dart` | Yes | Fare breakdown + payment | Recreated |
| 16 | `/booking-confirmation` | BookingConfirmationScreen — `features/booking/presentation/booking_confirmation_screen.dart` | Yes | Final summary + confirm | Recreated |
| 17 | `/searching-driver` | SearchingDriverScreen — `features/booking/presentation/searching_driver_screen.dart` | Yes | Animated driver search + failure/retry | Recreated |
| 18 | `/driver-assigned` | DriverAssignedScreen — `features/booking/presentation/driver_assigned_screen.dart` | Yes | Driver card, ETA, contact, cancel | Recreated |
| 19 | `/ride-tracking` | RideTrackingScreen — `features/booking/presentation/ride_tracking_screen.dart` | Yes | Simulated live trip map | Recreated (Leaflet, plan A2/A13) |
| 20 | `/trip-completed` | TripCompletedScreen — `features/booking/presentation/trip_completed_screen.dart` | Yes | Arrival summary + fare | Recreated |
| 21 | `/ride-rating` | RideRatingScreen — `features/booking/presentation/ride_rating_screen.dart` | Yes | Stars + tags + comment | Recreated |
| 22 | `/my-rides` | MyRidesScreen — `features/rides/presentation/screens/my_rides_screen.dart` (re-exported by 0-byte `features/rides/presentation/my_rides_screen.dart`) | Yes | Ride history list + filters | Recreated (filters changed, A10) |
| 23 | `/ride-details` | RideDetailsScreen(ride: RideRecord) — `features/rides/presentation/ride_details_screen.dart` | Yes | Single ride detail | Recreated as `/ride-details/[id]` (A11; Flutter arg cast `settings.arguments as RideRecord` at `router.dart:230` **throws if null**) |
| 24 | `/profile` | ProfileScreen — `features/account/presentation/profile_screen.dart` | Yes | Account hub (title "Account") | Recreated |
| 25 | `/edit-profile` | EditProfileScreen — `features/account/presentation/edit_profile_screen.dart` | Yes | Edit name/email | Recreated |
| 26 | `/payment-methods` | PaymentMethodsScreen — `features/account/presentation/payment_methods_screen.dart` | Yes | Cash/UPI selection | Recreated (UPI as "coming soon", A9 — see §7 G6) |
| 27 | `/notifications` | NotificationsScreen — `features/notifications/presentation/notifications_screen.dart` | Yes | Notification list | Recreated |
| 28 | `/help-support` | HelpSupportScreen — `features/support/presentation/help_support_screen.dart` | **No** (Flutter) | FAQ + report issue + SOS mock | Recreated **inside protected shell** (A3; deliberate divergence) |
| 29 | `/settings` | SettingsScreen — `features/account/presentation/settings_screen.dart` | Yes | Language/toggles/legal/logout | Recreated |
| 30 | `/about` | AboutScreen — `features/account/presentation/about_screen.dart` | **No** (Flutter) | Brand/mission/region info | Recreated **inside protected shell** (A3) |

### 1.2 Unrouted / dead / non-route screens

| Screen (file) | Status in Flutter | Evidence | Web disposition |
|---|---|---|---|
| SafetyScreen — `features/safety/presentation/screens/safety_screen.dart` | **Unrouted** (no case in `router.dart`), yet fully built with optional bottom nav (`selectedIndex: 2`) | no import in router.dart | **Recreated** at `/safety` (A3/A14). ⚠ Its AppBar title is the copy bug `'Help & Support'` (safety_screen.dart:23) — web must title it "Safety" (see §7 G1) |
| Legacy `OnboardingScreen` — `features/auth/presentation/onboarding_screen.dart` | **Dead**: 3-slide PageView duplicate of onboarding 1-3 (own slide copy: "Ride across Jhargram" etc., :21-46), never routed | not imported by router.dart | **Skipped** (A14) |
| `LocationSearchDelegate` — `features/location/presentation/location_search_delegate.dart` | **Live, not a route**: opened by PickupSelection's search icon via `showSearch` (pickup_selection_screen.dart:69-83) | used | Recreated as in-page search overlay/results on pickup screen |
| `RecentDestinationsBottomSheet` — `features/location/presentation/recent_destinations_bottom_sheet.dart` | Not a route; destination screen uses horizontal `EGoRecentDestinationChip`s instead (destination_selection_screen.dart:148-177). Whether the sheet is referenced anywhere: **UNVERIFIED** | — | Skipped (recents rendered as chips row, matching destination screen) |
| PhoneLoginScreen — `features/auth/presentation/screens/phone_login_screen.dart` | **NOT dead** — it is the actual `/login` UI behind the `LoginScreen` wrapper (login_screen.dart:27). Prior research note `research_c` marking it "DEAD/legacy" is **wrong** | router.dart:136-140 | Recreated as `/login` |
| Duplicate My Rides — `features/rides/presentation/my_rides_screen.dart` (0 bytes) | Benign re-export of `screens/my_rides_screen.dart` | file size 0 | Skipped (A14) |
| `MockData.homePlace` / `workPlace` — `mock_data/mock_data.dart:140-154` | Seed placeholders ("Add home address") that `SavedPlacesScreen` does **not** use (it seeds its own 3 places) | saved_places_screen.dart:23-48 | Not used; web seeds its own saved places (§5.7) |

## 2. End-to-end customer journeys (verified)

**J1 — First launch / onboarding.** Splash `/` (yellow bg, logo, "Move your way.", 1200 ms animation, navigate at 2000 ms; waits `isAuthInitialized`) → `isLoggedIn`? `/home` : `hasCompletedOnboarding`? `/login` : `/onboarding` (splash_screen.dart:56-78). Onboarding 1 → 2 → 3 (push); **Skip** on any screen or final CTA "Next" → `markOnboardingComplete()` (persisted) → `/login`.

**J2 — Login.** `/login` phone+password → `loginWithPassword` → success → `pushNamedAndRemoveUntil(/home)`; failure → inline error (repo message). Links: "New to E-GO? Create account" → `/create-account`; "Help" chip → `/help-support`.

**J3 — Register → OTP → (profile setup) → home.** `/create-account` validated submit → `registerAccount` (repo creates account, **session NOT established**, app_state.dart:117-119) → success → `/otp` with raw phone arg. OTP: 6 boxes, paste/auto-verify at 6 digits; wrong → clear + "Invalid OTP. Please try again."; verify success → `restoreSession()` → if `profile.isProfileComplete` → `/home` else `/profile-setup` (otp_screen.dart:136-140). **In mock, `register()` sets `isProfileComplete: true` (mock_auth_repository.dart:147), so `/profile-setup` is unreachable after registration** — plan A5 deliberately makes web route new users through `/profile-setup` instead (§7 G4). Profile setup: name (≥2 chars) + optional email → `completeProfileSetup` → `/home`.

**J4 — Home → booking.** `/home`: destination unset → CTA "CHOOSE LOCATION" → `/destination-selection`; pick place → default pickup applied if null → `proceedToVehicleSelection` (FSM idle→…→selectingVehicle + `loadVehicles`) → `pushReplacement(/vehicle-selection)`. Destination already set → CTA "SELECT VEHICLE" → `/vehicle-selection`. Vehicle "Continue" → `proceedToFareReview` → `/fare-details` → "Confirm vehicle" → `proceedToConfirmation` → `/booking-confirmation` → "Confirm booking" → navigate `/searching-driver` **then** `confirmBooking()` (4 s search delay → 2 s driver delay → FSM searchingDriver→driverAssigned, ride record inserted) → listener pushes `pushReplacement(/driver-assigned)`.

**J5 — Assigned → trip → rating.** `/driver-assigned` (auto-advance timer 3 s, or manual "Track driver") → FSM driverAssigned→driverArriving → `pushReplacement(/ride-tracking)`. Tracking timer +5 %/2 s: at 45 % → `driverArrived()` + snackbar "Driver has arrived at pickup!"; at 50 % → `startTrip()`; at 100 % → `completeTrip()` (marks ride completed, FSM tripCompleted → 500 ms → awaitingRating) → `pushReplacement(/trip-completed)`. Either "Rate your ride" → `/ride-rating` (submit → rated → thank-you → 1.5 s → home) **or** "Done" → `skipRating()` (FSM → idle) → home. Searching failure path: 12 s watchdog → failed → "Retry" (`retrySearch`) / "Back to home" (`resetToIdle`). Cancel path: searching "Cancel search" or assigned close-icon dialog → `cancelRide()` (ride marked cancelled, 300 ms → idle, booking reset) → home.

**J6 — History.** Bottom-nav "Rides" (or Profile → My rides) → `/my-rides` → filter pills → card tap → `/ride-details` (Flutter object arg; web id deep-link) → back. "Book a TOTO" (empty state) → `/destination-selection`.

**J7 — Account.** `/profile` ("Account") → edit (`/edit-profile`, snackbar "Profile updated"), saved places, payment methods, help, notifications, settings, about; "Log out" dialog → `logout()` → `/login`. Settings also logs out (dialog "Are you sure you want to log out of E-GO?").

**J8 — Support/safety.** `/help-support`: FAQ accordions, "Report an issue" dialog (snackbar confirm), "Emergency SOS (Mock)" snackbar. Flutter's Safety screen is unreachable (unrouted); web adds `/safety` (A3).
## 3. Screen specifications (verified from Flutter source)

Legend per screen: purpose, layout, exact copy (quoted), controls/interactions, loading/empty/error states, navigation, simulated flag. Currency glyph in Dart sources is U+20B9 (₹); it renders as mojibake in Windows console output only.

### 3.1 Auth and onboarding (public routes)

**`/onboarding` - Onboarding step 1** - `features/onboarding/presentation/screens/onboarding_screen_one.dart`
- Purpose: first-run brand intro (1 of 3).
- Layout: shared `OnboardingScreenLayout` (identical geometry across all 3 steps): header (wordmark only on step 1, `showWordmark: true`), hero illustration area (`OnboardingHero` + `LocationIllustration`, badge `Urban Flow`), progress `currentStep: 0`, Skip action, bottom CTA.
- Copy (exact): heading `Move your way,\nevery day`; body `Set your pickup, choose a vehicle, and ride - it's that simple.`; CTA `Get started`.
- Interactions: CTA -> push `/onboarding-2`; **Skip** -> `AppState.markOnboardingComplete()` (persisted) -> `pushReplacementNamed(/login)`. Test seams: `onNext`, `onSkip`, `enableAnimations=false`.
- States: static; illustration animations optional. Simulated: none.

**`/onboarding-2` - Onboarding step 2** - `.../onboarding_screen_two.dart`
- Layout: same widget, `showWordmark: false`, `BikeIllustration`, `currentStep: 1`.
- Copy (exact): `Fast bike rides,\nanytime` / `Need to get somewhere quickly? A bike rider is just a tap away.` / CTA `Next` -> push `/onboarding-3`; Skip identical to step 1.

**`/onboarding-3` - Onboarding step 3** - `.../onboarding_screen_three.dart`
- Layout: same widget, `TotoIllustration`, `currentStep: 2`.
- Copy (exact): `Ride across\nJhargram` / `Book affordable Toto (E-Rickshaw) and Bike rides anywhere in Jhargram city.` / CTA `Next` -> `markOnboardingComplete()` -> `pushReplacementNamed(/login)`; Skip identical.

**`/login` - Phone + password login** - `login_screen.dart` (wrapper, delegates at :27) -> `screens/phone_login_screen.dart`
- Purpose: sign in with phone + password against the mock repository.
- Layout: canonical 393x852 (`PhoneLoginConstants`), h-padding 24, scrollable column: header row (`E-GO` wordmark Poppins 24/32 w700 + 6px yellow dot | **Help** pill -> `/help-support`), heading block, 56px phone field, password field (shared `AuthPasswordField`, `Key('login_password_field')`), security note, optional general-error box, spacer, CTA, create-account link, legal line.
- Copy (exact): heading `Enter your\nphone number` (Poppins 28/34 w700, -0.02em); sub `We'll send a 6-digit verification code via SMS.` (15/22 w500) - **conflicts with password login, see §7 G2**; field label `PHONE NUMBER` (11px w700, ls 0.8); hint `98765 43210`; prefix `+91` with IN flag; security `Your number is kept secure & encrypted` (12px muted); CTA `Continue` (h58, r16, yellow); link `New to E-GO? Create account` (underlined 1.5); legal `By continuing, you agree to the Terms of Service and Privacy Policy of E-GO.` (11/16 centered muted).
- Errors (exact): `Please enter a valid 10-digit mobile number.`; `Please enter your password.`; login failure -> `appState.error` else `Invalid credentials. Please retry.`; exception -> `Network error. Please check your connection.`
- Interactions: phone input digits-only, max 10; valid -> green check suffix; non-empty invalid -> clear (x) suffix; focus -> 2px border + yellow halo (`brandPrimaryHalo` #33FFC928, blur 0 / spread 3); error -> `errorSurface` bg + 2px error border + inline icon+text row; loading -> spinner inside CTA, disabled colors `disabledBackground`/`disabledForeground`.
- States: CTA disabled until `AuthValidators.isValidPhone` AND `isValidLoginPassword` (non-empty) (`continue_button`); general error box `Key('login_error_message')`.
- Navigation: success -> `pushNamedAndRemoveUntil(/home)`; `Create account` -> `/create-account`; `Help` -> `/help-support`. Test keys: `login_phone_input`, `continue_button`.
- Simulated: mock auth (`AUTH_MODE` compile-time, default `mock` - `core/config/auth_config.dart`).

**`/create-account` - Registration** - `screens/create_account_screen.dart` (alias `/register` -> same screen, `router.dart:141-146`)
- Purpose: create account (name, phone, password, optional email), then OTP verification.
- Layout: header `E-GO` wordmark 22px + yellow dot (no Help chip); heading `Create your account` (Poppins 30/36 w700, -0.02em); sub `Sign up to start booking TOTO & fast bike rides across India in seconds.` (14/20 w500); 4 stacked fields (16px gaps); general error (conditional); CTA `Create account` (h56, r16); footer.
- Fields (exact labels/placeholders): `FULL NAME` ph `Rahul Sen` (person icon) | `PHONE NUMBER` shared `AuthPhoneField` ph `98765 43210` | `PASSWORD` shared `AuthPasswordField` ph `Enter your password` | `EMAIL ADDRESS` + badge `OPTIONAL` ph `rahul@example.com`.
- Errors (exact): `Please enter your full name.` / `Please enter a valid 10-digit mobile number.` / `Password must be at least 8 characters.` / `Please enter a valid email address.` / general `Registration failed. Please try again.` / `Network error. Please check your connection.`
- Validation: name non-empty (trim), phone `^[6-9]\d{9}$`, password >= 8 chars and not whitespace-only, email empty-or-valid (§5.2). Submit disabled until all valid (`create_account_button`); any input change clears general error; loading spinner in CTA.
- Navigation: success -> `pushNamed(/otp, arguments: phone)` - **session is NOT established at this point** (`app_state.dart:117-119`); footer `Already have an account? Log in` (underline brand, thickness 3) -> pop else `pushReplacement(/login)`; legal `By continuing, you agree to our Terms of Service & Privacy Policy` under a top divider.
- Simulated: mock registration; mock `register()` marks profile complete (§5.4, §7 G4).

**`/otp` - Phone verification** - `otp_screen.dart` (arg `String phone`, router default `''`, `router.dart:148`)
- Purpose: 6-digit code check; mock code is always `123456`.
- Layout: AppBar (back arrow + centered wordmark); heading `Verify your\nnumber` (headlineMedium 28); sub `Enter the 6-digit code sent to\n+91 {phone}`; mock banner shown only when `AuthConfig.isMockMode` (`Key('otp_demo_hint')`): warning-light pill with info icon, text `Demo OTP: 123456` (`MockOtpService.devOtp`); six digit boxes 46x56 (r12; fill: invalid -> `errorLight`, focused -> `brandPrimaryLight`, else `surface`; focused border navy 2px); `Verify` primary button; resend row.
- Interactions: auto-advance on digit, backspace steps back to previous box, paste distributes digits, **auto-verifies when 6 digits**; `Verify` (`otp_verify_button`) disabled until 6; verifying -> centered spinner replaces button+resend; invalid -> clear all boxes, refocus first, error `Invalid OTP. Please try again.` (`otp_error_message`).
- Cooldown: 30 s (`MockOtpService.resendCooldown`); copy `Resend OTP in {n}s` -> then TextButton `Resend OTP` (`otp_resend_button`) -> `requestOtp(phone)`; failure -> `Could not resend OTP. Please try again.`
- Navigation: `verifyOtp` success -> `pushNamedAndRemoveUntil(appState.profile.isProfileComplete ? /home : /profile-setup)`. In mock, registration already set complete, so `/profile-setup` is bypassed (§7 G4).
- Simulated: **no SMS** - `MockOtpService.request()` is an explicit no-op ("No SMS gateway is contacted").

**`/profile-setup` - Post-OTP profile** - `profile_setup_screen.dart`
- Purpose: capture name + optional email for new accounts.
- Layout: AppBar without back button (centered wordmark); 90px avatar (yellowLight circle, 2px yellow border, person icon navy, camera badge - decorative, no picker); heading `Set up your profile` (headlineSmall 24); sub `Tell us your name so drivers can find you` (grey500); `Full name *` + `Email (optional)` fields (filled `surface`, r12, focus navy 2px, error border); CTA.
- Errors (exact): `Please enter your name` / `Name must be at least 2 characters` / `Please enter a valid email` (regex `^[^@]+@[^@]+\.[^@]+$`); submit failure snackbar `Could not complete your profile. Please try again.`
- Interactions: CTA `Start riding` (arrow icon) -> `completeProfileSetup(name, email?)`; loading disables button; success -> `pushNamedAndRemoveUntil(/home)`.
- Simulated: none (profile stored in mock session).

### 3.2 Home and location

**`/home` - Map home** - `features/home/presentation/home_screen.dart`
- Purpose: map-first home, booking panel, bottom navigation.
- Layout: Column = Expanded map section + booking panel + `bottomNavigationBar` (64px). Map is a **static `CustomPaint` illustration** (`HomeMapPainter`), NOT tiles; current-location marker `HomeCurrentLocationMarker` at ~47% x / 52% y. Overlays: top-left logo pill (surface, radius 100, `EgoLogo.icon(20)` + wordmark 15, 0.8px border) and bottom-right 56px recenter FAB (`my_location_rounded`, semantics `Recenter map to current location`) -> `_loadLocation()`.
- Booking panel: surface, top radius 28, 40x4 drag handle; heading `Where to?` (Poppins 24 w700, ls -0.3); destination button 54px/r14 (`surfaceVariant`) showing search icon + `Choose your destination` placeholder or destination label + chevron -> `/destination-selection`; pickup row: ring dot + `PICKUP LOCATION` (10px w700 ls 0.8) + label (default `Jhargram Railway Station (Plat. 1)`, `Station Road, Jhargram`) + yellow `Change` pill (25% yellow bg) -> `/pickup-selection`; `Add saved place` pill (`+`, surfaceVariant) -> `/saved-places`; full-width CTA 54px/r14 yellow, label **`CHOOSE LOCATION`** when no destination (-> destination screen) else **`SELECT VEHICLE`** (default pickup if null -> `proceedToVehicleSelection()` -> push `/vehicle-selection`).
- Init `_loadLocation()`: if pickup null and `getCurrentLocation()` resolves, set pickup `Jhargram Railway Station (Plat. 1)`; silent catch on failure (empty error state).
- Bottom nav (own implementation, not the shared widget): `Home`, `Rides` (EgoLogo icon when selected), `Safety` (shield), `Account`; selected = yellow pill + w700 11px label. Taps: 1 -> `/my-rides`, 2 -> **`/help-support`** (label says `Safety` - divergence, §7 G5), 3 -> `/profile`; each returns resets index to 0.
- States: no loading/error UI on home; map illustration means no tile loading at all. Simulated: location (fixed mock coords), map.

**`/pickup-selection` - Set pickup point** - `features/location/presentation/pickup_selection_screen.dart`
- Layout: AppBar `Set pickup point` + search action -> `showSearch(EGoLocationSearchDelegate)`. Body Stack: `FlutterMap` (OSM tiles `https://tile.openstreetmap.org/{z}/{x}/{y}.png`, userAgentPackageName `com.ego.customer`, initialZoom 16, initial center = current pickup or `MockData.mockCurrentLocation`); static center pin (dark chip `Pickup point` + 42px yellow `location_pin`); small FAB bottom-right (bottom:180) = current-location (`_isLocating` -> 18px spinner); bottom card (surface, top radius 16) with address title/subtitle (initial `Jhargram Station Road` / `Near Railway Station, Jhargram`), `Change` TextButton.icon (edit) -> search, CTA **`Confirm pickup location`**.
- Interactions: map drag (`onPositionChanged` + `hasGesture`) -> title `Pinned Pickup Point`, subtitle `{lat}, {lng} (Jhargram)` (4 decimals); current location -> `Current Location` / `Jhargram Station Area`, move zoom 16; search result -> move + set title/subtitle; confirm -> `setPickupLocation(SavedLocation id 'pickup-<ms>', icon my_location, type other)` -> `pop(result)`.
- States: locating spinner; no error path (mock never fails). Simulated: GPS.

**`/destination-selection` - Where are you going?** - `features/location/presentation/destination_selection_screen.dart`
- Layout: AppBar `Where are you going?`; `EGoSearchInput` hint `Search destination in Jhargram...`, autofocus, clear button; if query empty: `Recent places` section header + horizontal 72px chip row (170px `EGoRecentDestinationChip`s from `LocationRepository.getRecentDestinations()`, hidden when empty) + divider, then header `Suggested places` (else `Search results`).
- Results: 300ms simulated latency; loading = navy spinner; empty -> `EGoEmptyState` `No places found` / `Try searching for Bazar, Palace, Station or Hospital`; list tiles: icon in `brandPrimaryLight` square keyed by `PlaceType` (market=store, transport=train, landmark=account_balance, hospital=local_hospital, education=school, residential=home, other=location_on), title name, subtitle address, trailing chevron.
- Select (tile or recent chip) -> `setDestinationLocation`; if pickup null -> default pickup `Jhargram Railway Station` / `Station Road, Jhargram` @ `MockData.mockCurrentLocation`; `await proceedToVehicleSelection()` (FSM + `loadVehicles`) -> `pushReplacementNamed(/vehicle-selection)`.

**`/saved-places` - Saved places** - `features/location/presentation/saved_places_screen.dart`
- Layout: AppBar `Saved places`; local (non-persisted) state seeds 3 places: `Home` `Ward No. 8, Ghoradhara, Jhargram` (22.4580, 86.9080) | `Work / Office` `Near District Collectorate, Jhargram` (22.4510, 86.8990) | `Jhargram Raj Palace` `Palace Road, Old Jhargram` (22.4480, 86.8950). Does **not** use `MockData.homePlace/workPlace`.
- Interactions: card delete IconButton or swipe left-to-right dismiss (red background) -> snackbar `Place removed`; empty -> `EGoEmptyState` `No saved places yet` / `Save Home, Work and frequent destinations for faster booking` + action `Add place`; add dialog `Add Favorite Place` with `Label (e.g. Gym, Library, Friend's House)` and `Address in Jhargram` (blank address -> `Jhargram area`, coord = `MockData.jhargramCenter`), `Cancel`/`Save` -> snackbar `Place saved successfully!`; bottom CTA **`Add a new place`**.
- Simulated: none (component state only; lost on route exit - §7).

**Search delegate (not a route)** - `features/location/presentation/location_search_delegate.dart`
- Opened only from pickup screen search icon. Actions: clear (when query non-empty), back -> `close(null)`. Results = `repository.searchPlaces(query)`; loading 24px spinner; error -> `Search failed` / `Please try again`; empty with query -> `No results found` / `Try a different search term`; result tile (place-type icon, name, address, chevron) -> `close(context, result)`.

### 3.3 Booking lifecycle

**`/vehicle-selection` - Choose vehicle** - `features/booking/presentation/vehicle_selection_screen.dart`
- Layout: AppBar `Choose vehicle`; route summary card (dot/line/pin glyph column + pickup label, fallback `Current location`, + destination label); body states; bottom surface tray with `Estimated fare` row (`₹{total}`, titleLarge w700) + `Continue`.
- Body states: loading -> navy spinner (`vehiclesLoading`, 400ms mock latency); empty -> `EGoEmptyState` `No vehicles available` / `Please try again later` + `Go back`; list -> `_VehicleCard`s: 56px icon chip (toto -> `EgoLogo.icon(28)`, bike -> `two_wheeler`), name (`Bike` / `Toto`), capacity pill (`person` + count, only when > 1), subtitle (`Fast & affordable` / `E-Rickshaw - Up to 3 passengers`), clock row `{arrival} min arrival - {trip} min trip`, right column `₹{total}` + `{km} km` + `check_circle` when selected; selected card = 2px brand border + 12px yellow glow.
- Interactions: tap = `selectVehicle` (local `_selected`); first option auto-selected post-frame; `Continue` -> `proceedToFareReview()` (FSM selectingVehicle->reviewingFare) -> push `/fare-details`.
- Simulated: fares from `MockPricingService`; no availability API.

**`/fare-details` - Fare breakdown** - `features/booking/presentation/fare_details_screen.dart`
- Guard: `selectedVehicle == null` -> bare scaffold `No vehicle selected`.
- Sections (surface cards r16): `Your route` (pickup `Pickup location` fallback, destination `Destination` fallback, subtitles); vehicle row (icon, name, `{km} km - {mins} min trip`); `Fare estimate` rows: `Base fare`, `Distance ({km} km - ₹{rate}/km)` (rate bike 10 / toto 7 via local `_ratePerKm`), `Platform fee`, divider, `Total estimate`; info banner (infoLight) `This is a demo fare estimate. Actual fares may vary.`; `Payment method` card showing `Cash` or `UPI` from `appState.paymentMethod` with `Change` -> `/payment-methods`.
- CTA `Confirm vehicle` -> `proceedToConfirmation()` -> push `/booking-confirmation`.

**`/booking-confirmation` - Confirm booking** - `features/booking/presentation/booking_confirmation_screen.dart`
- Guard: vehicle/pickup/dest any null -> bare scaffold `Booking data missing`.
- Cards: vehicle + route (icon, name, `{mins} min - {km} km`, `₹total`, divider, `Pickup` and `Destination` rows with labels); `Payment` (`Cash`/`UPI`, `Change`); fare rows `Base fare` / `Distance fare` / `Platform fee` / divider / `Total`; warning banner (warningLight) `Demo mode: No real driver will be dispatched.`
- CTA **`Confirm booking`** -> `Navigator.pushNamed(/searching-driver)` **first**, then `await appState.confirmBooking()` (order matters; §5.6).

**`/searching-driver` - Finding your driver** - `features/booking/presentation/searching_driver_screen.dart`
- No AppBar. Searching state: 120px pulsing circle (scale 0.95->1.05, 1200ms loop, yellowLight + yellow glow) with vehicle icon/logo; `Finding your driver` (headlineSmall 24); `Searching nearby {vehicle name} drivers...`; route summary card; secondary CTA `Cancel search` -> `cancelRide()`.
- Watchdog: one-shot `Timer(12 s)` (code comment says 10 s) -> `handleSearchFailure()` only if still `searchingDriver`.
- Listener transitions: `driverAssigned` -> cancel timer + `pushReplacement(/driver-assigned)`; `failed` -> stay, render failure UI; `cancelled`/`idle` -> `pushNamedAndRemoveUntil(/home)`.
- Failure UI: `search_off` icon 72, `No drivers found`, `No drivers are available right now. Please try again.`, primary `Retry` (`retrySearch()`), secondary `Back to home` (`resetToIdle()` + home). **Retry path deadlocks - §7 G8.**
- Simulated: 4s search + 2s driver fetch in AppState/repos (§5.6).

**`/driver-assigned` - Driver assigned** - `features/booking/presentation/driver_assigned_screen.dart`
- Guard: `assignedDriver == null` -> bare scaffold `Driver not assigned`.
- AppBar `Driver assigned`, no back, close (x) -> cancel dialog. Yellow status card: `check_circle` 48, `Your driver is on the way!`, `Arriving in {n} min (demo)` (n = `fareBreakdown.estimatedArrivalMinutes`, fallback 3).
- Driver card: 60px avatar (person icon), `driver.name`, star + `driver.rating` + `- {totalRides} rides`; round call/chat buttons (40px, yellowLight) -> snackbars `Call driver: Calling {name}... (demo)` / `Message driver: Chat with {name} (demo)`; divider; three columns `Vehicle`/`Color`/`Plate` (`vehicleName`, `vehicleColor`, `vehicleNumber`); warning strip `Demo driver - not a real person` (warningLight, centered).
- Route card `Your ride`: pickup row (navy circle) + destination row (yellow pin).
- Auto-advance: `Timer(3 s)` -> `driverStartsArriving()` + `pushReplacement(/ride-tracking)`; manual CTA **`Track driver`** does the same immediately.
- Cancel dialog: `Cancel ride?` / `Are you sure you want to cancel this ride?` / `No, keep ride` / `Yes, cancel` (error) -> `cancelRide()` -> `pushNamedAndRemoveUntil(/home)`.
- Simulated: driver identity fixed (`Rajan Kumar` bike / `Suresh Das` toto - §5.7).

**`/ride-tracking` - Live trip (simulated)** - `features/booking/presentation/ride_tracking_screen.dart`
- Full-bleed `FlutterMap` (OSM tiles, initialZoom 14.5, center pickup): markers = pickup (navy circle 24), destination (`EGoDestinationMarker` 36), driver (yellow circle with toto logo or bike icon) interpolated along route.
- Simulation engine: `Timer.periodic(2 s)`, `+5%` per tick (0->100 = 40 s). 0-40%: driver lerps from `MockData.mockCurrentLocation` to pickup; **45%** -> `driverArrived()` + snackbar `Driver has arrived at pickup!`; **50%** -> `startTrip()`; >50%: driver lerps pickup -> destination; **100%** -> cancel timer, `completeTrip()`, `pushReplacement(/trip-completed)`.
- Top status pill: `Driver arriving...` -> `Driver arrived` -> `Trip in progress`. Bottom sheet (r16, handle): `LinearProgressIndicator` (yellowDark, 4px), driver name / plate, call + chat buttons -> snackbars `Call driver (demo)` / `Chat with driver (demo)`, destination row + `₹{total fare}`.
- No cancel/back control (dead-end; §7). Simulated: GPS, movement, driver.

**`/trip-completed` - You've arrived!** - `features/booking/presentation/trip_completed_screen.dart`
- Layout: 100px successLight circle + `check_circle_outline`; `You've arrived!` (headlineMedium w700); `Your trip is complete.`; fare box (yellowLight): `Total fare`, `₹{ride.fareBreakdown.totalFare ?? vehicle total}` (36px navy w700), **`Cash payment` hard-coded** (ignores UPI selection - §7 G6); trip summary card rows: `Vehicle`, `From`, `To`, `Driver`, `Trip ID` (`ride.tripId`), each with `—` fallback.
- Actions: primary **`Rate your ride`** -> `pushReplacement(/ride-rating)`; secondary **`Done`** -> `skipRating()` (FSM awaitingRating->idle) -> `pushNamedAndRemoveUntil(/home)`.

**`/ride-rating` - Rate your ride** - `features/booking/presentation/ride_rating_screen.dart`
- AppBar `Rate your ride`, no back, action **`Skip`** -> `skipRating()` + home. Body: 80px avatar, driver name (fallback `Your driver`), `How was your ride?`, 5 stars (44px; filled `brandYellowDark`, empty `grey300`), label map 1 `Very poor` / 2 `Poor` / 3 `Okay` / 4 `Good` / 5 `Excellent!`; section `What went well?` with FilterChips: `Great driver`, `Very clean`, `On time`, `Smooth ride`, `Friendly`, `Safe driving` (selected = yellowLight fill, navy check, navy side); comment field `Add a comment (optional)` (3 lines, r12, navy focus); CTA **`Submit rating`**.
- Validation: 0 stars -> snackbar `Please select a star rating`. Submit builds comment = selected tags + free text joined with `, ` -> `submitRating(rating, comment)` -> thank-you view (`favorite` icon, `Thank you!`, `Your feedback helps us improve.`) -> 1.5 s -> `pushNamedAndRemoveUntil(/home)`.
- Simulated: rating persisted only in in-memory ride record.

### 3.4 Ride history

**`/my-rides` - Your rides** - `features/rides/presentation/screens/my_rides_screen.dart` (+ widgets in `presentation/widgets/`)
- Layout: no AppBar; Column = `RidesHeader` (title `Your rides`, Poppins 28 w700 ls -0.42, + 40x40 circular `history` button whose tap resets filter to All), `RideFilterTabs`, Expanded list/empty, shared `EGoBottomNavBar(selectedIndex: 1)`.
- Filters (`RideFilter` enum): pills `All`, `Electric TOTOs`, `Shared` (pill = 11px, ls 0.44, selected yellow + `brandPrimaryBorder`, unselected grey100). **`Shared` always returns `const []`** with source comment: "Shared rides are not currently supported by the booking model. Return an honest empty result rather than fabricating rides."
- List: `RideCard`s (12px gap, h-padding 24). Card = surface r16 + divider border + shadow(0,2,8): header (bike icon `two_wheeler` or toto `EgoLogo.icon(18)` + `vehicleName` w700 14 + status chip), divider, pickup row (navy dot, 13px), destination row (yellow pin), divider, footer (`{d} {Mon} {y} • {h}:{mm} {AM/PM}` + optional star+rating + `₹{total}` w700 15). Status chips: `Completed` successLight/success, `Cancelled` errorLight/error, `Active` infoLight/info, `Upcoming` warningLight/warning. Tap -> `pushNamed(/ride-details, arguments: ride)` (object arg; §7 G9).
- Empty: `RidesEmptyState` - 80px yellowLight circle badge with `EgoLogo.icon(38)`, `No rides yet` (Poppins 20 w700), `Your completed and cancelled rides will appear here.` (max width 260), `Book a TOTO` pill CTA (`BookTotoButton`: yellow, radius 9999, `+` icon, min 200x52) -> `/destination-selection`.
- Bottom nav taps: 0 -> pop/replace `/home`, 1 -> no-op, 2 -> `/help-support` (label `Safety`), 3 -> `/profile`.
- Data: `context.watch<AppState>().allRides` = in-memory `MockBookingRepository` list, **seeded empty** (`_seedRides = []`, §5.7). History lost on restart. Simulated: yes.

**`/ride-details` - Ride details** - `features/rides/presentation/ride_details_screen.dart`
- Constructor requires `ride: RideRecord`; router does `settings.arguments as RideRecord` (`router.dart:230`) -> **throws on missing arg / refresh** (§7 G9). Web uses `/ride-details/[id]` + `getRideById`.
- Cards: (1) status card: `Trip ID`, `Date` (`_formatDate`: `12 Nov 2026 • 3:04 PM`), `Status` colored text (`Completed` success / `Cancelled` error / `Active` info / `Upcoming` warning), conditional `Your rating` (5 stars 16px); (2) `Route`: `Pickup` / `Destination` labels + values; (3) `Fare breakdown`: `Base fare`, `Distance fare ({km} km)`, `Platform fee`, divider, `Total` (bold), `Payment` (`Cash`/`UPI`); (4) driver card: avatar, `driver.name`, `vehicleName`, `vehicleNumber`, star + `driver.rating`.
- States: none (static). AppBar `Ride details` with back. Simulated: none.

### 3.5 Account, support and safety

**`/profile` - Account hub** - `features/account/presentation/profile_screen.dart`
- AppBar title **`Account`** + edit action (pencil -> `/edit-profile`). Header block (surface): 80px yellowLight avatar showing `profile.name[0].toUpperCase()` or person icon; name (or `Set up profile`); phone (raw e.g. `+919000000001`) or `—`; email when present.
- Menu sections (labelMedium grey500 headers, surface list, 36px grey100 icon chips, chevron, 68px indent dividers): **Rides** = `My rides`, `Saved places`; **Payments** = `Payment methods`; **Help** = `Help & Support`, `Notifications`; **App** = `Settings`, `About E-GO`.
- Footer: secondary **`Log out`** (logout icon) -> dialog `Log out?` / `Are you sure you want to log out?` / `Cancel` / `Log out` (error) -> `logout()` -> `pushNamedAndRemoveUntil(/login)`; grey wordmark + `Move your way - Jhargram` tagline.

**`/edit-profile`** - `edit_profile_screen.dart`
- AppBar `Edit profile` + `Save` TextButton; 90px yellowLight avatar (decorative); fields `Full name *` (ph `Enter your full name`, errors `Name is required` / `Name too short`) and `Email (optional)` (ph `Enter your email`, error `Enter a valid email`, same regex as profile setup); CTA `Save changes` (loading state).
- Save -> `updateProfile(name, email?)` -> snackbar `Profile updated` -> pop. Simulated: in-memory account update (session must exist; repo throws `No active session. Please log in again.` otherwise).

**`/payment-methods`** - `payment_methods_screen.dart`
- AppBar `Payment methods`; label `Preferred payment`. Two selectable cards (`_PaymentOptionCard`, r12; selected = 2px `brandPrimaryBorder` + glow + `check_circle`, else `radio_button_unchecked` grey):
  1. `Cash` / `Pay directly to your rider or toto driver` / money icon (success) / badge `Active` (successLight) -> `setPaymentMethod(cash)` + snackbar `Payment set to Cash`.
  2. `UPI (GPay, PhonePe, Paytm)` / `Pay via UPI QR code upon arrival` / `qr_code_2` icon / badge `Demo Mode` (yellowLight) -> `setPaymentMethod(upi)` + snackbar `Payment set to UPI (Simulated)`.
- Notice card (warningLight, warning border): title `Payment Notice`, body `In this preview release of E-GO, payments are simulated. No real monetary transactions or banking APIs are connected.`
- Bottom CTA `Done` -> pop. **Web A9 diverges: UPI not selectable, shown as coming soon (§7 G6).**

**`/notifications`** - `features/notifications/presentation/notifications_screen.dart`
- AppBar `Notifications` + conditional `Mark all read` -> snackbar `All notifications marked as read`. Empty -> `EGoEmptyState` `No notifications` / `We'll notify you about your rides and offers here.`
- List cards (r12): unread = yellowLight 50% fill + yellow 30% border + yellow icon circle + 8px yellow dot + title w700; read = surface + grey border + grey icon circle. Content: circular icon, title, body, `_timeAgo` (`{n}m ago` / `{n}h ago` / `{n}d ago`). Tap -> `markNotificationRead(id)`.
- Seeds (2): `Welcome to E-GO! 👋` / `Book your first ride and move your way.` (1h ago, waving_hand); `E-GO is now in Jhargram` / `Book bike and Toto rides across Jhargram anytime.` (2h ago, location_on). In-memory only.

**`/settings`** - `features/account/presentation/settings_screen.dart`
- AppBar `Settings`; sections in bordered surface cards (r12):
  - **Preferences**: `App Language` (subtitle current) -> bottom sheet `Choose Language` with `English` and `বাংলা (Bengali)` rows + check; selection is **local state only, not persisted**.
  - **Notifications**: switches (active thumb navy / track yellow): `Ride Status Alerts` (`Notifications when driver arrives or begins trip`, default on), `SMS Updates` (`Receive important ride notifications via SMS`, default on), `Offers & Discounts` (`Special discounts and coupons for Jhargram rides`, default off).
  - **Privacy & Legal**: `Privacy Policy` -> snackbar `E-GO Privacy Policy (Demo)`; `Terms of Service` -> snackbar `E-GO Terms of Service (Demo)` (both with `open_in_new` icon).
  - Logout: red outlined button `Log out` -> dialog `Log out?` / `Are you sure you want to log out of E-GO?` / `Cancel` / `Log Out` -> `logout()` -> `/login`.
- All toggles are ephemeral (component state). Simulated: yes.

**`/help-support`** - `features/support/presentation/help_support_screen.dart` (public in Flutter, protected in web - A3)
- AppBar `Help & Support`. Gradient quick-support card (yellow -> yellowDark): `support_agent` icon + `E-GO Support Team` (18px w700), body `We are here to assist with your rides, safety, and payments in Jhargram.`, secondary button **`Report an issue`** (h40) -> dialog `Report an Issue` / `Describe your concern or feedback regarding your ride experience in Jhargram:` / 4-line field hint `e.g. Driver requested excess cash, app map issue, etc.` / `Cancel` + `Submit` (submit disabled until non-empty) -> snackbar `Issue report submitted! Our support team will review it.`
- `Frequently Asked Questions` (20px) -> accordion list from `MockData.faqs` (7 items, ExpansionTile, navy chevrons).
- Emergency card: `Emergency & Safety` / `Your safety is our highest priority during every ride.` + red outlined **`Emergency SOS (Mock)`** -> snackbar `Emergency alert triggered (Simulated in demo)`.

**`/safety` - Safety** - `features/safety/presentation/screens/safety_screen.dart` (**unrouted in Flutter**; web routes it - A3/A14)
- AppBar title is the copy bug **`Help & Support`** (line 23) - web must use `Safety` (§7 G1). Optional `EGoBottomNavBar(selectedIndex: 2)` when `showBottomNav`.
- Emergency SOS card (surface, r20): red-tinted shield circle, `Emergency SOS` (Poppins 18), `Instant alert to contacts & Jhargram Police`, full-width red button **`TRIGGER EMERGENCY SOS`** (48px, r12, ls 0.6) -> snackbar `Emergency SOS triggered (Demo Simulation). Contacts notified.`
- `Ride Safety Guidelines` - 3 cards (16px padding, r16, yellowLight icon chip): `Verified TOTO Drivers` ("Every E-GO driver in Jhargram is registered and police-verified with visible registration badges."), `Share Live Ride Status` ("Share your live route and estimated arrival time with friends and family with a single tap."), `24/7 Local Assistance` ("Our local Jhargram transit desk is always reachable for lost items, fare inquiries, and route questions.")
- `Frequently Asked Questions` - same `MockData.faqs` accordions (14px titles).

**`/about` - About E-GO** - `features/account/presentation/about_screen.dart` (public in Flutter, protected in web - A3)
- AppBar `About E-GO`; centered `EgoLogo(primary, height 96)`; tagline `Move your way.` (16 w600); pill `v0.1.0-alpha • Jhargram, WB`.
- Cards: `Our mission` = `E-GO is built specifically for Jhargram - connecting passengers with local Toto (E-Rickshaw) and Bike drivers through simple, transparent, and fair pricing. No hidden surge, no complicated apps.`; `Operating region` = bullet list: `Jhargram Railway Station & Bus Terminus`, `Jhargram Rajbari & Palace Grounds`, `Jhargram Super Speciality Hospital`, `Jhargram DM Office & Court Complex`, `Ghoradhara & Jamda Localities`.
- `Vehicle categories`: `Toto (E-Rickshaw)` - "Electric, eco-friendly 3-wheelers. Up to 4 passengers with light luggage."; `Bike Ride` - "Fast single-passenger motorbike rides for quick trips across town." (note: says 4 passengers vs vehicle card capacity 3 - §7).
- Footer: `© 2026 E-GO. All rights reserved.` / `Made for the people of Jhargram.`

### 3.6 Data layer (mock)

**`mock_data/mock_data.dart`** (all static consts, Jhargram, WB)
- `jhargramCenter = (22.4529, 86.9003)`; `mockCurrentLocation = (22.4550, 86.9020)`.
- `recentDestinations` (4): `Jhargram Bazar`/Market area (22.4701, 86.9152, store, market); `Jhargram Railway Station`/Station Road (22.4529, 86.9003, train, transport); `Jhargram Palace`/Tourist spot (22.4480, 86.8950, account_balance, landmark); `Kendua Market`/Local market (22.4650, 86.9100, shopping_basket, market).
- `suggestedPlaces` (12): the 4 above + `Jhargram Medical College`/Khasjangal, Jhargram (22.4400, 86.8800, hospital); `Jhargram Bus Stand`/Bus Stand Road (22.4580, 86.9050, transport); `Jhargram College`/College Road (22.4610, 86.9120, education); `Belpahari`/NH-6, Jhargram district (22.5200, 86.9500); `Lodhasuli` (22.4350, 86.8700, residential); `Binpur` (22.5600, 87.0200); `Sankrail` (22.4150, 86.8600); `Jamboni` (22.5000, 86.9800).
- `homePlace`/`workPlace` placeholders (`Add home address` / `Add work address`) - **unused by any screen** (§7).
- `faqs` (7): `How do I book a ride?`; `How is the fare calculated?` (answer: `Fares are based on distance and vehicle type. Bike rides start at ₹20 + ₹10/km. Toto rides start at ₹15 + ₹7/km. A small platform fee applies.`); `Can I cancel a ride?`; `What payment methods are accepted?` (`Currently cash is accepted. UPI and card payments will be available soon.` - basis for web A9); `How do I contact my driver?`; `What is a Toto?` (up to 3 passengers); `Is E-GO available 24/7?` (`E-GO operates from 6:00 AM to 10:00 PM.`).

**`features/booking/data/*`**
- `booking_repository.dart`: `RideStatus {upcoming, active, completed, cancelled}`; `PaymentMethod {cash, upi}`; `RideRecord` fields (id, pickup/destination `SavedLocation`, `vehicleType`, `fareBreakdown`, `driver`, `status`, `bookedAt`, `completedAt?`, `rating?`, `ratingComment?`, `paymentMethod = cash`, `tripId?`) + `vehicleName` getter + `copyWith`. `MockBookingRepository`: in-memory `List`, `getAllRides()` unmodifiable, `getCompletedRides()`, `getCancelledRides()`, `getRideById(id)` (returns null on miss), `addRide` inserts at index 0, `updateRide` replaces by id, `generateId()` = `EGO-{ms}`; **`_seedRides = []` (no seeded history)**.
- `vehicle_repository.dart`: `VehicleOption` (type, name, subtitle, capacity, iconData, fareBreakdown, isAvailable); `getAvailableVehicles` waits 400ms then returns exactly 2 options: `Bike` / `Fast & affordable` / cap 1 / `Icons.two_wheeler`; `Toto` / `E-Rickshaw - Up to 3 passengers` / cap 3 / `Icons.electric_rickshaw` - fares computed per route.
- `driver_repository.dart`: `MockDriver` (id, name, rating, totalRides, vehicleNumber, vehicleName, vehicleColor, avatarIcon). Both fetchers wait **2 s** then return fixed demos: bike = `driver-001` `Rajan Kumar` 4.8 / 324 rides / `WB 32 D 1234` / `Hero Splendor` / `Black`; toto = `driver-002` `Suresh Das` 4.6 / 211 rides / `WB 32 E 5678` / `E-Rickshaw` / `Green`.

**`features/location/data|domain/*`**
- `LocationRepository`: `searchPlaces(query)` waits 300ms; empty query -> all 12 `suggestedPlaces`; else case-insensitive `contains` on name or address; `getRecentDestinations()` waits 100ms -> 4 seeds; `getCurrentLocation()` waits 500ms -> `MockData.mockCurrentLocation` (never null, never errors); `saveRecentDestination()` is a **TODO no-op** (50ms delay) - recents never actually grow.
- `location_model.dart`: `LocationSearchResult` (id, name, address, coordinate, type); `PlaceType` enum (7 values); `SavedLocation` (id, label, subtitle?, coordinate, icon?, type, createdAt?); `CurrentLocationState` (unused elsewhere - dead model, §7).

**`features/notifications/data/notification_repository.dart`**
- `AppNotification` (id, title, body, createdAt, iconData, isRead, type); `NotificationType {info, booking, promo, system}` (only `info` used); `MockNotificationRepository`: 2 seeds (see §3.5), `markRead(id)` (has `orElse: first` fallback), `markAllRead()`, `clearAll()` (never called by UI), `unreadCount`. In-memory only.

### 3.7 Shared widget conventions (`lib/shared/widgets/`)

- `buttons.dart`: `EGoPrimaryButton` - Material `FilledButton`, full-width by default (`isFullWidth`+`expanded`), height default `EGoSpacing.buttonHeight` (48), label style `labelLarge` w700 with `onPrimary` (= navy on yellow), optional leading icon (8px gap), `isLoading` swaps content for 24px spinner and disables press. `EGoSecondaryButton` - `OutlinedButton`, same geometry, label w600 `onSurface`. `EGoTextButton` (min 64x48), `EGoIconButton` (circular, radiusRound, elevation1 default), `EGoFloatingActionButton` (mini/extended variants).
- `inputs.dart`: `EGoLocationInput` (label titleSmall + filled field, prefix/suffix slots, readOnly by default, errorText); `EGoSearchInput` (filled `surface`, default search prefix icon, clear suffix only when text present, `autofocus`, onChanged/onClear/onFieldSubmitted) - used by destination screen; `EGoRecentDestinationChip` (r12 card, label+subtitle, optional icon/check, selected state = yellowLight + brand border 1.5).
- `common.dart`: `EGoSectionHeader` (titleMedium + optional TextButton action); `EGoLabeledDivider`; `EGoEmptyState` (centered, 64px icon in `onSurfaceMuted`, titleLarge, subtitle bodyMedium, optional non-full-width primary action) - the single empty-state primitive; `EGoLoadingOverlay` (navy 30% scrim + white card + yellow spinner + optional message); `EGoBanner` (infoLight default, optional action + dismiss).
- `bottom_nav_bar.dart`: `EGoBottomNavBar` - 4 tabs `Home`, `Rides` (EgoLogo icon instead of glyph), `Safety`, `Profile` (param `profileLabel`, default `Profile`); selected tab = yellow pill (`brandPrimary`, radiusRound) with navy icon/label (w700 11px `navigationLabel`); container: surface, top divider, shadow (0,-4,16); optional 128px gesture-indicator bar (`showGestureIndicator`).
- `location_components.dart`: `EGoCurrentLocationButton` (white circular, my_location, yellow when active), `EGoMapZoomControls` (+/- stacked white circles), `EGoPickupMarker` (3-ring yellow target), `EGoDestinationMarker` (CustomPaint teardrop yellow + white center + shadow), `EGoCurrentLocationMarker` (yellow core + white center), `EGoAnimatedCurrentLocationMarker` (1500ms expanding/fading pulse ring) - web Leaflet equivalents should mirror these visuals (plan A2/A13).
- Auth widgets (`features/auth/presentation/widgets/`): `AuthPasswordField` - label 11px w700 ls 0.8, 56px box r16, lock icon, obscured by default with eye toggle `Key('password_visibility_toggle')` (semantics `Show password`/`Hide password`), focus = navy 2px + yellow halo (blur 0, spread 3), error = `errorLight` + 2px error border + inline icon+text row, `enableSuggestions:false`, `autocorrect:false`. (Sibling `AuthTextField`, `AuthPhoneField` follow the same 56px/r16 pattern - structure inferred from call sites; full bodies UNVERIFIED.)

## 4. Design system and web token comparison

### 4.1 Flutter official tokens (baseline)

- Colors: brand yellow `#FFC928`, app background `#F5F7FA`, navy `#142B45`, white surfaces.
- Type: Poppins for display/headings, Inter for body copy.
- Spacing: 4px scale. Radii: 4 / 8 / 12 / 16 / 24 / 9999.
- Controls: buttons 48px (default) and 56px (large/auth CTAs); inputs 48px (auth fields 56px, §3.1/§3.7).

### 4.2 Web tokens vs Flutter (`E-go-web/src/app/globals.css`)

Web Tailwind 4 theme tokens match the Flutter brand/surface/navy colors and the Poppins/Intering pairing. The differences below are **accepted web adaptations, not conflicts**:

| Area | Flutter | Web | Verdict |
|---|---|---|---|
| Muted text | navy with alpha | solid `#5B6B7C` | accepted (predictable contrast on white) |
| Focus indication | yellow halo (`#33FFC928`) | navy focus ring | accepted (visible on yellow surfaces) |
| Success | semantic green family | `#059669` | accepted (single web token) |
| Extras | - | `brand-strong` / `brand-soft` / `brand-muted`, `warning` / `info` tones, elevation shadows | web-only additions |

### 4.3 Usage rules (binding for all web screens)

1. Navy (`#142B45`) text on yellow buttons - **never white on yellow**.
2. Cards use 16px radius; pills/chips use radius 9999.
3. Buttons: 48px default, 56px for large/auth CTAs; inputs 48px (auth phone/password 56px).
4. Minimum touch target 44x44px on every interactive element.
5. Tokens are frozen after Batch 2 (plan section 3) - screens consume tokens, never raw hex.

## 5. Business logic (verified)

### 5.1 Phone normalization

- Strip all non-digits from input.
- 12 digits starting `91` -> drop the first 2; 11 digits starting `0` -> drop the first 1.
- After normalization the number must match `^[6-9]\d{9}$`.
- Stored as E.164 `+91XXXXXXXXXX`.

### 5.2 Password

- Registration requires >= 8 characters and must not be whitespace-only.
- The mock stores only a salted PBKDF2-SHA-256 hash - a stronger deviation from the Flutter A6 salted SHA-256 design (web decision).

### 5.3 OTP

- 6 digits; demo code `123456`; 30s resend cooldown; 10 minute expiry; max 5 attempts.
- Web decision D3: the demo OTP is accepted for an existing account even after a page refresh.
- An unknown phone may request an OTP only after an account exists (no account enumeration via OTP request).

### 5.4 Demo account and gate

- Phone `9000000001` / password `EgoDemo@123` / name `E-GO Demo User` / email `demo@ego.local`.
- Demo gate: `NEXT_PUBLIC_ENABLE_DEMO_AUTH=true` AND `NODE_ENV != production`.

### 5.5 Session

- Mock opaque token with 7-day TTL, persisted client-side.
- The onboarding-completion flag is persisted separately from the session.

### 5.6 Booking FSM (16 states)

States: `idle`, `selectingPickup`, `selectingDestination`, `selectingVehicle`, `reviewingFare`, `confirmingBooking`, `searchingDriver`, `driverAssigned`, `driverArriving`, `driverArrived`, `tripInProgress`, `tripCompleted`, `awaitingRating`, `rated`, `cancelled`, `failed`.

Verified transition table:

| From | To | Trigger | Flutter | Web (A8, deadline-based) |
|---|---|---|---|---|
| idle | selectingPickup / selectingDestination | user starts booking | - | - |
| selectingDestination | selectingVehicle | proceedToVehicleSelection | - | - |
| selectingVehicle | reviewingFare | proceedToFareReview | - | - |
| reviewingFare | confirmingBooking | proceedToConfirmation | - | - |
| confirmingBooking | searchingDriver | confirm booking | 4s | 6s |
| searchingDriver | driverAssigned | mock match | 2s | 4s |
| searchingDriver | failed | search watchdog | 12s | deadline-based |
| failed | searchingDriver | Retry (web fix) | dead self-transition, §7 G8 | new deadline scheduled |
| driverAssigned | driverArriving | timer / Track driver | 3s | 12s |
| driverArriving | driverArrived | timer / tracking progress | 12s | tracking progress |
| driverArrived | tripInProgress | auto-start | 40s | 30s auto-start |
| tripInProgress | tripCompleted | progress at 100% | 15s | 15s |
| tripCompleted | awaitingRating | auto | 500ms | 0.5s |
| awaitingRating | rated / idle | submit rating / skip | - | - |
| any active state | cancelled | user cancel | 300ms | 300ms |

All web FSM timings are deadline-based (single scheduler), approved as A8.

### 5.7 Fare calculation (verified)

- Distance: haversine on lat/lng with R = 6371 km; effective distance = max(0.5, km) (0.5 km minimum billable).
- Money is integer rupees throughout (no paise).
- **Bike**: base 20 + round(km x 10) + platform fee 3; trip ETA = round(km/20 x 60 + 3).clamp(2, 60) minutes; arrival 3 minutes.
- **Toto**: base 15 + round(km x 7) + platform fee 2; trip ETA = round(km/12 x 60 + 5).clamp(3, 90) minutes; arrival 5 minutes.

### 5.8 Mock data and seeds

- Jhargram center (22.4529, 86.9003); mock current location (22.455, 86.902).
- Exactly 2 vehicles: Bike and Toto (§3.6).
- Flutter seeds no ride history; the web seeds 3 demo rides (2 completed, one of them unrated, plus 1 cancelled) per A7.

### 5.9 Ride history lifecycle

- A ride record is created on booking confirm and updated on every FSM transition.
- Terminal records (completed / cancelled) are listed in descending order.
- The rating is stored on the ride record.

### 5.10 Dead code: retrySearch

- Flutter `retrySearch()` is a self-transition failed -> failed - dead, it never leaves `failed` (§7 G8).
- The web retry must transition failed -> `searchingDriver` and schedule a new deadline.


## 6. Mock-vs-real matrix and required labels

Every simulated surface must show the demo banner **"Demo simulation - no real driver is assigned."** and honest **"Simulated in demo"** labels. No claim of real SMS, payments, dispatch, or GPS may appear anywhere (plan section 5).

| Surface | Real product would | E-GO demo does | Required label |
|---|---|---|---|
| SMS / OTP delivery | send an SMS via a gateway | fixed code `123456`, no SMS sent | `Simulated in demo` + demo OTP hint |
| Password hashing | server-side hashing | local salted PBKDF2-SHA-256 in mock storage | local-only, no server |
| Driver dispatch | match with real drivers | timer-driven assignment | demo banner |
| Driver identity | real driver profiles | seeded Rajan Kumar / Suresh Das | `Demo driver - not a real person` |
| GPS / location | device GPS | fixed mock coordinates in Jhargram | `Simulated in demo` |
| Route and tracking | road network, live ETA | dashed straight line, timer progress | route marked approximate / simulated |
| Calls and messages | telephony | toast only | `(demo)` |
| Payments | PSP / UPI processing | cash only, no money movement | Payment Notice: no real transactions |
| Notifications | push / SMS | local in-memory only | `Simulated in demo` |
| Support and SOS | human agents / emergency services | toast only | `(Mock)` / `(Simulated in demo)` |

## 7. Gaps, inconsistencies and dead code (Flutter -> web decision)

| # | Flutter finding | Web decision |
|---|---|---|
| G1 | Safety screen unrouted; AppBar copy bug reads `Help & Support` | Route `/safety` (A14) with correct `Safety` title |
| G2 | Login subcopy mentions SMS though login is password-based | Copy corrected to password login |
| G3 | `/help-support` and `/about` unprotected | Protected inside the app shell (A3) |
| G4 | Mock registration/OTP marks profile complete -> `/profile-setup` bypassed | `/profile-setup` kept in the flow (A5/D11) |
| G5 | Bottom-nav `Safety` tab opens help-support | Tabs bind to their real routes (A14) |
| G6 | Trip-completed hardcodes `Cash`; UPI shown selectable though payments are simulated | Show the selected method; cash-only, UPI coming soon (A9) |
| G7 | Saved places non-persistent (lost on route exit) | Persist per user |
| G8 | `retrySearch()` self-transition failed -> failed deadlocks retry | failed -> `searchingDriver` plus a new deadline |
| G9 | Ride Details unsafe cast when argument missing (throws on refresh) | `/ride-details/[id]` + `getRideById` (A11) |
| G10 | `Shared` ride filter always empty (unsupported) | Filter omitted (A10) |
| G11 | About capacity copy says 4 passengers vs vehicle capacity 3 | Capacity 3 (toto) and 1 (bike) everywhere |
| G12 | Dead/duplicate files: legacy auth onboarding, legacy phone login, `my_rides` re-export | Not ported |


## 8. Final screen build checklist

Routes per `docs/web/ego_web_implementation_plan.md` section 4: 8 public + 1 alias + 22 protected = 31. Key components reference the section 3 specs.

| Route | Key components (§3) | Primary actions | Acceptance criteria |
|---|---|---|---|
| `/` | splash gate | auto-redirect | routes by session/onboarding flag; no flash of wrong screen |
| `/onboarding` | wordmark, hero, progress, Skip | Get started, Skip | exact copy §3.1; Skip persists the flag |
| `/onboarding-2` | step-2 layout, hero, Skip | Next, Skip | exact copy; identical geometry |
| `/onboarding-3` | step-3 layout, hero, Skip | Next, Skip | completes flag -> `/login` |
| `/login` | phone field, password, Help pill, error box | Continue, Create account | demo login works; errors §3.1; returnTo honored |
| `/create-account` (alias `/register`) | 4 fields, validators, legal line | Create account, Log in link | phone/password validation; alias resolves; no session pre-OTP |
| `/otp` | 6 digit boxes, demo hint, resend row | Verify, Resend | `123456`; 30s cooldown; 5 attempts; 10min expiry; D3 after refresh |
| `/profile-setup` | avatar, name, email | Start riding | reached after register (A5/D11); validation §3.1 |
| `/home` | map, booking panel, bottom nav | choose destination, Change pickup, CTA | FSM idle; CTA label CHOOSE LOCATION / SELECT VEHICLE; tabs bind correctly |
| `/pickup-selection` | Leaflet map, center pin, address card | drag/search, Confirm pickup location | sets pickup; coordinate subtitle on drag |
| `/destination-selection` | search input, recents, suggested list | select place | 300ms loading; empty state §3.2 |
| `/saved-places` | 3 seed cards, add dialog | add, delete, Add a new place | persists per user (G7); empty state |
| `/vehicle-selection` | route summary, 2 vehicle cards, fare tray | select vehicle, Continue | 400ms loading; first option auto-selected |
| `/fare-details` | route card, fare rows, payment row | Confirm vehicle, Change payment | demo fare banner; no-vehicle guard |
| `/booking-confirmation` | summary cards, warning banner | Confirm booking | push `/searching-driver` first, then confirm (§3.3) |
| `/searching-driver` | pulse circle, route card, failure UI | Cancel search, Retry | A8 deadlines 6s/4s; watchdog; retry works (G8) |
| `/driver-assigned` | status card, driver card, route card | Track driver, cancel, call/chat demo | 12s auto-advance; `Demo driver` strip |
| `/ride-tracking` | Leaflet markers, progress sheet | call/chat toasts | status pill + progress; dashed simulated route |
| `/trip-completed` | success circle, fare box, summary | Rate your ride, Done | shows selected payment method (G6) |
| `/ride-rating` | stars, chips, comment field | Submit rating, Skip | 0-star error; rating stored on ride |
| `/my-rides` | header, filter tabs, ride cards | filter, open details, Book TOTO | 3 seeded rides (A7); no Shared filter (A10); empty state |
| `/ride-details/[id]` | status, route, fare, driver cards | back | deep-link/refresh safe (A11); rating shown |
| `/profile` | avatar header, menu sections, logout | navigate sections, Log out | sections §3.5; logout -> `/login` |
| `/edit-profile` | name/email fields, Save | Save changes | validation; `Profile updated` feedback |
| `/payment-methods` | cash card, UPI (coming soon), notice | select Cash | cash-only (A9); payment notice shown |
| `/notifications` | list, unread styling, Mark all read | mark read | seeds §3.5; empty state |
| `/help-support` | support card, FAQ accordion, SOS | Report an issue, Emergency SOS (mock) | protected (A3); simulated labels |
| `/settings` | language row, switches, legal, logout | toggle, Log out | ephemeral toggles; logout dialog |
| `/about` | logo, mission, region, vehicle categories | - | protected (A3); capacity 3 / 1 (G11) |
| `/safety` | SOS card, safety guidelines, FAQ | Trigger Emergency SOS (mock) | routed (A14); title `Safety` |

