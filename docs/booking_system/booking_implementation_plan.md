# E-GO Booking System — Implementation Plan

Companion to `booking_system_architecture.md` and `booking_workflow.md`.
Source of truth: the written product specification. No reference screenshots are available.
Implementation order is system-first; UI polish comes after state, locations, fares and ordering pass tests.

## 0. Guardrails

- Preserve Provider/`AppState`, existing repositories/models/components and unrelated screens.
- One booking state, one screen per stage, one route per stage. No duplicate booking system.
- No fake GPS, history, coordinates, prices, routes or driver availability.
- No new packages unless a real location integration is later approved (current plan: honest
  `UnavailableCurrentLocationService`; no fake fallback).
- Keep existing design tokens (`#FFC928`, `#142B45`, `#F5F7FA`, `#FFFFFF`; Poppins/Inter/Manrope).
- Child flow screens are root-navigator routes and must not show the global bottom nav.
- Do not commit/stage anything; the working tree currently has staged test deletions that are not
  part of this task.

## Phase 1 — Core booking state and validation (no UI)

### Files
Create:
- `E-go/lib/core/booking_stage.dart` — `BookingStage`, `LocationConfirmationStatus`,
  `FareCalculationState`, `OrderSubmissionState`, stage transition validator.
- `E-go/lib/core/booking_validation.dart` — validation issue enum/result, `isValidCoordinate`,
  `validateBooking(...)` in the documented order.
- `E-go/lib/features/booking/domain/place_order_result.dart` — outcome enum/result.

Modify:
- `E-go/lib/app/app_state.dart` — add fields/getters/mutators from the architecture:
  stage, confirmations, canonical fare, fare state/error, submission state, created order id,
  current-location state; injectable `VehicleRepository`/`CurrentLocationService`/
  `MockBookingRepository`; invalidation on pickup/destination mutation; guarded
  `prepareVehicleSelection`/`loadVehicles`/`selectVehicle`; route-signature check after awaits;
  `placeOrder()` exactly-once orchestration; `startDriverSearch()`; fix `retrySearch()`.
  Keep legacy `proceedToVehicleSelection`, `proceedToFareReview`, `proceedToConfirmation`,
  `confirmBooking` working for existing screens/tests.
- `E-go/lib/features/booking/data/booking_repository.dart` — `RideRecord.driver` nullable;
  `MockBookingRepository.addRide` idempotent (return bool, ignore duplicate id); keep ids.
- `E-go/lib/features/booking/data/vehicle_repository.dart` — extract `VehicleRepository`
  interface; `MockVehicleRepository implements` it. Output stays exactly two options.
- Nullable-driver guards: `rides/presentation/ride_details_screen.dart`,
  `booking/presentation/trip_completed_screen.dart`,
  `safety/presentation/screens/safety_screen.dart` (show "Driver assignment pending" where needed).
- `E-go/lib/core/booking_state.dart` — do not merge stage into the ride FSM; only touch if a
  transition required by the plan is missing (documented legacy path). Keep driver/trip transitions.

### Tests
- `test/unit/booking_flow_state_test.dart`: initial stage/home/idle; select pickup/destination;
  update pickup/destination clears fare/options/vehicle; stage transitions valid/invalid;
  back-stage behavior; confirmation flags; current location never writes pickup.
- `test/unit/booking_validation_test.dart`: every validation issue and precedence; invalid coords;
  identical/too-close locations; fare not ready; submission in progress.
- `test/unit/order_submission_test.dart`: invalid booking blocked; valid order snapshot fields;
  duplicate call returns same order id; repository has exactly one record; addRide idempotent;
  submission state; error path leaves state failed and no record.
- Keep `test/unit/booking_state_test.dart` green; extend only if needed.

Acceptance: state and validation work independently of final UI; `flutter test test/unit` green
for the new tests.

## Phase 2 — Location data, persistence and discovery data (no UI)

### Files
Create:
- `E-go/lib/features/location/data/current_location_service.dart` — availability enum/result,
  `CurrentLocationService`, `UnavailableCurrentLocationService` (no coordinate, no delay).
- `E-go/lib/features/location/data/recent_destinations_store.dart` — shared_preferences JSON key
  `ego.recent_destinations.v1`; `load/latest/record`; newest-first, id/5-decimal dedupe, max 10,
  corrupt -> empty, reject invalid coords.
- `E-go/lib/features/location/data/popular_destinations.dart` — max 4, ids `s1,s2,s3,s6`
  resolved from `MockData.suggestedPlaces`; no coordinate duplication/invention.
- `E-go/lib/features/location/domain/location_selection_target.dart` — pickup/destination target.

Modify:
- `E-go/lib/features/location/data/location_repository.dart` — keep `searchPlaces`; remove fake
  `getCurrentLocation`/`getRecentDestinations`/no-op `saveRecentDestination` (or leave
  `searchPlaces` only). Update all call sites.
- `E-go/lib/features/location/domain/location_model.dart` — shared `iconForPlaceType(PlaceType)`.
- `E-go/lib/mock_data/mock_data.dart` — retire `MockData.recentDestinations`/`RecentDestination`
  and `mockCurrentLocation` from call sites after zero references (keep `jhargramCenter` and
  `suggestedPlaces`). Do not delete `SavedPlace`/FAQ data used elsewhere.

### Tests
- `test/unit/recent_destinations_store_test.dart`: empty; record/latest; ordering; dedupe by id
  and coordinate; max 10; corrupt JSON -> empty; invalid coords rejected.
- `test/unit/popular_destinations_test.dart`: resolves exactly 4 unique valid Jhargram entries.
- Update `test/unit/repositories_test.dart:40-45` to expect empty initial history and persisted
  history after `record` instead of hardcoded mocks.
- Add a fake/injected `CurrentLocationService` test: unavailable/denied/error mapping; no pickup write.

Acceptance: persistence and datasets are real, deterministic and empty by default; no fake GPS or
history remains in call sites.

## Phase 3 — Stage 2 Location Selection + Map picker UI

### Files
Create:
- `E-go/lib/features/location/presentation/location_selection_screen.dart` (replaces
  `destination_selection_screen.dart`; `git mv` then rewrite).
- `E-go/lib/features/location/presentation/map_location_picker_screen.dart` (replaces
  `pickup_selection_screen.dart`; `git mv` then rewrite; real `FlutterMap`, OSM tiles).
- `E-go/lib/features/location/presentation/widgets/location_selection_field.dart` — 56 px field:
  label, value/placeholder, icon, 48 px tap target, trailing map icon, inline error.
- `E-go/lib/features/location/presentation/widgets/recent_location_tile.dart` — icon, name,
  secondary address, 48 px target; no remove affordance.
- `E-go/lib/features/location/presentation/widgets/popular_destinations_section.dart` — max 4 rows
  (used on Home; keep in location feature only if also reused, otherwise place under home widgets).
- `E-go/lib/features/location/presentation/widgets/route_unavailable_notice.dart` only if reused.

Modify:
- `E-go/lib/app/router.dart` — add `locationSelection='/location-selection'`,
  `mapLocationPicker='/map-location-picker'`, `placeOrder='/place-order'`; remove/replace
  `pickupSelection`, `destinationSelection`, `vehicleSelection`; update protected routes; root
  `MaterialPageRoute`s (no shell).
- `E-go/lib/features/rides/presentation/screens/my_rides_screen.dart:37` and the legacy
  `features/rides/presentation/my_rides_screen.dart` booking entry -> `locationSelection`.
- Search delegate: allow reuse for both fields; no fake results; clear error/empty states.

Behavior:
- White Scaffold, AppBar back arrow, two fields, full-width `Select on map` action, recent list,
  Continue. Body scrollable + `resizeToAvoidBottomInset`; search is modal to protect keyboard.
- Map picker: Pickup/Drop segmented toggle, center pin, search, honest location-unavailable action,
  confirm/cancel; no fake reverse-geocoding.
- Selecting a recent row sets Drop and confirms it; Continue validates and calls
  `prepareVehicleSelection()` then pushes Place Order.

### Tests
- `test/widget/location_selection_screen_test.dart`: fields labels; pickup/drop separation; field
  editing via injected search result; map action navigation; recent list empty vs persisted;
  tap recent sets drop; inline validation; Continue disabled/navigates; no bottom nav.
- `test/widget/map_location_picker_test.dart`: renders FlutterMap; target toggle; confirm returns
  location; back preserves values; unavailable location snackbar; no bottom nav.
- Update `test/widget/global_navigation_shell_test.dart` Stage 2 route expectation.
- Tolerate failed OSM tile loads (do not assert network images); inject static tile provider or
  allow tile errors in tests.

Acceptance: customer can set/edit pickup and drop via search and map; selections survive every
transition; Stage 2 has no global nav; keyboard cannot cover controls.

## Phase 4 — Stage 3 Place Order UI

### Files
Create:
- `E-go/lib/features/booking/presentation/place_order_screen.dart` (`git mv` from
  `vehicle_selection_screen.dart`, then rewrite).
- `E-go/lib/features/booking/presentation/widgets/place_order_map_summary.dart` — `FlutterMap`,
  fit to both coords, pickup/destination markers, **no polyline**, route-unavailable notice.
- `E-go/lib/features/booking/presentation/widgets/vehicle_option_card.dart` — exactly Toto/Bike,
  premium icon tile, fare, selected/unselected states, semantics.
- `E-go/lib/features/booking/presentation/widgets/fare_summary_panel.dart` — fare states,
  demo labels, breakdown, retry.

Modify:
- `E-go/lib/app/router.dart` — `/place-order` -> `PlaceOrderScreen`.
- `E-go/lib/features/booking/presentation/booking_confirmation_screen.dart` and
  `fare_details_screen.dart` — keep registered as legacy/deprecated; do not link from primary flow.
- `E-go/lib/features/booking/presentation/searching_driver_screen.dart` — retry calls fixed
  `retrySearch()`; existing flow unchanged.
- `E-go/lib/features/booking/presentation/driver_assigned_screen.dart` — use pending order/driver
  safely; keep demo labels.

Behavior:
- Content order: map, location summary rows, two vehicle cards, fare panel, demo notice, Place order.
- `loadVehicles()` on entry if needed; show loading; no fare number unless ready.
- Vehicle switch updates fare immediately; location "Change" returns to Stage 2; locations preserved.
- Place order validates, blocks while submitting, creates one pending order, pushes
  `/searching-driver` via `pushReplacement`; duplicate taps cannot create another record.
- No global nav; no real driver/availability claims.

### Tests
- `test/widget/place_order_screen_test.dart`: map visible; pickup/destination labels; exactly two
  vehicle names; only one selected; switching updates fare; fare states; locations preserved on
  change/back; Place order disabled when invalid/submitting; enabled when valid; success navigation;
  duplicate tap creates one order; no bottom nav.
- `test/unit/fare_state_test.dart`: loading/ready/unavailable/error; invalidation on location change;
  stale async result discarded; preferred vehicle reapplied; fare matches existing pricing.
- Update `test/widget/booking_screens_test.dart` and `test/widget/customer_journey_test.dart` for
  new screen/state APIs while preserving ride lifecycle coverage.

Acceptance: the complete Home -> Stage 2 -> Stage 3 -> existing confirmation flow works; no stale
fare; no duplicate order; no invented route/price/GPS.

## Phase 5 — Home destination discovery UI

### Files
Create:
- `E-go/lib/features/home/presentation/widgets/home_map_view.dart` — interactive `FlutterMap`,
  Jhargram center, OSM tiles, current-location marker only when real data exists, recenter action
  with honest unavailable snackbar.
- `E-go/lib/features/home/presentation/widgets/home_destination_panel.dart` — white rounded-top
  panel: drag handle, `Where to?`, destination entry, conditional last-used, popular (max 4).
- `E-go/lib/features/home/presentation/widgets/last_used_destination_tile.dart` (or reuse the
  recent tile if it fits) and `popular_destination_tile.dart` if not reusing the section.

Modify:
- `E-go/lib/features/home/presentation/home_screen.dart` — Stack map + overlay panel; remove logo
  pill, saved-place pill, old pickup row, old CTA, fake location injection; keep global nav via
  shell; history load in `initState` with mounted checks; no location request on startup.
- `E-go/lib/features/home/presentation/index.dart` — update exports if needed.
- Retire `home_map_painter.dart` and `home_location_marker.dart` only after zero references.
- Retire `recent_destinations_bottom_sheet.dart` if still unused (verify first).

Behavior: tapping destination opens Stage 2; tapping last-used/popular sets destination, preserves
pickup, then Stage 3 if pickup confirmed else Stage 2 with Drop prefilled. Panel hides last-used
when no real history. Max four popular. No Add saved place. No E-GO logo.

### Tests
- `test/widget/home_destination_panel_test.dart`: map visible; E-GO logo absent; Where to? and
  Choose your destination visible; no Add saved place/CHOOSE LOCATION; last-used only with persisted
  history; max four popular; tap popular sets destination and navigates correctly; nav visible on
  Home; no fake current-location marker.
- Update `test/widget/home_screen_test.dart` to replace obsolete logo/saved-place/CTA assertions.
- Update `test/widget/global_navigation_shell_test.dart` Home screenshot expectations if needed.

Acceptance: Home is map-first, destination-first and honest; global nav remains; Stage 2 opens.

## Phase 6 — Screenshots, responsive and visual refinement

- Update `test/widget/migration_screenshot_test.dart`:
  - Home scenario uses a state with no recents for the clean state and a separate seeded-recents
    scenario if needed.
  - Add scenarios: `location_selection`, `map_selection`, `place_order`.
  - Seed Stage 3 via `prepare` with pickup/destination + loaded vehicles; select Toto/Bike and
    capture one variant each if useful.
  - Keep 393×852 logical DPR 2 (786×1704 PNG), real fonts/icons; map scenarios pump fixed durations,
    not `pumpAndSettle` if map animations never settle.
  - Output slugs: `final_home_393x852.png`, `final_location_selection_393x852.png`,
    `final_map_selection_393x852.png`, `final_place_order_393x852.png`.
- Responsive matrix: 320×568, 360×800, 375×667/812, 393×852, 430×932 across all stage scenarios;
  assert no exceptions/overflow.
- Visual checks: 28 px panel radius, 16 px card radius, 48–56 px touch targets, yellow primary
  action, navy text, white surfaces, light background, aligned icons, ellipsized long text.

Acceptance: actual Flutter screenshots captured and inspected; no overflow; the three stages are
visually consistent with E-GO tokens and the written layout.

## Phase 7 — Regression, full-suite and stale-test cleanup

- Update stale tests that conflict with current intended UI:
  - `test/widget/my_rides_screen_test.dart` (targets the obsolete `features/rides/presentation/my_rides_screen.dart`
    and removed `Shared` tab) — align with the active `screens/my_rides_screen.dart` or consolidate
    with the passing `your_rides_screen_test.dart`; keep meaningful coverage.
  - `test/widget/booking_screens_test.dart` (expects `Shared`, `Help & Support` case, old screens) —
    update to current UI/new screens.
  - `test/integration/auth_flow_test.dart` logout timeout — diagnose the infinite animation; prefer
    fixing the test pump strategy over changing unrelated UI. If an app-side always-animating widget
    is the true cause and a minimal safe fix exists, document it before changing.
- New tests must cover: state transitions, validation, fare invalidation/recalculation, vehicle
  switch, order exactly-once, recent/popular limits, permission/GPS unavailable, map selection,
  keyboard layout, child-screen nav visibility, responsive widths.
- Run the full suite and report pass/fail with command output.

Acceptance: no new failures caused by booking changes; stale pre-existing failures either fixed or
explicitly documented with evidence and owner approval.

## Phase 8 — Independent audit and correction loop

Auditor verifies: actual code, state transitions, data honesty, recent persistence, popular limit,
map behavior, fare correctness/invalidation, exactly-once submission, nav visibility, permissions,
naming, responsive UI, tests, screenshots, analysis, web build, regressions. Developer fixes
confirmed defects only; Orchestrator reruns verification and inspects the final diff/screenshots.

Deliverables: `booking_system_audit_report.md` and `booking_system_final_report.md`.

## Exact verification commands

```powershell
cd "D:\E-RICKSHAW RIDE\E-go"
flutter analyze
flutter test test/unit
flutter test test/widget/home_destination_panel_test.dart test/widget/location_selection_screen_test.dart test/widget/map_location_picker_test.dart test/widget/place_order_screen_test.dart
flutter test
flutter test test/widget/migration_screenshot_test.dart
flutter build web --release
```

Record actual output counts and any pre-existing failures separately. Do not claim success without
command evidence.

## File-level change summary

Create (planned):
```
E-go/lib/core/booking_stage.dart
E-go/lib/core/booking_validation.dart
E-go/lib/features/booking/domain/place_order_result.dart
E-go/lib/features/location/domain/location_selection_target.dart
E-go/lib/features/location/data/current_location_service.dart
E-go/lib/features/location/data/recent_destinations_store.dart
E-go/lib/features/location/data/popular_destinations.dart
E-go/lib/features/location/presentation/location_selection_screen.dart
E-go/lib/features/location/presentation/map_location_picker_screen.dart
E-go/lib/features/location/presentation/widgets/location_selection_field.dart
E-go/lib/features/location/presentation/widgets/recent_location_tile.dart
E-go/lib/features/location/presentation/widgets/popular_destinations_section.dart
E-go/lib/features/home/presentation/widgets/home_map_view.dart
E-go/lib/features/home/presentation/widgets/home_destination_panel.dart
E-go/lib/features/booking/presentation/place_order_screen.dart
E-go/lib/features/booking/presentation/widgets/place_order_map_summary.dart
E-go/lib/features/booking/presentation/widgets/vehicle_option_card.dart
E-go/lib/features/booking/presentation/widgets/fare_summary_panel.dart
E-go/test/unit/booking_flow_state_test.dart
E-go/test/unit/booking_validation_test.dart
E-go/test/unit/order_submission_test.dart
E-go/test/unit/fare_state_test.dart
E-go/test/unit/recent_destinations_store_test.dart
E-go/test/unit/popular_destinations_test.dart
E-go/test/widget/home_destination_panel_test.dart
E-go/test/widget/location_selection_screen_test.dart
E-go/test/widget/map_location_picker_test.dart
E-go/test/widget/place_order_screen_test.dart
```

Modify:
`app_state.dart`, `router.dart`, `booking_repository.dart`, `vehicle_repository.dart`,
`booking_state.dart` (only if required), `location_repository.dart`, `location_model.dart`,
`mock_data.dart`, `home_screen.dart`, `home/presentation/index.dart`,
`my_rides_screen.dart` (both booking entry references), legacy screen imports/tests,
`ride_details_screen.dart`, `trip_completed_screen.dart`, `safety_screen.dart`,
`searching_driver_screen.dart`, `migration_screenshot_test.dart`, `home_screen_test.dart`,
`global_navigation_shell_test.dart`, `repositories_test.dart`, `booking_screens_test.dart`,
`customer_journey_test.dart`, plus stale test cleanup.

Renamed/retired (after reference check):
- `destination_selection_screen.dart` -> `location_selection_screen.dart`
- `pickup_selection_screen.dart` -> `map_location_picker_screen.dart`
- `vehicle_selection_screen.dart` -> `place_order_screen.dart`
- `home_map_painter.dart`, `home_location_marker.dart`,
  `recent_destinations_bottom_sheet.dart`, `MockData.recentDestinations`,
  `MockData.mockCurrentLocation`, `RecentDestination` — only if zero references.
- Do **not** remove `saved_places_screen.dart`, `/saved-places`, or Profile navigation to it.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Route renames break tests/legacy screens | Update all references in one change; compile before UI work; run global-nav tests. |
| Nullable driver breaks ride/history/safety screens | Add null guards + "Driver assignment pending"; test ride details with pending + assigned orders. |
| Map/network tile flakiness in tests | Inject tile provider or tolerate tile errors; assert widget structure/markers, not tile pixels. |
| Fake history/GPS accidentally reintroduced | Grep for `mockCurrentLocation`, `recentDestinations`, `getCurrentLocation` after changes; tests assert empty-by-default. |
| Stale fare survives location change | Synchronous invalidation in setters + route-signature check after async loads; unit tests. |
| Duplicate order on double tap | Synchronous `submitting` guard, `createdOrderId` short-circuit, idempotent repository, `pushReplacement`. |
| Scope creep in Home/Stage 2 | No extra pickup row on Home, no recent-remove UI, no new vehicle categories, no new services/ads. |
| Pre-existing failing tests conflated with new work | Capture baseline (10 known failures) and compare post-change; fix or document separately. |

## Definition of done

Home (map, no logo, Where to?, real last-used only, ≤4 popular, no Add saved place, global nav) ->
Stage 2 (separate pickup/drop, search, map selection, real recents, validation, no global nav) ->
Stage 3 (markers, two vehicles, fare with invalidation, Place order) -> exactly one pending order ->
existing confirmation/search flow. Analyze clean, focused tests and full suite evidence, web build
success, screenshots inspected, docs complete, audit defects resolved.
