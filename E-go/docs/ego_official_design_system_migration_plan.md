# E-GO Official Design System Migration Plan

**Project:** E-GO customer application (`D:\E-RICKSHAW RIDE\E-go`)  
**Platform:** Existing Flutter web project only  
**Status:** Planning draft — implementation blocked by visual-reference intake and explicit approval  
**Date:** 2026-11-15

---

## 1. Executive Summary

This document defines the migration of the existing E-GO Flutter web customer app to the official E-GO brand system:

- Yellow: `#FFC928`
- Background: `#F5F7FA`
- Navy: `#142B45`

The migration is a **visual-system migration, not an application rewrite**. It must preserve the existing booking state machine, mock authentication, onboarding completion, route protection, navigation behaviour, local persistence, and current screen layouts.

The app currently has **104 Dart files**, **19 test files**, and **12 visual screenshot artifacts**. It already contains a substantial token system, but it is split across competing sources:

- `lib/app/theme/*`
- `lib/core/branding/*`
- Screen-local palettes in home, authentication, onboarding, rides, and safety.

The official palette is not currently present in `lib/`. Current values use `#F5C928` / `#FCD030` for yellow, `#FAFAF7` / `#FAF9F5` for backgrounds, and `#171717` for primary text.

The original `E-GO E-Rickshaw App UI Showcase(1).png` reference image is **not present in the workspace**. No screen-level visual decision in this document is final until that image is supplied, inspected, and recorded in the visual-reference gate in Section 3.

No application source code, assets, fonts, routes, dependencies, or platform configuration has been modified while preparing this plan.

---

## 2. Scope, Constraints, and Non-Goals

### 2.1 In scope

- The customer app at `D:\E-RICKSHAW RIDE\E-go` only.
- Existing Flutter web target.
- Brand palette, typography, component styling, and screen-level visual migration.
- Consolidation of the competing theme and branding token sources.
- Local bundling of Poppins and Inter fonts.
- Web shell titles, descriptions, manifest colours, and visual metadata.
- Visual QA, screenshot regeneration, analysis, and regression tests.
- Planning documentation and phase reports.

### 2.2 Out of scope

- Android or iOS platform folders, platform configuration, or mobile packaging.
- `E-go-rider`, `E-go-admin`, `backend`, `packages`, `infrastructure`, `rapido-analysis`, `toto-go-blueprint`, or workspace-level docs.
- Navigation redesign, new screens, route changes, or screen-flow changes.
- Booking, authentication, repository, pricing, or persistence logic changes.
- Replacing the Flutter or provider architecture.
- Changing PWA icon artwork unless an approved official asset is available.

### 2.3 Hard constraints

1. Official palette values must be exact:
   - Yellow `#FFC928`
   - Background `#F5F7FA`
   - Navy `#142B45`
2. Semantic colours for success, warning, error, and information must remain functional.
3. The 70/20/10 colour ratio is an **overall brand guideline**, not a per-screen quota.
4. Consume the token system through one clear source of truth after consolidation.
5. Preserve onboarding geometry and every existing coordinate-based test.
6. Preserve mock authentication, OTP testing, registration, onboarding completion, profile setup, booking transitions, vehicle selection, navigation, map interaction, local persistence, and existing behavioural tests.
7. Do not change working functionality for visual convenience.
8. Run visual QA and regression tests after every phase.
9. Do not begin implementation until the visual-reference gate and this plan are approved.

---

## 3. Visual Reference Gate

### 3.1 Required reference

The user will provide:

`E-GO E-Rickshaw App UI Showcase(1).png`

At the time of this plan it is not present anywhere in `D:\E-RICKSHAW RIDE`; `**/*Showcase*` and `**/*showcase*` searches return no files.

### 3.2 Gate R — reference intake and annotation

Before any screen-level visual work:

1. Add the original image to the workspace without modifying it.
2. Inspect the full image and record its native dimensions.
3. Map every depicted screen to the existing route inventory in Section 6.
4. Record, per screen:
   - Background and surface treatment
   - Yellow usage and placement
   - Navy usage and placement
   - Typography family, weight, size, and line height
   - Spacing, radii, borders, shadows, and control heights
   - App-bar and bottom-navigation treatment
   - Logo variant and placement
   - Map and illustration treatment
   - Semantic colour usage
5. Update the provisional decisions in this document.
6. Re-approve the visual plan.

### 3.3 Provisional status

Until Gate R is complete:

- Palette, typography, and architectural decisions in this document are final.
- Screen-level composition, component sizing, radii, and visual hierarchy decisions are **provisional**.
- The existing layouts remain the structural baseline.
- No source code should be restyled.

---

## 4. Current Architecture Audit

### 4.1 Application structure

- Entry point: `lib/main.dart`
- App and theme wiring: `lib/app/app.dart`
- Route table and guards: `lib/app/router.dart`
- Global state: `lib/app/app_state.dart` (`ChangeNotifier`)
- Booking state machine: `lib/core/booking_state.dart`
- Branding: `lib/core/branding/*`
- Theme: `lib/app/theme/*`
- Features: `account`, `auth`, `booking`, `home`, `location`, `notifications`, `onboarding`, `rides`, `safety`, `support`
- Shared widgets: `lib/shared/widgets/*`
- Mock data and pricing: `lib/mock_data/mock_data.dart`, `lib/core/mock_pricing.dart`

### 4.2 State and behaviour

- Provider `ChangeNotifier` state in `AppState`.
- Mock repositories for authentication, vehicles, drivers, bookings, notifications, and locations.
- `AUTH_MODE=mock` is the development default; mock OTP is `123456`.
- Booking status transitions are validated in `lib/core/booking_state.dart`.
- Onboarding completion is persisted under `ego_onboarding_complete`.
- Route protection is applied in `EGoRouter.generateRoute` through the `isAuthenticated` callback passed from `lib/app/app.dart`.

These behaviours are regression-critical and must not be altered by the visual migration.

### 4.3 Platform and tooling

- `.metadata` declares only `root` and `web` platforms.
- No `android/` or `ios/` directories exist.
- Dependencies: `flutter_map`, `latlong2`, `provider`, `shared_preferences`.
- Flutter SDK path is referenced explicitly in one screenshot test:
  `E:\flutter_windows_3.41.6-stable\flutter\bin\cache\artifacts\material_fonts\materialicons-regular.otf`.

### 4.4 Documentation baseline

- `docs/ego_mock_auth_testing_guide.md`
- `docs/ego_onboarding_consistency_report.md`
- `docs/ego_phone_login_integration_report.md`

The reports describe historical test counts and visual states. They are context, not proof of the current test state. Phase 0 must establish a fresh baseline.

---

## 5. Current Design-System Audit

### 5.1 Competing token sources

| Source | Current role | Problem |
|---|---|---|
| `lib/core/branding/ego_brand_colors.dart` | Raw brand palette | Uses old yellow `#F5C928`; no navy; no official background |
| `lib/app/theme/colors.dart` | Material/semantic aliases | Duplicates raw values and contains legacy “green” token names |
| `lib/app/theme/typography.dart` | Text styles | Declares `Roboto`, which is not bundled |
| `lib/core/branding/ego_brand_theme.dart` | Button and card helpers | Duplicates styles already provided by the theme |
| `lib/features/onboarding/presentation/theme/onboarding_constants.dart` | Onboarding palette, font, and geometry | Mixes fixed geometry with local colours and font family |
| `lib/features/auth/presentation/screens/phone_login_screen.dart` | Auth palette | Local constants including `#FAF9F5`, `#FCD030`, `#D93829` |
| `lib/features/auth/presentation/screens/create_account_screen.dart` | Auth palette and typography | Raw colours and `Manrope` literals |
| `lib/features/auth/presentation/widgets/auth_*.dart` | Auth field styling | Duplicated border, focus, error, and hint colours |
| `lib/features/home/presentation/home_screen.dart` | Home palette | Local `_k*` constants duplicate brand and neutral values |
| `lib/features/safety/presentation/screens/safety_screen.dart` | Safety palette and typography | Old green palette and hardcoded `Manrope` |
| `lib/features/rides/presentation/widgets/*` | Ride cards, tabs, headers | Hardcoded `Manrope` and raw status colours |
| `lib/shared/widgets/bottom_nav_bar.dart` | Navigation | Hardcoded `Manrope` |

### 5.2 Current palette

| Token | Current value | Official target |
|---|---|---|
| Brand yellow | `#F5C928` | `#FFC928` |
| Auth/onboarding CTA | `#FCD030` | `#FFC928` |
| Page background | `#FAFAF7` | `#F5F7FA` |
| Auth/onboarding background | `#FAF9F5` | `#F5F7FA` |
| Primary text / black | `#171717` | `#142B45` |
| Secondary text | `#6B7280`, `#444748`, `#747878`, `#65716B` | Navy-derived muted tones |
| Borders/dividers | `#E7E7E2`, `#E5E5E5`, `#EBEBEB`, `#E3E8E3` | Navy-derived borders |
| Input/disabled surfaces | `#F5F5F0`, `#F3F4F6`, `#EBEBE6` | Light background or navy-derived surfaces |
| Error | `#DC2626` and `#D93829` | Single semantic error token |
| Success | `#059669` and `#1B8755` | Single semantic success token |
| Warning | `#D97706` | Preserve |
| Information | `#0284C7` | Preserve |
| Rating accent | `#FBBC04` | Provisional: brand yellow or approved reference value |
| Map greens | Functional cartography | Preserve as functional exception, subject to reference review |

The official colors `#FFC928`, `#F5F7FA`, and `#142B45` do not currently appear in `lib/`.

### 5.3 Current typography

- `pubspec.yaml` bundles only Manrope:
  - `assets/fonts/manrope-regular.ttf` (400)
  - `assets/fonts/manrope-bold.ttf` (700)
  - `assets/fonts/manrope-extrabold.ttf` (800)
- `lib/app/theme/typography.dart` declares `fontFamilyPrimary = 'Roboto'` and `fontFamilyNumbers = 'Roboto'`.
- `web/index.html` loads Manrope from Google Fonts.
- Auth widgets and screens, onboarding constants, rides widgets, safety, and bottom navigation hardcode `Manrope`.
- No Inter or Poppins font files exist in the repository.

### 5.4 Current web shell

- `web/index.html` title and PWA name are `e_go`.
- Description is `A new Flutter project.`
- `web/manifest.json` uses default `#0175C2` theme and background colours.
- PWA icons and favicon are the default Flutter assets.
- `web/index.html` contains a Google Fonts link for Manrope.

### 5.5 Functional visual exceptions

The following should not be blindly converted to brand colors:

- `lib/features/home/presentation/widgets/home_map_painter.dart`: cartographic land, road, railway, and label colours.
- Map route polyline, vehicle, and status colors where they communicate state.
- Semantic success, warning, error, and information colors.
- System overlays and platform status-bar behavior on the web.

Any exception must be named, documented in code, and reviewed during visual QA.

---

## 6. Full Route and Screen Inventory

All paths below are relative to `E-go/`.

| # | Surface | Route / entry | Implementation file | Notes |
|---|---|---|---|---|
| 1 | Splash | `/` | `lib/features/auth/presentation/splash_screen.dart` | Animated logo; full-yellow background; routes by auth and onboarding state |
| 2 | Onboarding 1 | `/onboarding` | `lib/features/onboarding/presentation/screens/onboarding_screen_one.dart` | Pixel-locked layout |
| 3 | Onboarding 2 | `/onboarding-2` | `lib/features/onboarding/presentation/screens/onboarding_screen_two.dart` | Pixel-locked layout |
| 4 | Onboarding 3 | `/onboarding-3` | `lib/features/onboarding/presentation/screens/onboarding_screen_three.dart` | Pixel-locked layout |
| 5 | Phone login | `/login` | `lib/features/auth/presentation/login_screen.dart` → `screens/phone_login_screen.dart` | Facade preserves test-compatible API |
| 6 | Create account | `/create-account`, `/register` | `lib/features/auth/presentation/screens/create_account_screen.dart` | Both routes resolve to the same screen |
| 7 | OTP verification | `/otp` | `lib/features/auth/presentation/otp_screen.dart` | Six-digit mock OTP |
| 8 | Profile setup | `/profile-setup` | `lib/features/auth/presentation/profile_setup_screen.dart` | Post-OTP profile completion |
| 9 | Home | `/home` | `lib/features/home/presentation/home_screen.dart` | Custom map, booking sheet, bottom navigation |
| 10 | Pickup selection | `/pickup-selection` | `lib/features/location/presentation/pickup_selection_screen.dart` | Map-based location flow |
| 11 | Destination selection | `/destination-selection` | `lib/features/location/presentation/destination_selection_screen.dart` | Search and map selection |
| 12 | Saved places | `/saved-places` | `lib/features/location/presentation/saved_places_screen.dart` | Saved-place management |
| 13 | Vehicle selection | `/vehicle-selection` | `lib/features/booking/presentation/vehicle_selection_screen.dart` | Bike/Toto cards and fare preview |
| 14 | Fare details | `/fare-details` | `lib/features/booking/presentation/fare_details_screen.dart` | Fare breakdown |
| 15 | Booking confirmation | `/booking-confirmation` | `lib/features/booking/presentation/booking_confirmation_screen.dart` | Pickup, destination, payment summary |
| 16 | Searching driver | `/searching-driver` | `lib/features/booking/presentation/searching_driver_screen.dart` | Cancel search |
| 17 | Driver assigned | `/driver-assigned` | `lib/features/booking/presentation/driver_assigned_screen.dart` | Driver card and contact actions |
| 18 | Ride tracking | `/ride-tracking` | `lib/features/booking/presentation/ride_tracking_screen.dart` | `flutter_map` tracking view |
| 19 | Trip completed | `/trip-completed` | `lib/features/booking/presentation/trip_completed_screen.dart` | Completion summary |
| 20 | Ride rating | `/ride-rating` | `lib/features/booking/presentation/ride_rating_screen.dart` | Stars, tags, comment |
| 21 | My rides | `/my-rides` | `lib/features/rides/presentation/screens/my_rides_screen.dart` via `presentation/my_rides_screen.dart` | Export shim preserves import compatibility |
| 22 | Ride details | `/ride-details` | `lib/features/rides/presentation/ride_details_screen.dart` | Receives `RideRecord` argument |
| 23 | Profile | `/profile` | `lib/features/account/presentation/profile_screen.dart` | Account hub |
| 24 | Edit profile | `/edit-profile` | `lib/features/account/presentation/edit_profile_screen.dart` | Profile form |
| 25 | Payment methods | `/payment-methods` | `lib/features/account/presentation/payment_methods_screen.dart` | Payment selection |
| 26 | Notifications | `/notifications` | `lib/features/notifications/presentation/notifications_screen.dart` | Notification list |
| 27 | Help & Support | `/help-support` | `lib/features/support/presentation/help_support_screen.dart` | Public route |
| 28 | Settings | `/settings` | `lib/features/account/presentation/settings_screen.dart` | Protected route |
| 29 | About | `/about` | `lib/features/account/presentation/about_screen.dart` | Public route |
| 30 | Safety | No named route | `lib/features/safety/presentation/screens/safety_screen.dart` | Exists but is not wired into `EGoRouter`; current “Safety” nav item opens Help & Support |
| 31 | Legacy onboarding carousel | No named route | `lib/features/auth/presentation/onboarding_screen.dart` | Legacy/unrouted implementation retained for compatibility |
| 32 | Location search | Modal route | `lib/features/location/presentation/location_search_delegate.dart` | Opened from location flows |
| 33 | Recent destinations | Bottom sheet | `lib/features/location/presentation/recent_destinations_bottom_sheet.dart` | Opened from location flows |

### 6.1 Routing observations

- `EGoRouter.protectedRoutes` covers home through settings, including all booking and rides screens.
- `helpSupport` and `about` are public.
- `EGoRouter` does not define a Safety route.
- The Home bottom navigation uses:
  - Home → `/home`
  - Rides → `/my-rides`
  - Safety → `/help-support`
  - Profile/Account → `/profile`
- The migration must not “fix” the Safety navigation discrepancy as part of visual work. That is a separate product decision.

---

## 7. Supporting UI Inventory

### 7.1 Shared widgets

| Component | File | Migration relevance |
|---|---|---|
| Primary, secondary, text, icon, and FAB buttons | `lib/shared/widgets/buttons.dart` | Yellow/navy, Inter labels, keep sizes |
| Location and search inputs | `lib/shared/widgets/inputs.dart` | Token-driven; selected-state tints |
| Section header, labeled divider, empty state, loading overlay, banner | `lib/shared/widgets/common.dart` | Navy text, light surfaces, semantic banners |
| Bottom navigation | `lib/shared/widgets/bottom_nav_bar.dart` | Remove `Manrope`; yellow active capsule; navy icons/text |
| Map controls and route summary | `lib/shared/widgets/location_components.dart` | Brand markers/controls; map functionality preserved |
| Widget barrel | `lib/shared/widgets/index.dart` | Update only if exports change |

### 7.2 Branding widgets and assets

| Item | File / asset | Notes |
|---|---|---|
| Logo variants | `lib/core/branding/widgets/ego_logo.dart` | Primary, icon, wordmark; tint support via `srcIn` |
| Brand mark | `lib/core/branding/widgets/ego_brand_mark.dart` | Verify usages |
| Wordmark | `lib/core/branding/widgets/ego_wordmark.dart` | Verify usages |
| Asset paths | `lib/core/branding/ego_brand_assets.dart` | Single source for brand asset paths |
| Logo master | `assets/branding/ego_logo_master.jpg` | Inspect transparency and colour |
| Primary logo | `assets/branding/ego_logo_primary.png` | Used on splash |
| Icon logo | `assets/branding/ego_logo_icon.png` | Used on home pill and navigation |
| Wordmark | `assets/branding/ego_logo_wordmark.png` | Used in headers |
| Brand background | `assets/branding/ego_brand_background.jpg` | Verify usage before changing |
| Alternate logo image | `LOGO/IMG-20261027-WA0005.jpg` | Not integrated; do not use without approval |

### 7.3 Onboarding widgets

- `lib/features/onboarding/presentation/widgets/onboarding_screen_layout.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_hero.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_header.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_progress.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_primary_button.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_illustrations/bike_illustration.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_illustrations/toto_illustration.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_illustrations/location_illustration.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_illustrations/wind_trails_painter.dart`
- `lib/features/onboarding/presentation/theme/onboarding_constants.dart`

The geometry constants, including 272 px hero area, 236 px disk, 216 px ring, 72 px heading/supporting areas, 58 px CTA, and 16 px radius, are regression-critical.

### 7.4 Home widgets

- `lib/features/home/presentation/widgets/home_map_painter.dart`
- `lib/features/home/presentation/widgets/home_location_marker.dart`
- `lib/features/home/presentation/index.dart`

### 7.5 Authentication widgets

- `lib/features/auth/presentation/widgets/auth_text_field.dart`
- `lib/features/auth/presentation/widgets/auth_phone_field.dart`
- `lib/features/auth/presentation/widgets/auth_password_field.dart`

### 7.6 Rides widgets

- `lib/features/rides/presentation/widgets/ride_card.dart`
- `lib/features/rides/presentation/widgets/ride_filter_tabs.dart`
- `lib/features/rides/presentation/widgets/rides_header.dart`
- `lib/features/rides/presentation/widgets/rides_empty_state.dart`
- `lib/features/rides/presentation/widgets/book_toto_button.dart`

### 7.7 Web shell

- `web/index.html`
- `web/manifest.json`
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

---

## 8. Screen-by-Screen Migration Matrix

Status labels:

- **Token-driven**: mostly consumes `EGoColors`, `EGoTypography`, and `EGoSpacing`.
- **Local palette**: contains duplicate raw colours or font families.
- **Mixed**: token-driven with local overrides.
- **Reference-blocked**: screen-level visual decisions require the showcase image.

| Phase | Screen / surface | File(s) | Current state | Planned migration work | Verification |
|---|---|---|---|---|---|
| 1 | Theme and tokens | `lib/app/theme/colors.dart`, `typography.dart`, `spacing.dart`, `theme.dart` | Split system; old palette; `Roboto` | Canonical palette/roles; Poppins/Inter; Material theme roles | `test/widget_test.dart`, new token test |
| 1 | Brand palette | `lib/core/branding/ego_brand_colors.dart` | Old yellow; no navy | Exact official values; semantic tokens; derived tones | Token test |
| 1 | Brand theme helpers | `lib/core/branding/ego_brand_theme.dart` | Duplicates button/card styles | Deprecate or delegate to canonical theme/buttons | Static analysis and grep |
| 1 | Fonts | `pubspec.yaml`, `assets/fonts/*` | Manrope only | Add Poppins and Inter with OFL; keep Manrope temporarily | `flutter pub get`, analyze, tests |
| 1 | Web shell | `web/index.html`, `web/manifest.json` | Flutter defaults | E-GO name, description, colours, font loading | Manual web inspection |
| 2 | Splash | `lib/features/auth/presentation/splash_screen.dart` | Token-driven, yellow background | Official yellow, navy tagline, logo QA | Widget/manual capture |
| 2 | Onboarding 1–3 | `lib/features/onboarding/presentation/screens/onboarding_screen_one.dart`, `onboarding_screen_two.dart`, `onboarding_screen_three.dart` and all onboarding widgets | Local palette; pixel-locked | Palette/typography only; geometry unchanged | Coordinate tests and screenshots |
| 2 | Legacy onboarding carousel | `lib/features/auth/presentation/onboarding_screen.dart` | Token-driven but unrouted | Migrate tokens or mark legacy; no routing change | Visual inspection |
| 3 | Phone login | `lib/features/auth/presentation/screens/phone_login_screen.dart` | Local palette; `Manrope` | Official palette; Inter; remove local constants | `phone_login_screen_test.dart` |
| 3 | Create account | `lib/features/auth/presentation/screens/create_account_screen.dart` | Local palette; `Manrope` | Official palette; Inter; error tokens | `create_account_screen_test.dart` |
| 3 | OTP | `lib/features/auth/presentation/otp_screen.dart` | Mostly token-driven | Input/error/CTA token alignment; Inter | Auth flow tests |
| 3 | Profile setup | `lib/features/auth/presentation/profile_setup_screen.dart` | Token-driven | Token/typography alignment | Manual/widget capture |
| 3 | Auth fields | `lib/features/auth/presentation/widgets/auth_text_field.dart`, `auth_phone_field.dart`, `auth_password_field.dart` | Local border/focus/error colours; `Manrope` | Shared input tokens; navy focus; semantic error | Auth tests |
| 4 | Home | `lib/features/home/presentation/home_screen.dart` | Local `_k*` palette | Replace with theme tokens; keep layout | `home_screen_test.dart` |
| 4 | Home map | `lib/features/home/presentation/widgets/home_map_painter.dart` | Functional cartography | Review against reference; do not blindly brand | Visual QA |
| 4 | Home marker | `lib/features/home/presentation/widgets/home_location_marker.dart` | Local yellow/black | Brand yellow/navy marker | Visual QA |
| 4 | Pickup selection | `lib/features/location/presentation/pickup_selection_screen.dart` | Mixed | Tokens; map controls; no flow change | Visual QA |
| 4 | Destination selection | `lib/features/location/presentation/destination_selection_screen.dart` | Mixed | Tokens; search/selection states | Visual QA |
| 4 | Saved places | `lib/features/location/presentation/saved_places_screen.dart` | Mixed | Tokens; semantic delete action | Visual QA |
| 4 | Location search and recent sheet | `lib/features/location/presentation/location_search_delegate.dart`, `recent_destinations_bottom_sheet.dart` | Mixed | Tokens; Inter; sheet radius/surface | Visual QA |
| 4 | Vehicle selection | `lib/features/booking/presentation/vehicle_selection_screen.dart` | Token-driven | Selected-card yellow/navy; CTA; Inter | `booking_screens_test.dart` |
| 4 | Fare details | `lib/features/booking/presentation/fare_details_screen.dart` | Token-driven | Fare hierarchy; yellow CTA; Inter | `booking_screens_test.dart` |
| 4 | Booking confirmation | `lib/features/booking/presentation/booking_confirmation_screen.dart` | Token-driven | Summary cards; payment row; Inter | `booking_screens_test.dart` |
| 4 | Shared widgets | `lib/shared/widgets/buttons.dart`, `inputs.dart`, `common.dart`, `location_components.dart` | Mostly token-driven | Button/input/card/nav rules; Inter | Widget tests |
| 5 | Searching driver | `lib/features/booking/presentation/searching_driver_screen.dart` | Token-driven | Palette/typography; animation unchanged | `booking_screens_test.dart` |
| 5 | Driver assigned | `lib/features/booking/presentation/driver_assigned_screen.dart` | Token-driven; raw rating accent | Official palette; semantic star/accent decision | `booking_screens_test.dart` |
| 5 | Ride tracking | `lib/features/booking/presentation/ride_tracking_screen.dart` | Token-driven; map | Chrome, cards, markers; map behaviour preserved | `booking_screens_test.dart` and manual map check |
| 5 | Trip completed | `lib/features/booking/presentation/trip_completed_screen.dart` | Token-driven | Summary, CTA, typography | `booking_screens_test.dart` |
| 5 | Ride rating | `lib/features/booking/presentation/ride_rating_screen.dart` | Mixed; raw `#FBBC04` | Star token decision; chips; Inter | `booking_screens_test.dart` |
| 6 | My rides | `lib/features/rides/presentation/screens/my_rides_screen.dart` and `lib/features/rides/presentation/widgets/*` | Local `Manrope`; raw status colours | Tokens/semantic chips/Inter; no filter behaviour change | `my_rides_screen_test.dart` |
| 6 | Ride details | `lib/features/rides/presentation/ride_details_screen.dart` | Token-driven | Typography/cards | Visual QA |
| 6 | Profile | `lib/features/account/presentation/profile_screen.dart` | Token-driven | Typography/cards | Visual QA |
| 6 | Edit profile | `lib/features/account/presentation/edit_profile_screen.dart` | Mixed | Inputs; tokens; Inter | Visual QA |
| 6 | Payment methods | `lib/features/account/presentation/payment_methods_screen.dart` | Token-driven | Selected-state yellow/navy | Visual QA |
| 6 | Notifications | `lib/features/notifications/presentation/notifications_screen.dart` | Token-driven | Typography/status tokens | Visual QA |
| 6 | Help & Support | `lib/features/support/presentation/help_support_screen.dart` | Token-driven | Typography/accordion surfaces | Visual QA |
| 6 | Settings | `lib/features/account/presentation/settings_screen.dart` | Token-driven | Typography/switches/sheets | Visual QA |
| 6 | About | `lib/features/account/presentation/about_screen.dart` | Token-driven | Logo/typography/surfaces | Visual QA |
| 6 | Safety | `lib/features/safety/presentation/screens/safety_screen.dart` | Old green palette; `Manrope`; unrouted | Replace green palette with brand/semantic tokens; no routing change | Visual QA |
| 6 | Bottom navigation | `lib/shared/widgets/bottom_nav_bar.dart` | Mixed; `Manrope` | Yellow active capsule; navy inactive; Inter | `home_screen_test.dart`, `my_rides_screen_test.dart` |
| 6 | Web shell | `web/index.html`, `web/manifest.json` | Flutter defaults | Brand metadata and colours; PWA icons if official assets available | Manual web/PWA inspection |
| 6 | Cleanup | `pubspec.yaml`, `assets/fonts/*`, all migrated files | Manrope fallback and stale aliases remain | Remove Manrope only after full verification; remove dead aliases | Full suite and grep |

### 8.1 Reference-blocked decisions

The following must wait for Gate R:

- Whether app bars remain white or become light-background/transparent.
- Card border radii, shadows, and elevation.
- Exact button heights and pill vs rounded-rectangle treatment.
- Splash composition beyond the existing layout.
- Map canvas palette and illustration details.
- Rating-star colour and treatment.
- Whether navigation labels use navy or muted navy.
- Whether selected cards use yellow fill, yellow border, or both.

---

## 9. Target Architecture and Token Consolidation

### 9.1 Single source of truth

**Raw palette source:** `lib/core/branding/ego_brand_colors.dart`

- The only file allowed to define the official brand hex values.
- Contains official yellow, background, and navy.
- Contains the preserved semantic success, warning, error, and information colors.
- May define neutral white and derived alpha values required by Material theme roles.

**Semantic role layer:** `lib/app/theme/colors.dart`

- Defines `EGoColors` roles such as `brandPrimary`, `onSurface`, `surface`, `outline`, `error`, and `mapControlBackground`.
- References `EgoBrandColors`; must not duplicate raw official values.
- Removes or aliases legacy “green” names only after all usages are confirmed.

**Typography:** `lib/app/theme/typography.dart`

- The only production file that names font families and defines text styles.
- `fontFamilyDisplay = 'Poppins'`
- `fontFamilyBody = 'Inter'`
- `fontFamilyNumbers = 'Inter'`
- `fontFamilyPrimary` remains as a compatibility alias to the body family during migration.

**Spacing and shape:** `lib/app/theme/spacing.dart`

- Remains the single source for 4 px spacing, control heights, radii, and elevation values.

**Material theme:** `lib/app/theme/theme.dart`

- Builds the only `ThemeData` used by the app.
- Must not contain duplicated palette literals.

### 9.2 Import and dependency rules

1. Features import the public theme barrel:
   - Preferred: `package:e_go/app/theme/index.dart`
   - Compatibility: `package:e_go/core/theme/index.dart`
2. `lib/app/theme/*` must not import feature files.
3. Feature-local color constants are not permitted for brand UI after migration.
4. Functional map and illustration palettes may remain local only when named, documented, and inaccessible to general UI styling.
5. `lib/core/branding/ego_brand_theme.dart` should be deprecated and replaced by shared buttons or the Material theme. It must not contain a second button system.
6. `lib/core/branding/ego_brand_assets.dart` remains the source for brand asset paths.
7. `lib/core/branding/widgets/*` remain the source for logo/brand-mark widgets.
8. `lib/core/theme/index.dart` remains a compatibility barrel, not an independent token source.
9. `lib/features/onboarding/presentation/theme/onboarding_constants.dart` retains geometry only; colors and font families reference theme tokens.
10. `PhoneLoginConstants` retains layout-only constants; color constants are removed.

### 9.3 Migration safety rules

- Keep deprecated aliases until all imports and tests are migrated.
- Delete aliases only after grep confirms zero production usages.
- Do not change route names, screen constructors, public widget APIs, or test keys.
- Do not rename existing files during the visual migration unless required to resolve a duplicate source.
- Do not introduce a new state-management or theming package.

### 9.4 Proposed end state

```
lib/core/branding/ego_brand_colors.dart     raw official palette + semantics
lib/core/branding/ego_brand_assets.dart     asset paths
lib/core/branding/widgets/*                 logo and brand-mark widgets
lib/app/theme/colors.dart                   semantic roles; no raw palette duplication
lib/app/theme/typography.dart               Poppins/Inter styles; only family names
lib/app/theme/spacing.dart                  spacing, radii, elevation
lib/app/theme/theme.dart                    Material 3 ThemeData
lib/app/theme/index.dart                    canonical public barrel
lib/core/theme/index.dart                   compatibility re-export
lib/core/branding/ego_brand_theme.dart      deprecated compatibility facade
```

---

## 10. Palette Specification

### 10.1 Official colors

| Name | Value | Primary use |
|---|---|---|
| Brand yellow | `#FFC928` | Primary CTAs, active navigation, selected states, brand moments, markers, highlights |
| Background light | `#F5F7FA` | Scaffold backgrounds, auth/onboarding backgrounds, section bands, input fills where appropriate |
| Deep navy | `#142B45` | Primary text, icons, outlines, focus borders, dark buttons, high-contrast surfaces |

### 10.2 Neutral and derived tones

- White `#FFFFFF` remains the surface color for cards, sheets, input fields, and app bars where the reference permits. It is a neutral surface, not a fourth brand hue.
- Secondary text: navy at approximately 60–70% opacity over the active background.
- Muted text: navy at approximately 40–50% opacity.
- Borders and dividers: navy at approximately 12–16% opacity.
- Disabled fills: light background mixed toward navy at low opacity.
- Selected fills: yellow at 12–18% opacity, with a navy or yellow border.
- Focus ring: navy border for accessible contrast; optional yellow halo as a brand accent.
- Shadows: navy-tinted or neutral black at low opacity; never use yellow shadows.

All derived tones must be generated from the three official colors. Avoid adding unrelated hex values.

### 10.3 Semantic colors

Keep semantic meaning stable:

| Semantic | Value | Use |
|---|---|---|
| Success | `#059669` | Successful state, valid indicator |
| Warning | `#D97706` | Warning state |
| Error | `#DC2626` | Validation and destructive errors |
| Information | `#0284C7` | Informational banners and links |

Consolidate the auth-specific error `#D93829` into the single error token unless the visual reference explicitly requires a separate red. Consolidate the safety/auth success greens into the success token.

### 10.4 Mapping from current values

| Current | Replacement |
|---|---|
| `#F5C928`, `#FCD030` | `#FFC928` |
| `#FAFAF7`, `#FAF9F5` | `#F5F7FA` |
| `#171717`, `#131E1A`, `#000000` text | `#142B45` |
| `#6B7280`, `#444748`, `#747878`, `#65716B`, `#63635E` | Navy-derived secondary/muted text |
| `#E7E7E2`, `#E5E5E5`, `#EBEBEB`, `#E3E8E3` | Navy-derived borders/dividers |
| `#F5F5F0`, `#F3F4F6`, `#EBEBE6`, `#F2F2EC` | Light background or navy-derived neutral surface |
| `#D93829` | Semantic error `#DC2626` |
| `#1B8755`, `#176B4F` | Semantic success `#059669` |
| `#FBBC04` | Provisional: brand yellow or reference-approved rating accent |
| `#F5B33B` | Provisional: brand yellow or semantic warning depending on meaning |
| Map greens | Functional exception; reference review required |

### 10.5 70/20/10 application

The ratio is an overall brand guideline:

- Yellow is the dominant brand signal through CTAs, active navigation, selected states, logo moments, and key accents.
- Light background dominates page area because it is the functional canvas.
- Navy carries text, iconography, outlines, and dark anchor surfaces.
- White is allowed as a neutral surface for cards, sheets, and controls.
- Do not force a screen to be 70% yellow. A screen may be mostly light with a yellow CTA and navy text and still be compliant.
- Audit the overall app and key screens against the reference image, not arbitrary per-screen percentages.

---

## 11. Typography Specification

### 11.1 Families

| Role | Family | Weights | Use |
|---|---|---|---|
| Display and headings | Poppins | 600, 700, 800 | Display, headline, brand title, screen headings |
| Body and UI | Inter | 400, 500, 600, 700 | Body, inputs, buttons, navigation, labels, numerals |

### 11.2 Application rules

- `EGoTypography.display*`, `headline*`, and `brandTitle` use Poppins.
- `EGoTypography.titleLarge` uses Poppins for screen-level headings.
- `EGoTypography.titleMedium` and `titleSmall` use Inter for card and component labels.
- `body*`, `label*`, input text, button labels, and navigation labels use Inter.
- Numerals in fares, fares breakdowns, OTP, and ride metrics may use Inter with tabular figures if visually consistent.
- Preserve existing font sizes and line heights initially. Adjust only after reference inspection and only if layout tests remain stable.
- Do not mix Manrope into new tokens.

### 11.3 Font assets

Planned additions:

- `assets/fonts/Poppins-Regular.ttf` (400)
- `assets/fonts/Poppins-Medium.ttf` (500)
- `assets/fonts/Poppins-SemiBold.ttf` (600)
- `assets/fonts/Poppins-Bold.ttf` (700)
- `assets/fonts/Poppins-ExtraBold.ttf` (800)
- `assets/fonts/Inter-Regular.ttf` (400)
- `assets/fonts/Inter-Medium.ttf` (500)
- `assets/fonts/Inter-SemiBold.ttf` (600)
- `assets/fonts/Inter-Bold.ttf` (700)
- OFL license files for both families.

These files are **not present** and must not be added until implementation is approved. Poppins 500 may be omitted if unused, to reduce bundle size.

### 11.4 Manrope transition

- Keep Manrope in `pubspec.yaml` during Phases 1–5.
- Keep old test harness font loading working until the relevant phase updates it.
- Remove Manrope assets and declarations only after:
  - All production usages are gone.
  - All screenshot/visual tests load Poppins/Inter.
  - The full test suite passes.
  - Visual QA confirms no layout regression.

### 11.5 Web shell typography

- Remove the Google Fonts Manrope link after bundled fonts are active.
- Ensure the web build loads only the approved bundled families.
- Do not use remote font loading as the sole source for the app UI.

---

## 12. Spacing, Shape, Elevation, and Motion

### 12.1 Spacing

Retain the existing 4 px base scale in `lib/app/theme/spacing.dart`:

- `xs` 4, `sm` 8, `md` 12, `lg` 16, `xl` 20, `xxl` 24, `xxxl` 32, `huge` 48.

Do not globally rescale spacing during the palette migration. Adjust individual screens only if the showcase requires it and after visual QA.

### 12.2 Shape

Current baseline:

- Primary buttons: pill/24 px radius in shared widgets.
- Onboarding CTA: 16 px radius.
- Auth inputs: 16 px radius.
- Cards: 16–20 px radius in various screens.
- Bottom sheets: top corners around 16–24 px.
- Bottom navigation active item: pill.

Keep these values initially. Freeze them only after the reference image is inspected.

### 12.3 Elevation and borders

- Prefer subtle borders and low-opacity shadows.
- Use yellow only for emphasis, never for shadows.
- Selected cards may use a yellow border or a light yellow tint, but avoid combining heavy yellow fill with navy text if contrast is reduced.
- Keep app bar and card elevation consistent with the reference.

### 12.4 Motion

- Preserve existing animation timings and routes.
- Do not remove the splash animation, booking transitions, map marker animation, or rating interactions.
- Only adjust motion if the reference requires it and tests remain green.

---

## 13. Component Migration Rules

| Component | Target treatment |
|---|---|
| Primary button | Yellow `#FFC928` fill, navy label, Inter 600/700, pill or reference radius; disabled derived neutral |
| Secondary button | Transparent/white fill, navy border and label |
| Text button | Navy label; no yellow body text on light backgrounds |
| Input | White surface, navy text, navy-muted hint, navy 2 px focus border, semantic error |
| Card | White surface, navy-derived border, low shadow, 16 px reference radius |
| Selected card | Yellow border or 12–18% yellow tint; navy text; check/icon navy |
| Chip | Selected yellow fill with navy text; unselected light surface with navy-muted text |
| Status chip | Preserve semantic success/warning/error/info backgrounds and text |
| Bottom navigation | White surface, yellow active capsule, navy active icon/text, navy-muted inactive |
| App bar | Provisional: white surface, navy title/icons; confirm with reference |
| Bottom sheet | White surface, navy text, top radius, navy handle |
| Dialog | White surface, navy title/body, yellow primary action |
| Snackbar | Navy background with white text, or white with navy text; confirm contrast |
| Map control | White circular control, navy icon; active yellow |
| Map marker | Yellow and navy; preserve legibility |
| Empty state | Navy title, muted navy body, yellow action |
| Rating star | Provisional: brand yellow, or approved amber from reference |
| Logo pill | White/light surface, navy wordmark/icon; verify asset transparency |
| Splash | Official yellow background, primary logo, navy tagline; confirm composition with reference |

### 13.1 Button and text contrast

- Use navy text on yellow; do not use white text on yellow.
- Use white text on navy where a dark button is required.
- Do not use yellow body text on light backgrounds.
- Use navy or semantic red for error text, not brand yellow.
- Focus indication must be visible against white and light backgrounds.

### 13.2 Onboarding-specific rules

- Change only colors and typography tokens.
- Preserve `OnboardingScreenLayout` and all fixed dimensions.
- Preserve the 272 px hero area, 236 px disk, 216 px ring, 72 px heading and supporting areas, 58 px CTA height, and 16 px CTA radius.
- Preserve `enableAnimations` behavior used by tests.
- After switching to Poppins/Inter, verify text wrapping and line counts. If metrics shift, adjust line heights within existing fixed boxes, not the box geometry.
- Regenerate onboarding screenshots after each change.

### 13.3 Authentication-specific rules

- Keep the custom input composition and all test keys.
- Keep password visibility behavior, validation messages, OTP autofocus/paste behavior, and mock-auth routes.
- Replace local border/focus/error/hint colors with shared tokens.
- Use Inter for fields, buttons, and navigation labels.
- Do not change form validation or request logic.

### 13.4 Home, map, and booking rules

- Replace home `_k*` constants with theme tokens.
- Keep the map painter’s functional cartography, road, railway, and label colors unless the reference explicitly defines a new map style.
- Update only map markers, controls, overlays, and booking UI to brand colors.
- Keep all location selection, recent destinations, saved places, and route flows unchanged.

### 13.5 Ride and support rules

- Replace hardcoded `Manrope` with Inter through typography tokens.
- Map raw status colors to semantic tokens.
- Preserve ride filters, empty states, cancellation, history, and rating behavior.
- Migrate the safety screen’s old green palette even though it is currently unrouted; do not change its routing.

---

## 14. Responsive and Visual QA Plan

### 14.1 Required viewports

| Viewport | Purpose |
|---|---|
| 360 × 800 | Standard Android |
| 375 × 667 | iPhone SE compact |
| 375 × 812 | iPhone X/11/12 mini |
| 393 × 852 | Canonical design viewport |
| 412 × 915 | Large Android / Pixel 7 |
| 430 × 932 | Plus / Pro Max |

### 14.2 Visual checks per screen

- Background and surface colors
- Yellow usage and prominence
- Navy text and icon contrast
- Typography family, weight, size, and line height
- Logo variant, scale, and clear space
- Spacing and alignment
- Border radius and elevation
- Control heights and touch targets
- Selected, focused, disabled, loading, empty, and error states
- No overflow, clipping, or unintended scrolling
- Keyboard-open behavior on auth and profile forms
- Bottom navigation and safe-area behavior
- Map controls and marker legibility

### 14.3 Reference comparison

- Compare at 393 × 852 first.
- Overlay or crop the reference image per screen after Gate R.
- Record deviations and decide whether they are intentional adaptations or defects.
- Do not claim pixel fidelity without the reference image.

### 14.4 Screenshot artifacts

Current baseline:

- `test/screenshots/onboarding_screen_one_393x852.png`
- `test/screenshots/onboarding_screen_two_393x852.png`
- `test/screenshots/onboarding_screen_three_393x852.png`
- `test/screenshots/onboarding_screen_one_375x667.png`
- `test/screenshots/onboarding_screen_two_375x667.png`
- `test/screenshots/onboarding_screen_three_375x667.png`
- `test/screenshots/login_screen_393x852.png`
- `test/screenshots/login_screen_375x667.png`
- `test/screenshots/login_screen_412x915.png`
- `test/screenshots/register_screen_393x852.png`
- `test/screenshots/register_screen_375x667.png`
- `test/screenshots/register_screen_412x915.png`

Planned additions after implementation approval:

- Splash
- Home
- Pickup/destination/saved places
- Vehicle selection, fare, confirmation
- Searching/assigned/tracking/completed/rating
- My rides/ride details
- Profile/edit/payment/notifications/settings/about/help/safety

Critical screens should be captured at 393 × 852 and 375 × 667; the full app should be checked at all six viewports.

---

## 15. Accessibility, Contrast, and Semantics

### 15.1 Contrast

- Navy `#142B45` on yellow `#FFC928` is the primary high-contrast pairing for yellow surfaces.
- Navy on `#F5F7FA` is the primary high-contrast pairing for light surfaces.
- Yellow on white and white on yellow do not provide sufficient text contrast; avoid them for text.
- White on navy is acceptable for dark surfaces.
- Semantic error text must remain readable on white and light backgrounds.
- Focus indicators must remain visible; use navy borders plus an optional yellow halo, not a low-contrast yellow-only outline.

### 15.2 Semantics

- Preserve existing semantic labels, tooltips, button roles, and test keys.
- Do not remove labels or icon semantics for visual minimalism.
- Keep touch targets at least 48 logical pixels.
- Preserve keyboard focus order and form accessibility.
- Verify the logo widget’s `semanticLabel` behavior remains correct.

### 15.3 Colour is not the only signal

- Selected vehicle cards, filter chips, status chips, and errors must retain text, icons, or shape cues in addition to colour.
- Do not rely on yellow alone to indicate selection or warning.

---

## 16. Test and Regression Plan

### 16.1 Baseline (Phase 0)

Run before any code change:

```powershell
cd "D:\E-RICKSHAW RIDE\E-go"
flutter analyze
flutter test
```

Record:

- Analyzer result
- Test count and pass/fail state
- Current screenshot artifacts
- Any pre-existing failures

The historical reports claim 97/97 and 107/107 passing, but the current suite has 19 test files and must be measured fresh.

### 16.2 Existing test inventory

Unit tests:

- `test/unit/auth_repository_test.dart`
- `test/unit/booking_state_test.dart`
- `test/unit/mock_pricing_test.dart`
- `test/unit/repositories_test.dart`

Widget tests:

- `test/widget_test.dart`
- `test/widget/onboarding_screen_one_test.dart`
- `test/widget/onboarding_screen_two_test.dart`
- `test/widget/onboarding_screen_three_test.dart`
- `test/widget/onboarding_consistency_test.dart`
- `test/widget/onboarding_flow_test.dart`
- `test/widget/onboarding_screenshot_test.dart`
- `test/widget/phone_login_screen_test.dart`
- `test/widget/create_account_screen_test.dart`
- `test/widget/auth_screens_flow_test.dart`
- `test/widget/home_screen_test.dart`
- `test/widget/booking_screens_test.dart`
- `test/widget/my_rides_screen_test.dart`
- `test/widget/customer_journey_test.dart`

Integration tests:

- `test/integration/auth_flow_test.dart`

### 16.3 Behavioural invariants

The following must remain covered and passing:

- Demo login, phone normalization, wrong-credential and unknown-account errors.
- Registration, duplicate phone handling, mock OTP `123456`, invalid OTP, resend cooldown.
- Onboarding completion persistence under `ego_onboarding_complete`.
- Protected-route redirects and public Help route.
- Logout and session clearing.
- Booking state transitions from idle through rating.
- Vehicle availability, fare calculation, ride creation, and ride history.
- Home layout, logo presence, map marker, recenter, and bottom navigation.
- My Rides filters, empty state, booking CTA, and navigation.
- Profile, edit profile, payment, notifications, settings, help, and safety rendering.

### 16.4 Visual and token tests

Add after implementation approval:

- `test/unit/design_tokens_test.dart`
  - Assert exact official palette values.
  - Assert semantic colors.
  - Assert Poppins/Inter font family tokens.
  - Assert theme primary, surface, scaffold, and typography bindings.
- Extend or add screenshot tests for all migrated phases.
- Keep the onboarding coordinate tests intact.
- Consider a token-usage test that fails if banned old values (`#F5C928`, `#FCD030`, `#FAF9F5`, `#FAFAF7`, `#171717`, `Manrope`) remain in migrated production files. Implement only if it is stable and not brittle.

### 16.5 Test infrastructure updates

- `test/widget/onboarding_screenshot_test.dart` currently loads Manrope from `assets/fonts/` and hardcodes the Flutter SDK MaterialIcons path on `E:`.
  - Update font loading to Poppins/Inter when the phase begins.
  - Replace the hardcoded SDK path with a portable lookup or environment-aware fallback.
- `test/widget/phone_login_screen_test.dart` and `test/widget/create_account_screen_test.dart` currently set `fontFamily: 'Manrope'` and old background colors.
  - Update only their visual harness values.
  - Preserve all finding, validation, and navigation assertions.
- `test/widget_test.dart` and `test/widget/home_screen_test.dart` assert white surface, white app bar, and `EGoColors.brandPrimary`.
  - Keep these valid by retaining white surfaces/app bar unless the reference requires a change.
  - If the reference requires a change, update the assertions deliberately in the same phase.

### 16.6 Test gates per phase

For each phase:

1. `flutter analyze` must report zero issues.
2. Targeted tests for touched screens must pass.
3. Full `flutter test` suite must pass.
4. Screenshots for touched screens must be regenerated and reviewed.
5. No behavioural test may be removed or weakened.
6. Onboarding coordinate tests must remain green.

### 16.7 Manual smoke tests

1. Launch with `--dart-define=AUTH_MODE=mock`.
2. Log in with `9000000001` / `EgoDemo@123`.
3. Log out and verify redirect to Login.
4. Create a new account and verify OTP `123456`.
5. Complete onboarding and verify it is not shown again.
6. Run the full booking flow: pickup → destination → vehicle → fare → confirmation → searching → assigned → tracking → completed → rating.
7. Verify My Rides, ride details, profile, edit profile, payment methods, notifications, settings, help, about, and safety render correctly.
8. Verify protected routes redirect when logged out.
9. Verify no overflow at 360 × 800 and 430 × 932.

---

## 17. Implementation Sequence and Phase Gates

### Phase 0 — Reference intake and baseline

- Receive and inspect `E-GO E-Rickshaw App UI Showcase(1).png`.
- Complete Gate R and update this document.
- Run baseline `flutter analyze` and `flutter test`.
- Capture current screenshots.
- Confirm no pre-existing failures.

**Gate 0:** Reference annotated; baseline recorded; plan re-approved.

### Phase 1 — Design-system foundation

Files:

- `lib/core/branding/ego_brand_colors.dart`
- `lib/app/theme/colors.dart`
- `lib/app/theme/typography.dart`
- `lib/app/theme/spacing.dart`
- `lib/app/theme/theme.dart`
- `lib/core/branding/ego_brand_theme.dart`
- `lib/core/theme/index.dart`
- `pubspec.yaml`
- `assets/fonts/*`
- `web/index.html`
- `web/manifest.json`
- `test/unit/design_tokens_test.dart`

Work:

- Add official palette and semantic tokens.
- Add Poppins/Inter assets and declarations.
- Rebuild Material theme with official roles.
- Remove duplicate raw palette values from role tokens.
- Keep Manrope for compatibility.
- Update web title, description, and colors.
- Do not restyle screen-level local palettes yet.

**Gate 1:** Analyzer and tests pass; token test passes; no screen behavior changes.

### Phase 2 — Splash and onboarding

Files:

- `lib/features/auth/presentation/splash_screen.dart`
- `lib/features/onboarding/presentation/theme/onboarding_constants.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_screen_layout.dart` (only if token references require it)
- `lib/features/onboarding/presentation/widgets/onboarding_hero.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_header.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_progress.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_primary_button.dart`
- `lib/features/onboarding/presentation/widgets/onboarding_illustrations/*`
- `lib/features/auth/presentation/onboarding_screen.dart` (legacy, tokens only)
- `test/widget/onboarding_*`
- Onboarding screenshots

Work:

- Apply official palette and typography.
- Keep all fixed geometry.
- Verify logo background and contrast on splash.
- Regenerate screenshots at 393 × 852 and 375 × 667.

**Gate 2:** Exact-coordinate tests pass; screenshots reviewed; no overflow.

### Phase 3 — Authentication

Files:

- `lib/features/auth/presentation/screens/phone_login_screen.dart`
- `lib/features/auth/presentation/screens/create_account_screen.dart`
- `lib/features/auth/presentation/otp_screen.dart`
- `lib/features/auth/presentation/profile_setup_screen.dart`
- `lib/features/auth/presentation/widgets/auth_text_field.dart`
- `lib/features/auth/presentation/widgets/auth_phone_field.dart`
- `lib/features/auth/presentation/widgets/auth_password_field.dart`
- `lib/features/auth/presentation/login_screen.dart` (only if facade changes; usually none)
- `test/widget/phone_login_screen_test.dart`
- `test/widget/create_account_screen_test.dart`
- Auth flow tests and screenshots

Work:

- Remove auth-local palette and `Manrope`.
- Use shared input, button, error, and typography tokens.
- Preserve all validation, OTP, routing, and mock-auth behavior.

**Gate 3:** Auth unit/widget/integration tests pass; screenshot review; keyboard behavior intact.

### Phase 4 — Core booking

Files:

- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/widgets/home_map_painter.dart`
- `lib/features/home/presentation/widgets/home_location_marker.dart`
- `lib/features/location/presentation/pickup_selection_screen.dart`
- `lib/features/location/presentation/destination_selection_screen.dart`
- `lib/features/location/presentation/saved_places_screen.dart`
- `lib/features/location/presentation/location_search_delegate.dart`
- `lib/features/location/presentation/recent_destinations_bottom_sheet.dart`
- `lib/features/booking/presentation/vehicle_selection_screen.dart`
- `lib/features/booking/presentation/fare_details_screen.dart`
- `lib/features/booking/presentation/booking_confirmation_screen.dart`
- `lib/shared/widgets/buttons.dart`
- `lib/shared/widgets/inputs.dart`
- `lib/shared/widgets/common.dart`
- `lib/shared/widgets/location_components.dart`
- `lib/shared/widgets/bottom_nav_bar.dart`
- Home, booking, and location tests

Work:

- Remove home `_k*` palette.
- Apply component rules.
- Keep map cartography functional; update overlays and markers.
- Preserve all location and booking navigation.

**Gate 4:** Home/booking tests pass; map interaction smoke test; no overflow; screenshots reviewed.

### Phase 5 — Ride lifecycle

Files:

- `lib/features/booking/presentation/searching_driver_screen.dart`
- `lib/features/booking/presentation/driver_assigned_screen.dart`
- `lib/features/booking/presentation/ride_tracking_screen.dart`
- `lib/features/booking/presentation/trip_completed_screen.dart`
- `lib/features/booking/presentation/ride_rating_screen.dart`
- `test/widget/booking_screens_test.dart`
- `test/widget/customer_journey_test.dart`

Work:

- Apply palette, typography, cards, CTAs, status chips, and rating treatment.
- Preserve map behavior and booking transitions.

**Gate 5:** Booking lifecycle tests pass; customer journey test passes; screenshots reviewed.

### Phase 6 — Supporting screens, cleanup, and final QA

Files:

- `lib/features/rides/presentation/screens/my_rides_screen.dart`
- `lib/features/rides/presentation/widgets/ride_card.dart`
- `lib/features/rides/presentation/widgets/ride_filter_tabs.dart`
- `lib/features/rides/presentation/widgets/rides_header.dart`
- `lib/features/rides/presentation/widgets/rides_empty_state.dart`
- `lib/features/rides/presentation/widgets/book_toto_button.dart`
- `lib/features/rides/presentation/ride_details_screen.dart`
- `lib/features/account/presentation/profile_screen.dart`
- `lib/features/account/presentation/edit_profile_screen.dart`
- `lib/features/account/presentation/payment_methods_screen.dart`
- `lib/features/account/presentation/settings_screen.dart`
- `lib/features/account/presentation/about_screen.dart`
- `lib/features/notifications/presentation/notifications_screen.dart`
- `lib/features/support/presentation/help_support_screen.dart`
- `lib/features/safety/presentation/screens/safety_screen.dart`
- `lib/shared/widgets/bottom_nav_bar.dart` (final pass)
- `pubspec.yaml` and `assets/fonts/*` (remove Manrope only after verification)
- `web/index.html`, `web/manifest.json`, PWA icons if approved
- Full screenshot matrix

Work:

- Migrate remaining screens and widgets.
- Remove old green palette from safety.
- Remove hardcoded Manrope.
- Remove dead token aliases only after grep confirmation.
- Update web metadata and icons if official assets are available.
- Run full regression and visual QA.

**Gate 6:** Full analyzer and test suite pass; all six viewports reviewed; onboarding coordinates unchanged; Manrope removal verified; final plan report approved.

### 17.1 Phase dependencies

- Phase 1 must complete before any screen palette work.
- Phase 2 must not begin until Gate R is complete.
- Phase 3 depends on Phase 1 token and font availability.
- Phases 4–6 depend on Phase 1 and their preceding phase gates.
- Manrope removal is the final step, never an intermediate step.

---

## 18. Risks, Assumptions, Open Questions, and Approval

### 18.1 Risks and mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Showcase image not available | Screen-level fidelity cannot be verified | Gate R blocks visual finalization; do not implement screen styling before intake |
| Font metric changes break onboarding | Coordinate tests fail; layout shifts | Keep fixed boxes; run coordinate tests after each font change; tune line heights only |
| Competing token systems drift | Inconsistent colors and duplicate fixes | Enforce one raw palette source and one theme source; grep for banned literals |
| Local palettes remain in screens | Inconsistent UI and future regressions | Phase-by-phase removal; final grep for old hexes and `Manrope` |
| Test harness hardcodes old fonts/colors | False failures or stale screenshots | Update harness per phase; preserve behavior assertions |
| Test harness hardcodes Flutter SDK path | Tests fail on another machine | Replace with portable MaterialIcons lookup during Phase 1 or Phase 2 |
| Yellow text on light backgrounds | Accessibility failure | Enforce navy-on-yellow and navy-on-light rules in review |
| Yellow focus ring alone | Insufficient focus contrast | Use navy focus border plus optional yellow halo |
| Map restyling harms legibility | Navigation confusion | Treat cartography as a functional exception; review with reference |
| Logo asset has baked-in background or low resolution | Bad appearance on yellow/white | Inspect assets; use transparent official variant; do not recolor blindly |
| PWA icons remain Flutter defaults | Inconsistent web identity | Replace only with approved official icon assets |
| Unrouted safety screen or legacy onboarding is mistaken for dead code | Accidental route/behavior changes | Migrate visually, do not change routing or delete without separate approval |
| 70/20/10 is applied literally per screen | Over-yellowed, unusable screens | Apply as an overall brand guideline; validate against reference |
| Web-only scope hides mobile issues | No Android/iOS safe-area verification | Keep responsive web checks; mobile packaging remains out of scope |
| Scope creep into redesign | Regression risk and schedule growth | Preserve layouts, flows, and state; only visual tokens/components change |

### 18.2 Assumptions

- The showcase image will be supplied before implementation begins.
- The official logo assets in `assets/branding/` remain approved for use.
- White is permitted as a neutral surface color for cards, sheets, and inputs.
- Existing screen structures and layouts are the baseline unless the reference explicitly requires a change.
- Manrope can remain temporarily without affecting the final design.
- Poppins and Inter will be bundled locally under their OFL licenses.
- Mock auth and mock repositories remain the development behavior during this migration.
- The Safety screen remains unrouted during this migration; no route changes are made.
- The legacy onboarding carousel remains unrouted; it is migrated visually or left as a compatibility surface, not deleted.
- The existing 19 test files are the current regression baseline, subject to a fresh Phase 0 run.

### 18.3 Open questions

1. **Reference image:** Will the original `E-GO E-Rickshaw App UI Showcase(1).png` be added before implementation?
2. **App bar treatment:** White surface or light `#F5F7FA` background? Current tests expect white.
3. **Surface policy:** Confirm white cards/sheets/inputs are acceptable as neutral surfaces within the official three-color system.
4. **Rating star:** Brand yellow `#FFC928` or a reference-approved amber?
5. **PWA icons:** Are official icon/favicon source assets available, or should the existing `ego_logo_icon.png` be used to generate them later?
6. **Safety screen:** Should it be visually migrated only, wired to a route, or deferred? This plan assumes visual migration only.
7. **Legacy onboarding carousel:** Should it be visually migrated, left unchanged, or retired in a separate task?
8. **Old token aliases:** Confirm that dead aliases may be removed after grep verification, rather than retained indefinitely.
9. **App bar elevation/shadow:** Keep flat, or use a subtle reference-driven shadow?
10. **Map canvas:** Preserve the current functional cartography or adopt a reference-driven map style?

### 18.4 Approval gate

Implementation must not begin until:

- Gate R is complete and the reference image has been inspected.
- The open questions above are resolved or explicitly deferred.
- This plan is explicitly approved.

No application source code, assets, fonts, routes, dependencies, or platform configuration may be changed before that approval.