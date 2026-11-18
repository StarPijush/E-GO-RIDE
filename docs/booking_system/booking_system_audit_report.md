# E-GO Booking System — Audit Report

Date: 17 November 2026
App: `D:\E-RICKSHAW RIDE\E-go`
Documents audited: `booking_reference_analysis.md`, `booking_system_architecture.md`,
`booking_workflow.md`, `booking_implementation_plan.md`

Final verdict: **APPROVED** for the implemented customer booking transformation, with the
limitations listed in section 7.

## 1. Scope

The audit covered the customer booking path:

`Home destination discovery -> Stage 2 Location Selection -> Map Location Picker ->
Stage 3 Place Order -> existing searching/driver-assignment flow`

It also covered shared booking state, validation, fare gating, recent/popular destinations,
order exactly-once behavior, nullable-driver handling, navigation visibility, legacy route
compatibility, tests, screenshots, static analysis and the web release build.

## 2. Audit method and evidence

The independent auditor inspected the docs and the implementation, then ran analysis and
targeted tests. The orchestrator completed the full-suite, screenshot and web-build checks.
The first auditor pass reached its step limit and returned preliminary findings only; those
findings were fixed and the auditor rechecked the five corrections in a second pass and
returned **APPROVED**.

| Check | Command | Actual result |
|---|---|---|
| Static analysis | `flutter analyze` | `No issues found! (ran in 4.9s)` |
| Static analysis | `dart analyze lib test` | `No issues found!` |
| Targeted post-fix tests | `flutter test test/unit/order_submission_test.dart test/unit/booking_flow_state_test.dart test/widget/place_order_screen_test.dart test/widget/your_rides_screen_test.dart test/widget/booking_screens_test.dart test/widget/customer_journey_test.dart` | `+43: All tests passed!` |
| Independent auditor recheck | `flutter test test/unit/order_submission_test.dart test/widget/place_order_screen_test.dart test/widget/your_rides_screen_test.dart` | `+24: All tests passed!` |
| Full regression suite | `flutter test` | `+292: All tests passed!` |
| Web release build | `flutter build web --release` | `√ Built build\web` (warnings only) |
| Screenshot generation | `flutter test test/widget/migration_screenshot_test.dart` (part of full suite) | All screenshot and responsive checks passed |

Known benign test noise: OSM tile requests return HTTP 400 in widget tests because the test
harness does not use network tiles. The tests tolerate these errors and assert widget
structure/markers, not tile pixels.

## 3. Requirement verification matrix

| Requirement | Verdict | Evidence |
|---|---|---|
| Stage flow `home -> locationSelection -> locationConfirmation -> vehicleSelection -> orderSubmission` | PASS | `booking_stage.dart`; stage transition tests in `booking_flow_state_test.dart`; Home/Stage 2/Stage 3 widget tests |
| Home is map-first with destination discovery, no obsolete Home sections | PASS | `home_screen.dart`, `home_map_view.dart`, `home_destination_panel.dart`; `home_destination_panel_test.dart`, `home_screen_test.dart` |
| Home shows global four-item bottom nav; booking child screens hide it | PASS | `EGoMainShell`; `global_navigation_shell_test.dart`; screenshot `final_home_393x852.png` |
| Stage 2 has honest empty state, pickup/drop fields, recent and popular sections | PASS | `location_selection_screen.dart`; `location_selection_screen_test.dart` |
| Map picker starts with no invented candidate; Confirm disabled until user action | PASS | `map_location_picker_screen.dart`; `map_location_picker_test.dart` |
| Map picker supports Pickup/Drop toggle, search, confirm and back | PASS | `map_location_picker_test.dart` |
| Stage 3 shows map summary, both locations, exactly two vehicle cards and fare panel | PASS | `place_order_screen.dart`, `place_order_map_summary.dart`, `vehicle_option_card.dart`, `fare_summary_panel.dart`; `place_order_screen_test.dart` |
| Exactly two vehicles: Bike and E-Rickshaw/Toto | PASS | `MockVehicleRepository`; `booking_flow_state_test.dart`; `place_order_screen_test.dart` |
| No vehicle auto-selected in Stage 3 | PASS | `place_order_screen_test.dart`; screenshot `final_place_order_393x852.png` |
| Fare hidden until a vehicle is selected and fare is ready | PASS | `fare_summary_panel.dart`; `place_order_screen_test.dart` |
| Fares come only from `MockPricingService`; Bike 20 + 10/km + 3, Toto 15 + 7/km + 2; min 0.5 km | PASS | `mock_pricing.dart`; fare tests |
| No road-route geometry is invented; straight-line distance is labelled approximate | PASS | `place_order_map_summary.dart`; route-unavailable notice in screenshot |
| Exactly-once order creation | PASS | `createdOrderId` short-circuit, submitting guard, idempotent `MockBookingRepository.addRide`, `pushReplacement`; `order_submission_test.dart` |
| Pending order uses `RideStatus.upcoming`, nullable driver and "Driver assignment pending" | PASS | `app_state.dart`, `booking_repository.dart`; nullable-driver guards in ride details/trip completed/safety; tests |
| Duplicate taps cannot create a second order | PASS | `place_order_screen_test.dart` double-tap test; repository idempotence test |
| Recent destinations persist only after a successful order, max 10, newest first, deduped, corrupt -> empty | PASS | `recent_destinations_store.dart`; `recent_destinations_store_test.dart`; `order_submission_test.dart` |
| Popular destinations are max 4 from `s1,s2,s3,s6`; never written to recents by display alone | PASS | `popular_destinations.dart`; `popular_destinations_test.dart`; `home_destination_panel_test.dart` |
| No fake GPS, current location or coordinates | PASS | `UnavailableCurrentLocationService`; search-only `LocationRepository`; `current_location_test.dart`; map picker honesty tests |
| Home current-location marker only appears with real data | PASS | `home_map_view.dart`; current-location tests |
| Legacy `/pickup-selection` and `/destination-selection` redirect to the new screens | PASS | `router.dart`; route tests |
| New routes `/location-selection`, `/map-location-picker`, `/place-order` | PASS | `router.dart`; route tests |
| Saved Places and `/saved-places` remain available | PASS | `saved_places_screen.dart`; Profile navigation; screenshot `final_saved_places_393x852.png` |
| Rides "Book a TOTO" still opens the booking flow | PASS | Active `MyRidesScreen` now pushes `EGoRouter.locationSelection`; `your_rides_screen_test.dart` |
| Responsive layouts across target viewports | PASS | `migration_screenshot_test.dart`; 320x568, 360x800, 375x667, 375x812, 393x852, 430x932 |
| Screenshots at 393x852 | PASS | 21 `final_*_393x852.png` files generated and inspected |

## 4. Defects found and corrected

The first auditor pass found five low/medium issues. All were corrected and rechecked:

1. **Submitting state was not announced before persistence.**
   `_placeOrder()` set `OrderSubmissionState.submitting` but did not notify listeners before
   writing the ride. It now calls `notifyListeners()` while submitting, before
   `addRide`. A unit test asserts that listeners observe `submitting` and then `succeeded`.

2. **Direct `startDriverSearch()` could run without a pending order.**
   The search method now creates the pending order first when `createdOrderId` is null and
   only proceeds on success. A unit test covers the direct-call path.

3. **Driver-search fallback invented a ride from partial state.**
   The `_pickupLocation!` / `_destinationLocation!` fallback was removed. If the pending
   ride is missing, search fails honestly via `handleSearchFailure()` instead of creating an
   unrequested record.

4. **Stage 3 submitting UI was not wired to local state.**
   `_placing` is now set with `setState`, and `isPlacing = isSubmitting || _placing` drives
   the disabled button, `PopScope`, back button and "Placing order..." spinner.

5. **Legacy vehicle selection auto-selected the first vehicle.**
   Auto-selection was removed from the deprecated `VehicleSelectionScreen`; it now requires
   an explicit choice. The active Rides CTA was also changed from the legacy
   `/destination-selection` constant to `/location-selection`.

Stale test and legacy-data cleanup completed during the same correction cycle:

- `booking_screens_test.dart` labels and coordinates updated to the current UI/data.
- Stale duplicate `test/widget/my_rides_screen_test.dart` removed; active Rides coverage is
  `your_rides_screen_test.dart`.
- Ride-details navigation test added to `your_rides_screen_test.dart`.
- Fake recent/current-location code removed from `LocationRepository`, `MockData` and tests.
- Obsolete pickup/destination selection screens, home map painter, home location marker and
  recent-destinations bottom sheet removed.
- `global_navigation_shell_test.dart` now checks the Location Selection route.
- `auth_flow_test.dart` passed on a targeted rerun and in the full suite.

## 5. Visual QA

Key screenshots inspected:

- `test/screenshots/final_home_393x852.png`: map-first Home with destination panel and global
  bottom navigation visible.
- `test/screenshots/final_location_selection_393x852.png`: Stage 2 with honest empty state.
- `test/screenshots/final_map_selection_393x852.png`: full-screen map picker, light map surface,
  circular current-location control.
- `test/screenshots/final_place_order_393x852.png`: both route markers, both vehicle cards,
  Bike selected, fare total and enabled Place order button.
- `test/screenshots/final_vehicle_selection_393x852.png`: deprecated legacy screen now shows
  both cards unselected and Continue disabled; no auto-selection.

Maps in screenshots are flat gray because the screenshot harness injects a transparent
`TestTileProvider`. This is a test-harness limitation, not a production map failure.

## 6. Residual risks and accepted deviations

- **Synchronous mock persistence.** `MockBookingRepository.addRide` is synchronous, so the
  submitting state is emitted but the spinner may not occupy a visible frame in the demo.
  The state, duplicate guard, disabled controls and `PopScope` are implemented; a real
  asynchronous persistence layer would surface the spinner naturally.
- **No native target / no real GPS.** The app is web-only in this workspace. Real
  permission/GPS behavior cannot be verified; the shipped `UnavailableCurrentLocationService`
  reports unavailable honestly and never substitutes coordinates.
- **OSM tiles in tests.** Network tile requests fail with HTTP 400 under widget tests; the
  harness tolerates them. Real OSM tile rendering was not verified in a browser.
- **Deprecated legacy routes remain.** `/vehicle-selection`, `/fare-details` and
  `/booking-confirmation` remain registered for compatibility. They are not linked from the
  primary flow. `/vehicle-selection` no longer auto-selects a vehicle.
- **Demo boundaries.** Driver assignment and pricing are simulated; no backend, real driver
  dispatch or live quote is claimed.
- **Git staging anomaly.** Several test files are staged as deleted while existing on disk.
  Nothing was staged, committed, reverted or cleaned during this work.

## 7. Audit conclusion

The implemented booking flow matches the written contract for the customer path, preserves
the existing ride lifecycle, enforces exactly-once order creation, keeps data honest, and
passes static analysis, the full test suite and the web release build. The five correction
items were independently rechecked and approved.

**Final status: APPROVED.**
