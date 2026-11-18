# E-GO Booking System — Final Report

Date: 17 November 2026
App: `D:\E-RICKSHAW RIDE\E-go`
Status: **COMPLETE AND VERIFIED**

## 1. Executive summary

The customer booking system has been transformed into a single, honest, testable flow:

`Home destination discovery -> Stage 2 Location Selection -> Map Location Picker ->
Stage 3 Place Order -> existing searching/driver-assignment flow`

The work preserves the existing ride lifecycle and visual language, adds a separate
`BookingStage` model for the customer-visible steps, and enforces exactly-once order
creation. All booking state is owned by `AppState`; no second booking system, duplicate
stage screen or fake location/history data was introduced.

Verification completed:

- `flutter analyze`: no issues.
- `dart analyze lib test`: no issues.
- Full `flutter test`: **+292, all tests passed**.
- Independent auditor recheck of corrections: **+24, all tests passed; APPROVED**.
- `flutter build web --release`: **Built build\web**.
- 21 final screenshots generated at 393x852 and inspected; responsive matrix covers
  320x568, 360x800, 375x667, 375x812, 393x852 and 430x932.

## 2. Delivered behavior

### Stage 1 — Home

- Map-first Home with interactive `FlutterMap` centered on Jhargram.
- Bottom discovery panel with drag handle, "Where to?", destination field, conditional
  "Last used" recent destination and "Popular in Jhargram".
- Popular destinations are limited to four dataset-owned places: Jhargram Bazar, Railway
  Station, Palace and Bus Stand (`s1,s2,s3,s6`).
- Home keeps the global four-item bottom navigation via `EGoMainShell`.
- Current-location marker appears only when a real coordinate exists; otherwise the locate
  action reports an honest unavailable message.
- A destination tap with a confirmed pickup opens Stage 3 directly; without a confirmed
  pickup it opens Stage 2 with the drop prefilled.
- Back from a direct Stage 3 returns to Home with stage `home`.

### Stage 2 — Location Selection

- Root-navigator screen with no global bottom nav.
- Pickup and Drop fields; each opens the full-screen map picker.
- Recent destinations are loaded from persistence and fill only the drop field.
- "Continue" validates both locations, loads the two fare options and opens Stage 3.
- Empty state is honest: "Your ordered destinations will appear here."
- Back returns Home while preserving confirmed locations.

### Map Location Picker

- Full-screen `FlutterMap` with center pin, Pickup/Drop toggle, search and confirm.
- Starts with no candidate when the field has no saved location; Confirm is disabled until
  the user selects a place, moves the map, searches or uses the current-location control.
- Search uses the existing place dataset; no fabricated results.
- Current location uses `UnavailableCurrentLocationService` by default and never writes a
  pickup automatically.
- Back pops null and leaves both fields unchanged.

### Stage 3 — Place Order

- Route map summary with pickup and destination markers, camera fit and an explicit
  "Route preview unavailable" notice (no fabricated polyline).
- Pickup/Drop summary with "Change" returning to Stage 2 while preserving locations.
- Exactly two vehicle options: E-Rickshaw/Toto and Bike.
- No vehicle is auto-selected. Fare is hidden until a vehicle is selected and the fare state
  is ready.
- Fare breakdown, approximate straight-line distance, demo pricing disclaimer and demo-mode
  notice.
- "Place order" is disabled until the shared validation passes; duplicate taps cannot create
  a second record.
- Success replaces Stage 3 with `/searching-driver`; the existing demo search and driver
  assignment continue under the same order id.

### Orders and recent history

- The pending order is created at Place order with:
  - `RideStatus.upcoming`
  - `driver: null`
  - immutable pickup/destination/vehicle/fare/payment snapshot
  - `tripId` equal to the order id
- `createdOrderId` short-circuits repeated submissions; `MockBookingRepository.addRide`
  ignores an existing id; navigation uses `pushReplacement`.
- Driver assignment later attaches a clearly labelled demo driver to the same record.
- Recent destinations are written only after a successful order, stored under
  `ego.recent_destinations.v1`, max 10, newest first, deduped by id or 5-decimal coordinates,
  with corrupt data treated as empty.
- Popular destinations are never written to recents merely by being displayed.

## 3. Architecture

- `BookingStatus` remains the existing ride/driver finite-state machine.
- `BookingStage` is a separate customer-visible stage model:
  `home`, `locationSelection`, `locationConfirmation`, `vehicleSelection`,
  `orderSubmission`.
- `AppState` orchestrates stage transitions, confirmations, fare loading, vehicle selection,
  submission, order reference, driver search and recent-history versioning.
- Shared validation lives in `booking_validation.dart`.
- Location data is separated into search-only `LocationRepository`, current-location service,
  recent store and popular-destination resolver.
- Fares come only from `MockPricingService` through `VehicleRepository`.
- Child booking screens are root-navigator routes and hide the global shell navigation.

## 4. Main files

### Core and state

- `lib/core/booking_stage.dart`
- `lib/core/booking_validation.dart`
- `lib/features/booking/domain/place_order_result.dart`
- `lib/app/app_state.dart`
- `lib/app/router.dart`

### Booking data and UI

- `lib/features/booking/data/booking_repository.dart`
- `lib/features/booking/data/vehicle_repository.dart`
- `lib/features/booking/data/driver_repository.dart`
- `lib/features/booking/presentation/place_order_screen.dart`
- `lib/features/booking/presentation/widgets/place_order_map_summary.dart`
- `lib/features/booking/presentation/widgets/vehicle_option_card.dart`
- `lib/features/booking/presentation/widgets/fare_summary_panel.dart`

### Location and Home

- `lib/features/location/data/current_location_service.dart`
- `lib/features/location/data/recent_destinations_store.dart`
- `lib/features/location/data/popular_destinations.dart`
- `lib/features/location/data/location_repository.dart`
- `lib/features/location/presentation/location_selection_screen.dart`
- `lib/features/location/presentation/map_location_picker_screen.dart`
- `lib/features/location/presentation/location_selection_target.dart`
- `lib/features/location/presentation/widgets/location_selection_field.dart`
- `lib/features/location/presentation/widgets/location_tile.dart`
- `lib/features/home/presentation/home_screen.dart`
- `lib/features/home/presentation/widgets/home_map_view.dart`
- `lib/features/home/presentation/widgets/home_destination_panel.dart`
- `lib/shared/shell/ego_main_shell.dart`

### Tests

- `test/unit/booking_flow_state_test.dart`
- `test/unit/booking_validation_test.dart`
- `test/unit/order_submission_test.dart`
- `test/unit/recent_destinations_store_test.dart`
- `test/unit/popular_destinations_test.dart`
- `test/unit/current_location_test.dart`
- `test/widget/home_destination_panel_test.dart`
- `test/widget/home_screen_test.dart`
- `test/widget/location_selection_screen_test.dart`
- `test/widget/map_location_picker_test.dart`
- `test/widget/place_order_screen_test.dart`
- `test/widget/your_rides_screen_test.dart`
- `test/widget/booking_screens_test.dart`
- `test/widget/customer_journey_test.dart`
- `test/widget/global_navigation_shell_test.dart`
- `test/widget/migration_screenshot_test.dart`
- `test/helpers/test_tile_provider.dart`

### Removed stale code

- `lib/features/home/presentation/widgets/home_map_painter.dart`
- `lib/features/home/presentation/widgets/home_location_marker.dart`
- `lib/features/location/presentation/pickup_selection_screen.dart`
- `lib/features/location/presentation/destination_selection_screen.dart`
- `lib/features/location/presentation/recent_destinations_bottom_sheet.dart`
- `MockData.mockCurrentLocation`, `MockData.recentDestinations`, `RecentDestination`
- Dead `EGoRecentDestinationChip`

## 5. Verification evidence

### Static analysis

```text
flutter analyze
Analyzing E-go...
No issues found! (ran in 4.9s)

dart analyze lib test
No issues found!
```

### Full test suite

```text
flutter test
+292: All tests passed!
```

### Independent auditor recheck

```text
flutter test test/unit/order_submission_test.dart test/widget/place_order_screen_test.dart test/widget/your_rides_screen_test.dart
+24: All tests passed!
```

### Web release build

```text
flutter build web --release
Compiling lib\main.dart for the Web... 130.9s
√ Built build\web
```

The build emitted only warnings: a Wasm dry-run suggestion, a CupertinoIcons font lookup
warning and Material icon tree-shaking. There were no compile errors.

### Screenshots and responsive checks

- 21 `test/screenshots/final_*_393x852.png` files generated at 393x852 logical pixels
  (786x1704 PNG).
- Responsive test matrix: 320x568, 360x800, 375x667, 375x812, 393x852, 430x932.
- Key screenshots inspected:
  - `final_home_393x852.png` — Home with bottom navigation.
  - `final_location_selection_393x852.png` — Stage 2.
  - `final_map_selection_393x852.png` — map picker.
  - `final_place_order_393x852.png` — both markers, both vehicle cards, selected Bike.
  - `final_vehicle_selection_393x852.png` — deprecated legacy screen, no auto-selection.

## 6. Corrections made during audit

1. Added submitting-state notification before order persistence.
2. Made direct `startDriverSearch()` create the pending order first when needed.
3. Removed the partial-state fallback that could invent a ride during search.
4. Wired the local `_placing` state to the Stage 3 submitting UI.
5. Removed legacy vehicle auto-selection and updated the active Rides CTA to
   `/location-selection`.

Stale tests and fake-location code were also cleaned up; the full suite is green.

## 7. Known limitations

- **Synchronous mock persistence.** `MockBookingRepository.addRide` completes synchronously,
  so the submitting spinner may not occupy a visible frame in the demo. The submitting state
  is emitted, duplicate taps are blocked and the UI controls are wired for a real async
  repository.
- **No native target or real GPS.** The workspace is web-only; real permission/GPS behavior
  cannot be verified. The shipped behavior is an honest "current location unavailable" state.
- **OSM tiles in tests.** Tile requests return HTTP 400 in widget tests; tests tolerate this.
  Screenshots use a transparent test tile provider, so maps appear flat gray.
- **Legacy routes remain.** `/vehicle-selection`, `/fare-details` and
  `/booking-confirmation` remain registered for compatibility and are not linked from the
  primary flow.
- **Demo data.** Driver assignment and pricing are simulated; no backend, live quote or real
  driver dispatch is claimed.
- **Git staging anomaly.** Several test files are staged as deleted while existing on disk.
  No staging, committing, reverting or cleaning was performed.

## 8. Definition of done

| Criterion | Status |
|---|---|
| Home destination discovery implemented | Done |
| Stage 2 Location Selection implemented | Done |
| Map Location Picker implemented | Done |
| Stage 3 Place Order implemented | Done |
| Exactly two vehicles and correct fare gating | Done |
| Exactly-once order creation | Done |
| Nullable-driver pending order and guards | Done |
| Recent destinations persistence | Done |
| Popular destinations max four | Done |
| No fake GPS/history/coordinates | Done |
| Global nav hidden on child screens, visible on Home | Done |
| Legacy route compatibility | Done |
| Responsive screenshots and visual QA | Done |
| Static analysis clean | Done |
| Full test suite green | Done |
| Web release build succeeds | Done |
| Independent audit approved | Done |

## 9. How to verify

```powershell
cd "D:\E-RICKSHAW RIDE\E-go"
flutter analyze
dart analyze lib test
flutter test
flutter build web --release
flutter test test/widget/migration_screenshot_test.dart
```

Expected: analysis clean, full suite green, web build succeeds, screenshot/responsive tests
pass. OSM HTTP 400 logs during widget tests are expected and tolerated.
