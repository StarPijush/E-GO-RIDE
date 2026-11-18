# E-GO Customer App — Booking System Phase-0 Reference Analysis

Status: READ-ONLY discovery output. No application code, tests, or pubspec were modified.
Source of truth: the written target specification (summary supplied in the task brief). No reference
screenshots were available; written descriptions are treated as truth.
Method: direct file reads with `file:line` citations, plus targeted greps. `flutter analyze`/`flutter test`
were NOT re-run in this session; baseline status comes from the auditor's prior evidence (see section 9).

---

## 1. Existing implementation inventory

### 1.1 Home
- `E-go/lib/features/home/presentation/home_screen.dart` (563 lines), widget `EGoHomeScreen(showBottomNav)`.
- Map-first: `Expanded(child: _buildMapSection())` at `home_screen.dart:161`; map is a
  `CustomPaint(painter: const HomeMapPainter())` at `:177` — a hand-drawn cartographic illustration,
  not a live tile map. Current-location dot is `HomeCurrentLocationMarker` positioned at
  `mw*0.47 / mh*0.52` (`:187-191`).
- E-GO logo pill overlay: `_buildLogoPill()` `:217-242` (EgoLogo icon+wordmark `:236-238`),
  placed by `Positioned(top:0,left:0)` `:199-209`.
- Booking panel `_buildBookingPanel()` `:297-380`: "Where to?" heading `:338-348`;
  destination entry `_buildDestinationButton` `:382-420` with placeholder text
  `'Choose your destination'` `:403`; pickup row `_buildPickupRow` `:422-495`
  ("PICKUP LOCATION" `:451-459`, hardcoded fallback label `'Jhargram Railway Station (Plat. 1)'`
  `:461`, "Change" `:475-492`); "Add saved place" pill `_buildSavedPlacePill` `:497-524`
  (pushes `EGoRouter.savedPlaces` `:499`); CTA `_buildCTAButton` `:526-553`
  (labels `'CHOOSE LOCATION'` / `'SELECT VEHICLE'` `:542`).
- `_onChooseLocation()` `:100-120`: if destination set but pickup null it injects a **mock pickup**
  (`MockData.mockCurrentLocation`, id `'pickup-default'`) `:104-111`, then
  `proceedToVehicleSelection()` + `Navigator.pushNamed(vehicleSelection)` `:113-115`
  — bypassing any intermediate stage.
- `_loadLocation()` `:52-71` calls `LocationRepository.getCurrentLocation()` (mock, see 1.4) and
  labels it `'Jhargram Railway Station (Plat. 1)'` with id `'current-loc'` `:60-61`.
- Global bottom nav: `bottomNavigationBar: widget.showBottomNav ? _buildBottomNav() : null` `:167`;
  nav handler `_onBottomNavTap` `:122-147` pushes myRides/safety/profile routes.

### 1.2 Booking workflow (current)
Sequence as wired today:
1. Home -> destination (`EGoRouter.destinationSelection`) `home_screen.dart:79-88`.
2. `DestinationSelectionScreen` on pick -> `setDestinationLocation` + default mock pickup +
   `proceedToVehicleSelection()` + `pushReplacementNamed(vehicleSelection)`
   (`destination_selection_screen.dart:63-93`, `:95-114`).
3. `VehicleSelectionScreen` -> `proceedToFareReview()` + `pushNamed(fareDetails)`
   (`vehicle_selection_screen.dart:44-47`).
4. `FareDetailsScreen` -> `proceedToConfirmation()` + `bookingConfirmation`
   (route `router.dart:187-191`; migration harness prepares it via
   `state.proceedToFareReview()` `migration_screenshot_test.dart:57-65`).
5. `BookingConfirmationScreen` -> `AppState.confirmBooking()` (`app_state.dart:306-337`):
   transition to `searchingDriver` `:307`, **hard-coded 4 s delay** `:310`, driver fetch
   `:314-317`, `RideRecord` created with id `EGO-<epochMs>` (`booking_repository.dart:116-118`)
   `:321-334`, then `driverAssigned` `:336`.
6. `SearchingDriverScreen` -> `DriverAssignedScreen` -> `RideTrackingScreen` ->
   `TripCompletedScreen` -> `RideRatingScreen` (routes `router.dart:197-221`).
- State machine: `core/booking_state.dart` — 16-value `BookingStatus` enum `:5-22`, transition
  table `_allowedTransitions` `:25-87`, `isValidTransition` `:90-92`, `bookingStatusLabel` `:95-130`.
- `AppState` booking fields `app_state.dart:51-69`: status, pickup, destination, selectedVehicle,
  availableVehicles, assignedDriver, currentRide, paymentMethod, vehiclesLoading.
- `retrySearch()` `app_state.dart:398-401` is **broken**: it transitions
  `failed -> searchingDriver`, then calls `confirmBooking()`, which tries
  `searchingDriver -> searchingDriver` (`app_state.dart:307`); that transition is not in the table
  (`booking_state.dart:57-62`), so `_transition` returns false and `confirmBooking` returns at
  `:307` without searching.

### 1.3 Map technology
- Two coexisting approaches:
  - CustomPainter illustration: `home_map_painter.dart` (11.6 KB), `home_location_marker.dart`
    (3.4 KB) — used by Home only (`home_screen.dart:177,190`).
  - Real `flutter_map ^7` + OSM raster tiles: `pickup_selection_screen.dart:116-129`
    (`urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'`, `userAgentPackageName:
    'com.ego.customer'` `:125-126`) and `ride_tracking_screen.dart:124-128`.
- No polyline/route rendering anywhere in `lib/` (grep found no Polyline/routing usage).
  There is no routing/OSRM/ORS service and no route-data model.

### 1.4 Location service / GPS
- `LocationRepository.getCurrentLocation()` (`location_repository.dart:60-63`): 500 ms delay then
  **always returns `MockData.mockCurrentLocation`** (`LatLng(22.4550, 86.9020)`, `mock_data.dart:13`).
  This is fake GPS.
- No geolocation package exists (`pubspec.yaml:9-15` = flutter_map, latlong2, provider,
  shared_preferences only). No browser Geolocation usage found in `lib/`.
- A `CurrentLocationState` model with `coordinate/accuracy/isLoading/error` exists but is
  **unused by any screen** (`location_model.dart:53-83`).
- Consumers of the fake source: `home_screen.dart:54`, `pickup_selection_screen.dart:55`.

### 1.5 Location search
- `LocationRepository.searchPlaces` (`location_repository.dart:8-42`): 300 ms simulated latency,
  substring match over `MockData.suggestedPlaces` (12 Jhargram entries `s1-s12`,
  `mock_data.dart:52-137`); empty query returns all.
- UI: `destination_selection_screen.dart` (search field `:130-139`, results list `:223-270`
  with name `:248-253` + secondary address `:254-261` + per-`PlaceType` icon `_iconForPlaceType`
  `:277-294`) and `location_search_delegate.dart` (5.6 KB `showSearch` delegate used by
  `pickup_selection_screen.dart:70-73`).
- Search is local-only (no network, no real geocoder).

### 1.6 Location storage / recent / saved places
- **Recent destinations are fabricated**: `getRecentDestinations()`
  (`location_repository.dart:44-58`) returns the 4 hardcoded `MockData.recentDestinations`
  (`mock_data.dart:16-49`: Jhargram Bazar, Railway Station, Palace, Kendua Market).
- **`saveRecentDestination()` is a no-op**: 50 ms delay, writes nothing (`location_repository.dart:65-67`).
  Grep confirms **zero call sites** — history is never recorded even by the mock.
- `shared_preferences` is used in exactly one place: `mock_auth_repository.dart:220,226`
  (onboarding-completion flag; comment at `:4`). No location data is persisted anywhere.
- Saved places: `SavedPlacesScreen` keeps a hardcoded in-memory `List<SavedPlace>` seeded in
  `initState` (`saved_places_screen.dart:23-48`); "Add" dialog stores new places with
  `coordinate: MockData.jhargramCenter` (`:95`) and is lost on pop (`:86-98`); remove is
  in-memory only (`:115-125`). Route `/saved-places` is referenced by
  `router.dart:48,77,175-179`, `home_screen.dart:499`, and **`profile_screen.dart:89`**.
- `EGoRecentDestinationsBottomSheet` (`recent_destinations_bottom_sheet.dart:8-108`) renders
  `LocationRepository().getRecentDestinations()` `:58`; grep shows **no consumers** — unused widget.

### 1.7 Vehicle models
- `VehicleOption` (`vehicle_repository.dart:9-27`): `type`, `name`, `subtitle`, `capacity`, `iconData`,
  `fareBreakdown`, `isAvailable` (always true; no real availability data).
- `MockVehicleRepository.getAvailableVehicles` (`vehicle_repository.dart:29-67`) returns exactly two
  options: Bike (`VehicleType.bike`, capacity 1, `Icons.two_wheeler`) and Toto
  (`VehicleType.toto`, capacity 3, `Icons.electric_rickshaw`), after a simulated 400 ms delay.
- `VehicleType` lives in `core/mock_pricing.dart:9`; `Toto` is the existing product term for
  E-Rickshaw (`FareBreakdown.vehicleName` `:32-38`).

### 1.8 Fare service
- `MockPricingService` (`mock_pricing.dart:65-133`) is the only fare logic. It is explicitly
  demo-only (`:3-5`, `:63-65`).
- Haversine straight-line distance (`:67-79`), minimum effective distance 0.5 km (`:88`).
- Bike: base ₹20 + ₹10/km + ₹3 platform fee (`:91-110`).
- Toto: base ₹15 + ₹7/km + ₹2 platform fee (`:111-131`).
- Estimated trip/arrival minutes are derived from mock speeds. No route distance, no real tariff,
  no fare quote persistence. `fare_details_screen.dart` adds the in-app disclaimer
  (`:166-192`) and hardcodes rate labels (`_ratePerKm` `:262-265`) rather than reading pricing rules.

### 1.9 Order model / repository
- `RideRecord` (`booking_repository.dart:13-84`): id, pickup/destination `SavedLocation`,
  `VehicleType`, `FareBreakdown`, `MockDriver`, `RideStatus`, `bookedAt`, optional completion/
  rating/payment/tripId. `MockBookingRepository` (`:86-121`) is an in-memory list with empty seed
  (`:120`), `addRide`/`updateRide`, id `EGO-<epochMs>` (`:116-118`). Nothing is persisted.
- No order is created at the moment the user places the order: `confirmBooking()`
  (`app_state.dart:306-337`) waits a hard-coded 4 s, fabricates a driver, then adds the record.
  There is no submission state, no idempotency key, and no duplicate-submit guard at UI level.

### 1.10 Navigation / route structure
- `EGoRouter` (`router.dart:32-291`): splash/onboarding/auth; home + pickupSelection +
  destinationSelection + savedPlaces; vehicleSelection + fareDetails + bookingConfirmation +
  searchingDriver + driverAssigned + rideTracking + tripCompleted + rideRating; account/support.
- `EGoMainShell` (`ego_main_shell.dart:72-97`) owns the only global bottom nav and loads Home,
  Rides, Safety, Account in an `IndexedStack`. Routes `/home`, `/my-rides`, `/profile`, `/safety`
  mount the shell (`router.dart:160-164,224-239,262-274`); every child booking/location screen is a
  root-navigator `MaterialPageRoute`, so the global nav is hidden while they are on top
  (verified by `global_navigation_shell_test.dart:438-450`).
- `EGoRouter.protectedRoutes` (`router.dart:73-94`) redirects unauthenticated users to Login in the
  real app. Tests pass `isAuthenticated: () => true`.
- Booking entries today: Home destination button (`home_screen.dart:79-88`), Home CTA
  (`:100-120`), Rides empty-state "Book a TOTO" button
  (`rides/presentation/screens/my_rides_screen.dart:37`), both open `/destination-selection`.

### 1.11 Mock vs real boundaries
- Auth: `AuthConfig` defaults to `AUTH_MODE=mock` (`core/config/auth_config.dart:8-29`);
  `createAuthRepository()` chooses the implementation. No backend calls in the customer app.
- Locations/search/vehicles/fares/drivers/bookings: local mocks only. OSM raster tiles are the only
  network dependency (`pickup_selection_screen.dart:124-126`, `ride_tracking_screen.dart:124-128`).
- No routing/OSRM/ORS client, no geocoder, no geolocation, no live driver availability, no payment
  gateway. The app is web-only (`E-go/web/`); there are no `android/` or `ios/` project folders.

### 1.12 Tests and screenshot harness
- 42 test files currently on disk; 226 tests ran in the baseline audit: **216 passed, 10 failed**.
- Booking/location/home-related tests: `test/unit/booking_state_test.dart` (FSM table only),
  `test/unit/mock_pricing_test.dart`, `test/unit/repositories_test.dart` (asserts recent
  destinations are non-empty at `:40-45` — incompatible with "no fake history"),
  `test/widget/booking_screens_test.dart`, `test/widget/customer_journey_test.dart`,
  `test/widget/home_screen_test.dart` (asserts E-GO logo quads + Add saved place + CHOOSE LOCATION
  at `:46-66` — all must change), `test/widget/global_navigation_shell_test.dart`,
  `test/widget/migration_screenshot_test.dart`.
- Screenshot harness: `migration_screenshot_test.dart` builds each widget in a `RepaintBoundary`,
  sets a 393×852 logical surface at DPR 2, loads real fonts and Material icons, then writes
  `test/screenshots/final_<slug>_393x852.png` (786×1704 physical) via
  `RenderRepaintBoundary.toImage` (`:203-256`). It is capture-only — no golden comparison.
  Scenarios are listed at `:45-99`; there are no scenarios for pickup/destination selection yet.
  `design_system_screenshot_test.dart` captures design-token previews to
  `test/screenshots/design_system_foundation_*.png`; `global_navigation_shell_test.dart` separately
  captures shell/child-nav screenshots (`:496-700`).

## 2. Current system problems and specification gaps

| # | Problem | Evidence | Required change |
|---|---|---|---|
| P1 | Fake GPS location | `location_repository.dart:60-63`; injected as pickup in `home_screen.dart:104-111`, `destination_selection_screen.dart:77-86,99-107` | Remove fake source. Real current-location integration or an explicit location-unavailable state; never label mock coordinates as the customer's position. |
| P2 | Fake recent history | `location_repository.dart:44-58` returns hardcoded `MockData.recentDestinations`; `saveRecentDestination` is a no-op `:65-67` | Persist only destinations actually used; show last-used/recent only when real history exists; no fake placeholder. |
| P3 | No location persistence | `shared_preferences` only used for onboarding flag (`mock_auth_repository.dart:220,226`) | Add a small recent-destination store using the existing `shared_preferences` dependency. |
| P4 | Home shows logo overlay | `home_screen.dart:199-242` | Remove E-GO logo from Home. Keep the asset/branding elsewhere. |
| P5 | Home still has Add saved place and Choose Location CTA | `home_screen.dart:362-368,497-553` | Remove Add saved place from this panel. Replace old CTA workflow with destination-first discovery. |
| P6 | No last-used/popular discovery | no widgets or data in Home panel | Add last-used destination (only if real history) and max 4 popular places. |
| P7 | Home map is a static painter | `home_screen.dart:177`, `home_map_painter.dart` | Use the existing `flutter_map`/OSM technology for an interactive map; show current-location only with valid data. |
| P8 | Destination selection is one-field and auto-books | `destination_selection_screen.dart:126-273`, auto pickup injection `:77-86`, pushReplacement `:91` | Build Stage 2 with separate pickup + drop fields, map selection, suggestions, confirmation, no auto-fake pickup. |
| P9 | No map picker for destination | only pickup map screen exists (`pickup_selection_screen.dart`) | Add a map selection mode for pickup and destination with confirmation. |
| P10 | Stale fare/vehicle after location change | `setPickupLocation`/`setDestinationLocation` (`app_state.dart:255-263`) do not clear `_selectedVehicle`/`_availableVehicles` | Invalidate route/fare/vehicle on either location change; recompute when both valid. |
| P11 | No fare state / loading / error / submission state / order reference | `AppState` fields `:51-69` | Add explicit fare state, submission state, order reference, and duplicate-submit guard. |
| P12 | Order creation waits for fake driver before recording | `app_state.dart:306-337` | Place order must validate, create exactly one order through the repository/mock, then enter existing confirmation/search flow. |
| P13 | `retrySearch()` never restarts search | `app_state.dart:398-401` vs `booking_state.dart:57-62` | Fix retry or remove the broken path without regressing existing screens. |
| P14 | No route geometry | no polyline/routing code in `lib/` | Do not draw an invented route. Show markers and an explicit route-unavailable state unless real route data exists. |
| P15 | Tests encode obsolete UI | `home_screen_test.dart:46-66`; `repositories_test.dart:40-45`; `migration_screenshot_test.dart:45-99` | Update tests/harness to the new Home/Stage 2/Stage 3 requirements and real-history semantics. |

## 3. Reference behavior extracted from the written specification

Reference screenshots were not supplied; the following is the source of truth for behaviour/layout:

1. **Home (Stage 1)**: map is the primary visual; no E-GO logo; show current location only with real
   data; white bottom panel with rounded top corners overlays map; `Where to?` heading;
   tappable `Choose your destination` field; last-used destination only if real history; maximum
   four popular places; no Add saved place; global four-item bottom nav visible; selecting a
   popular/recent destination sets the shared destination and proceeds to confirmation/order flow.
2. **Location Selection (Stage 2)**: white background; back arrow; `Pickup location` field showing
   the current selected pickup and editable; `Drop location` field below; clear separation; `Select
   on map` action that opens a real interactive map and confirms pickup/destination; recent
   locations below fields with icon, name, secondary address and clear tap target; keyboard must
   not hide controls; no global bottom nav; both values validate before advancing.
3. **Place Order (Stage 3)**: map at top with pickup marker, destination marker, route line only with
   valid route data; location summary; exactly two vehicles — Electric Rickshaw/Toto and Bike —
   with premium icons, single selection; fare from existing pricing for the selected vehicle;
   changing vehicle updates fare; changing either location invalidates stale route/fare; primary
   `Place order` validates the full booking, prevents duplicate submission, creates the order via
   the existing repository/mock, preserves pickup/destination/vehicle/fare, then enters the
   existing confirmation flow; no global bottom nav.
4. **Shared booking state**: one source of truth across all stages: pickup, destination,
   confirmation status, vehicle, distance when available, fare state/value when available, stage,
   submission state, created order reference. Back navigation preserves valid selections; location
   changes invalidate stale route/fare; no fare may survive a location change.
5. **Data honesty**: no invented coordinates/history/prices/routes/GPS/driver availability.
   Popular places must come from the existing approved Jhargram dataset, max 4, no duplicates.
6. **Design**: existing E-GO tokens only (`#FFC928`, `#142B45`, `#F5F7FA`, `#FFFFFF`; bundled
   typography), premium/clean/minimal, clear selected states, comfortable 48 px touch targets,
   responsive at 320–430 logical px.

## 4. Existing reusable code and components

- State: `AppState` (Provider/ChangeNotifier) — extend rather than replace; `BookingStatus` FSM is
  reusable but does not model Stage 1/2, fare or submission; either extend it carefully or add a
  parallel stage enum with explicit mapping (Reasoner decision).
- Location model: `SavedLocation` already has id/label/subtitle/coordinate/type/createdAt — reuse.
  `LocationSearchResult` + `PlaceType` + icon mapping already exist.
- Dataset: `MockData.suggestedPlaces` (12 valid Jhargram locations) and `MockData.jhargramCenter`
  can seed popular places without inventing coordinates.
- Search: `LocationRepository.searchPlaces` local search and `EGoLocationSearchDelegate` can be
  reused/debounced; `LocationRepository` must stop returning fake current location/recents.
- Map: `flutter_map` + OSM `TileLayer` pattern from `pickup_selection_screen.dart`; `MapController`,
  center pin pattern. `latlong2` coordinates.
- Vehicles/fares: `VehicleOption`, `MockVehicleRepository` (two options), `MockPricingService` —
  reuse and keep the demo-fare boundary/labels; do not invent a new pricing table.
- Orders: `RideRecord`, `MockBookingRepository` — reuse as the development repository; add
  order-creation orchestration/submission state in `AppState`, not a second repository.
- UI: `EGoColors/EGoSpacing/EGoTypography/EGoTheme`, `EGoPrimaryButton`, `EGoSearchInput`,
  `EGoEmptyState`, `EGoSectionHeader`, `EGoRecentDestinationChip`, `EGoInfoRow`/location components,
  `EgoGooeyBottomNavigation`, `EGoMainShell`, `EgoLogo`.
- Tests/screenshots: reuse the `migration_screenshot_test.dart` capture pattern/font loader and
  extend scenarios for the three new stages.

## 5. Missing functionality

- Real (or honestly unavailable) current-location integration + permission/error states.
- Persisted recent destinations and a last-used destination query (no fake defaults).
- Configurable popular-places dataset limited to four.
- Dedicated Stage 2 screen with separate pickup/drop search, map picking for both, validation and
  keyboard-safe layout.
- Interactive Home map with conditional current-location marker.
- Stage 3 map summary with markers and conditional route line.
- Explicit fare state (idle/loading/ready/unavailable/error), stale invalidation and vehicle-driven
  recalculation.
- Order submission state/idempotent guard/order reference, wired to the existing confirmation flow.
- Tests for state transitions, location/permission handling, recent/popular limits, fare
  invalidation, duplicate submission, widget/UI + regression.
- Updated screenshot scenarios for Home, Location Selection, Map Selection and Place Order.

## 6. Files: reuse, modify, add, retire

**Reuse unchanged (or only small additions):**
- `e_go/lib/core/mock_pricing.dart` (pricing rules), `e_go/lib/features/booking/data/vehicle_repository.dart`,
  `e_go/lib/features/booking/data/driver_repository.dart`, `e_go/lib/features/booking/data/booking_repository.dart`
  (add idempotency only if needed), `e_go/lib/features/location/domain/location_model.dart`,
  `e_go/lib/core/branding/*`, `e_go/lib/app/theme/*`, shared widgets, `EGoMainShell`,
  `EgoGooeyBottomNavigation`, `ride_tracking_screen.dart`, `driver_assigned_screen.dart`,
  Profile/Safety/Help/Rides presentation (except booking entry route constants if renamed).

**Modify:**
- `lib/app/app_state.dart` — add stage/fare/submission/order state, invalidation, validation,
  duplicate guard; fix retry.
- `lib/core/booking_state.dart` — only if the Reasoner chooses to extend the FSM; keep existing
  driver lifecycle intact.
- `lib/features/location/data/location_repository.dart` — remove fake GPS/recents; integrate
  persistence and real/unavailable current location; keep search.
- `lib/features/home/presentation/home_screen.dart` — new map + destination discovery panel.
- `lib/features/location/presentation/destination_selection_screen.dart` — replace/rename as the
  Stage 2 location selection screen (separate fields, map action, recents, validation).
- `lib/features/location/presentation/pickup_selection_screen.dart` — generalise/rename as map
  location picker (pickup/destination modes) or reuse its map pattern.
- `lib/features/booking/presentation/vehicle_selection_screen.dart` — evolve into Stage 3 place
  order screen (map summary, 2 vehicle cards, fare, Place order), or introduce `place_order_screen.dart`
  and retire the old one only after all references/tests are updated.
- `lib/app/router.dart` — route wiring for stage 2/map picker/place order; update protected routes
  and any renamed constants; ensure child screens stay outside the shell.
- `lib/features/rides/presentation/screens/my_rides_screen.dart:37` — booking entry route if renamed.
- `lib/shared/widgets/*` — only shared additions if justified (vehicle card, location field).
- Tests/screenshot harness as listed in section 8.

**Add (suggested; Reasoner to approve exact set):**
- `lib/features/location/data/recent_destinations_store.dart` (shared_preferences persistence,
  dedupe, most-recent-first, max entries).
- `lib/features/location/data/popular_destinations.dart` (configurable max-4 dataset using existing
  Jhargram places).
- `lib/features/location/data/current_location_service.dart` (real integration or honestly
  unavailable; permission/error state; no fake fallback).
- `lib/features/location/presentation/location_selection_screen.dart` (or renamed equivalent).
- `lib/features/location/presentation/map_location_picker_screen.dart` (or generalised equivalent).
- `lib/features/booking/presentation/place_order_screen.dart` (or evolve existing vehicle screen).
- Focused widgets: destination field, location history tile, popular place section, vehicle card,
  fare summary, place-order button.
- Tests: booking state/location store/fare invalidation/order submission + widget tests + screenshots.

**Retire only after proving unused and updating all references:**
- Fake recent data (`MockData.recentDestinations`), `EGoRecentDestinationsBottomSheet` (unused),
  old one-field destination flow, old Home `pickupSelection` entry and `Add saved place` pill.
- Do **not** remove `SavedPlacesScreen` or the `/saved-places` route: Profile still links to it
  (`profile_screen.dart:89`) and screenshots cover it.

## 7. Recent/popular destination persistence proposal (for Reasoner approval)

- Use the existing `shared_preferences` dependency. Add `RecentDestinationsStore` under
  `lib/features/location/data/` storing a JSON list of serialized `SavedLocation` records
  (id, label, subtitle, lat, lng, type name, createdAt). Max ~10 entries; newest first; dedupe by
  coordinate/id; reject invalid coordinates (NaN/out of range); tolerate corrupt JSON by returning
  empty. Write only when a destination is actually used (after successful selection/booking per
  product decision), never from search typing.
- Home asks the store for the most recent entry; if empty, hides the last-used section entirely.
- Popular: a small const/configurable list in `popular_destinations.dart`, max 4, selected from
  existing `MockData.suggestedPlaces` entries (valid Jhargram coordinates, no duplicates).
  Reasoner/owner should choose which four (suggest Bazar, Railway Station, Palace, Bus Stand).
- Stage 2 history list reads the same store (not `LocationRepository` hardcoded mocks) and shows
  only persisted entries. Empty state is an explicit "No recent locations yet" message, not fake
  rows.

## 8. Test inventory and baseline

Baseline (independently verified by Auditor, Flutter 3.41.6): `flutter analyze` clean;
`flutter test` = **216 passed, 10 failed**. Exact failing tests:
1. `test/integration/auth_flow_test.dart` — "logout clears the session and returns to Login"
   (pre-existing `pumpAndSettle` timeout; unrelated to booking).
2. `test/widget/booking_screens_test.dart` — "MyRidesScreen renders tabs and lists" (expects
   removed `Shared` tab) — obsolete.
3. `test/widget/booking_screens_test.dart` — "ProfileScreen renders account options and navigation
   items" (case mismatch `Help & Support` vs `Help & support`) — obsolete.
4–10. `test/widget/my_rides_screen_test.dart` — seven failures due to the screen redesign
   (`RidesHeader`, `Shared`, `BookTotoButton`, ambiguous `Bike`, icon-based nav, responsive CTA).
   These are stale tests, not current booking-logic failures.

Tests that the new specification invalidates or requires updating:
- `test/widget/home_screen_test.dart:46-66` — logo present / Add saved place / CHOOSE LOCATION
  assertions must be replaced with new Home assertions (map, no logo, Where to?, recents/popular,
  nav).
- `test/unit/repositories_test.dart:40-45` — assumes hardcoded recent history; must assert empty
  initial history + persistence/dedupe after saving instead.
- `test/widget/migration_screenshot_test.dart:45-99` — Home/vehicle_selection/fare_details/
  booking_confirmation scenarios and screenshot PNGs must be updated; add location-selection, map
  picker and place-order scenarios.
- `test/widget/global_navigation_shell_test.dart:438-450` — destination selection route must still
  hide bottom nav (or be updated to the renamed Stage 2 route).
- `test/widget/booking_screens_test.dart` and `test/widget/customer_journey_test.dart` — need
  updates for the new stage/fare/submission API while preserving ride lifecycle coverage.
- `test/unit/booking_state_test.dart` — update only if the FSM is extended; keep driver/trip
  transition tests green.
- Add tests for: initial/selected/updated pickup/destination, fare invalidation/recalculation,
  vehicle switching, submission/dedupe, recents empty/save/dedupe/order, popular ≤4, permissions/
  GPS unavailable, map selection, validation, nav visibility, responsive 320/360/375/393/430.

## 9. Environment constraints

- **Web-only customer app**: only `E-go/web/` exists; no Android/iOS project. `flutter build web`
  is the supported build. Native permission dialogs/GPS cannot be verified here. Any real
  browser-geolocation integration can only be smoke-tested manually in Chrome; widget tests run on
  the Dart VM and must inject a fake/permission-state service.
- **No routing service**: route line may only be rendered if a real route/geometry source is added.
  The current fare uses Haversine; that is a distance estimate, not a road route.
- **OSM tiles in widget tests**: `flutter_map` `TileLayer` performs network image requests; tests
  may log tile errors but must not fail. Prefer injecting a lightweight tile provider or tolerate
  failed tiles in screenshots; never let network state cause flaky exceptions.
- **Screenshots**: capture-only harness (`toImage`), not golden comparisons. Physical files are
  786×1704 for a 393×852 logical viewport. New scenarios must load real fonts/icons to be judgeable.
- **No backend**: keep mock repository boundary and demo labels; do not claim live drivers/prices.
- **Git index anomaly**: several old tests are staged as deleted while present on disk. Do not commit
  or stage during this task unless explicitly asked; resolve only with owner approval.
- **AUTH_MODE mock**: default; auth tests need `SharedPreferences.setMockInitialValues({})`.

## 10. Risks / open questions for the Reasoner

1. Extend the existing `BookingStatus` FSM with stage/fare/submission states, or keep the FSM for
   ride lifecycle and add a separate `BookingStage` + explicit mapping? Avoid invalid-transition
   regressions in `SearchingDriverScreen`/`DriverAssignedScreen`.
2. Stage 2: replace `DestinationSelectionScreen` in place (rename file/class/route) vs add a new
   screen and retire the old route; how to keep the Rides "Book" entry and shell-nav tests green.
3. Stage 3: evolve `VehicleSelectionScreen` into Place Order vs create `PlaceOrderScreen`; what
   happens to `/fare-details` and `/booking-confirmation` in the new flow (keep as legacy, bypass,
   or remove from the primary path).
4. Where does fare calculation live (existing `MockPricingService` via vehicle repo vs a new fare
   controller/state), and when exactly is it invalidated/recomputed? How is "unavailable" modeled?
5. What is the "order created" boundary: on Place order (before driver search) vs after mock driver
   assignment? How to guarantee exactly-once creation and preserve existing confirmation/tracking?
6. How to implement current location honestly in a web-only app with no geolocator dependency:
   browser Geolocation integration vs explicit unavailable state + manual pickup. If unavailable,
   how is permission handling/error state represented and tested?
7. Which four popular places are approved, and where does the configurable dataset live?
8. When are recent destinations written — on destination selection, on Place order, or on
   successful order creation? How many are retained and how are duplicates resolved?
9. How to present map selection for pickup vs destination in one picker (mode argument) and how
   confirmation returns to Stage 2 without losing the other value.
10. How to keep the existing fare/confirmation screens functioning for regression while the new
    three-stage path bypasses some of them.

