# E-GO Booking System Architecture

Status: design contract for the three-stage booking flow (Home discovery, Location Selection, Place Order).
Authoritative inputs: `docs/booking_system/booking_reference_analysis.md`, the product specification, `EGO-AGENT-INSTRUCTIONS.md`.
No application code is modified by this document.

## 1. Principles and invariants

1. Single source of truth: `AppState` (Provider/ChangeNotifier) owns all booking values. Screens hold only transient UI state (search text, map camera, map-picker candidate).
2. Separate lifecycles: `BookingStatus` remains the ride/driver FSM. `BookingStage` models the user-visible stages and the map-confirmation step. They are not merged.
3. Data honesty: no fake GPS, history, coordinates, prices, routes or driver availability. Absence is an explicit unavailable state.
4. One booking path: no second booking system, no duplicate screen per stage, no duplicate route per stage.
5. Exactly-once order: `placeOrder()` creates at most one `RideRecord` per order; duplicates return the existing reference.
6. Derived data may not outlive its inputs: any pickup/destination change clears fare, distance and vehicle options synchronously.
7. Extend existing repositories, models, tokens and widgets; do not replace them.
8. Demo boundaries stay labelled: fare is the existing `MockPricingService` estimate; driver assignment stays the existing simulated flow.
9. Global bottom nav belongs to `EGoMainShell`. Booking/location screens are root-navigator routes and hide it.

## 2. Layered architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│ Presentation: Home panel/map · LocationSelectionScreen ·              │
│ MapLocationPickerScreen · PlaceOrderScreen · shared stage widgets    │
└───────────────────────────────┬──────────────────────────────────────┘
                                │ watch/read AppState; local UI state only
┌───────────────────────────────▼──────────────────────────────────────┐
│ AppState: stage · confirmations · fare · vehicle · submission ·      │
│ order reference · validation · invalidation · exactly-once logic     │
└───────┬───────────────────────────────┬──────────────────────────────┘
        │                               │
┌───────▼──────────────────┐   ┌────────▼─────────────────────────────┐
│ Booking data             │   │ Location data                        │
│ MockVehicleRepository    │   │ LocationRepository (search only)     │
│ MockPricingService       │   │ CurrentLocationService               │
│ MockBookingRepository    │   │ RecentDestinationsStore              │
│ MockDriverRepository     │   │ PopularDestinations config           │
└───────┬──────────────────┘   └────────┬─────────────────────────────┘
        │                               │
┌───────▼───────────────────────────────▼──────────────────────────────┐
│ MockData (Jhargram dataset) · shared_preferences · OSM raster tiles  │
└──────────────────────────────────────────────────────────────────────┘
```

Dependencies point downward only. Widgets never create orders; `AppState` orchestrates. Screens may call `RecentDestinationsStore` (read/remove) and `LocationRepository.searchPlaces`.

## 3. Domain model and enums

### 3.1 `E-go/lib/core/booking_stage.dart`

```dart
enum BookingStage {
  home,
  locationSelection,
  locationConfirmation,
  vehicleSelection,
  orderSubmission,
}

enum LocationConfirmationStatus { unconfirmed, confirmed }
enum FareCalculationState { idle, loading, ready, unavailable, error }
enum OrderSubmissionState { idle, submitting, succeeded, failed }

bool isValidBookingStageTransition(BookingStage from, BookingStage to);
```

Allowed stage transitions (invalid transitions logged then ignored):

| From | To |
|---|---|
| home | locationSelection |
| locationSelection | home, locationConfirmation, vehicleSelection |
| locationConfirmation | locationSelection, home |
| vehicleSelection | locationSelection, orderSubmission, home |
| orderSubmission | vehicleSelection, home |

`locationConfirmation` is the map-picker stage. Search-in-edit does not change stage. `orderSubmission` reuses `PlaceOrderScreen` while submitting.

### 3.2 Validation — `E-go/lib/core/booking_validation.dart`

```dart
enum BookingValidationIssue {
  pickupMissing, destinationMissing, identicalLocations, invalidCoordinates,
  vehicleMissing, fareNotReady, noVehiclesAvailable, submissionInProgress,
  orderAlreadyPlaced,
}

class BookingValidationResult {
  const BookingValidationResult(this.issues);
  final List<BookingValidationIssue> issues;
  bool get isValid => issues.isEmpty;
  BookingValidationIssue? get firstIssue => issues.isEmpty ? null : issues.first;
}

bool isValidCoordinate(LatLng coordinate); // finite; lat -90..90; lng -180..180

BookingValidationResult validateBooking({
  required SavedLocation? pickup,
  required SavedLocation? destination,
  required VehicleOption? vehicle,
  required FareBreakdown? fare,
  required FareCalculationState fareState,
  required OrderSubmissionState submissionState,
  required bool hasAvailableVehicles,
});
```

Evaluation order:
1. `submissionInProgress` when `submitting`.
2. `pickupMissing` when pickup null.
3. `destinationMissing` when destination null.
4. `invalidCoordinates` when either coordinate fails `isValidCoordinate`.
5. `identicalLocations` when ids match or `MockPricingService.distanceKm(...) < 0.05` km.
6. `noVehiclesAvailable` when the loaded options are empty.
7. `vehicleMissing` when nothing is selected.
8. `fareNotReady` when fare is null or `fareState != ready`.

`PlaceOrderResult` — `E-go/lib/features/booking/domain/place_order_result.dart`:

```dart
enum PlaceOrderOutcome { success, validationFailed, alreadyPlaced, inProgress, error }

class PlaceOrderResult {
  final PlaceOrderOutcome outcome;
  final String? orderId;
  final List<BookingValidationIssue> issues;
  final String? message;
  bool get isSuccess => outcome == PlaceOrderOutcome.success;
}
```

### 3.3 Order record change

`RideRecord.driver` becomes nullable (`MockDriver? driver`) so an order exists before demo driver assignment. The order reference is `RideRecord.id` (`EGO-<epochMs>` from `MockBookingRepository.generateId()`), generated once.

- Place order: `status: RideStatus.upcoming`, `driver: null`, `bookedAt: now`, `tripId: id`.
- Driver search: `copyWith(driver: demoDriver, status: RideStatus.active)`.
- `MockBookingRepository.addRide` becomes idempotent (ignore duplicate id, return `false`).
- `ride_details_screen.dart`, `trip_completed_screen.dart`, `safety_screen.dart` guard null and show "Driver assignment pending"; no invented data.
- No parallel order entity is introduced.

## 4. AppState contract

Constructor additions (optional; defaults preserve current behaviour):

```dart
AppState({
  AuthRepository? authRepository,
  VehicleRepository? vehicleRepository,
  CurrentLocationService? currentLocationService,
  MockBookingRepository? bookingRepository,
});
```

`abstract class VehicleRepository { Future<List<VehicleOption>> getAvailableVehicles({required LatLng from, required LatLng to}); }`
`MockVehicleRepository implements VehicleRepository` with unchanged deterministic output. Injection exists only for fare loading/empty/error tests.

### 4.1 Booking fields and getters

| Field | Type | Getter | Notes |
|---|---|---|---|
| `_bookingStage` | `BookingStage` | `bookingStage` | starts `home` |
| `_pickupLocation` | `SavedLocation?` | `pickupLocation` | existing |
| `_destinationLocation` | `SavedLocation?` | `destinationLocation` | existing |
| `_pickupConfirmation` | `LocationConfirmationStatus` | `pickupConfirmation` | `confirmed` only via explicit mutator |
| `_destinationConfirmation` | `LocationConfirmationStatus` | `destinationConfirmation` | same |
| `_selectedVehicle` | `VehicleOption?` | `selectedVehicle` | existing |
| `_availableVehicles` | `List<VehicleOption>` | `availableVehicles` | existing |
| `_calculatedFare` | `FareBreakdown?` | `calculatedFare` | canonical fare for current route + vehicle |
| `_fareState` | `FareCalculationState` | `fareState` | idle/loading/ready/unavailable/error |
| `_fareError` | `String?` | `fareError` | user-facing message only |
| `_orderSubmissionState` | `OrderSubmissionState` | `orderSubmissionState` | idle/submitting/succeeded/failed |
| `_createdOrderId` | `String?` | `createdOrderId` | created order reference |
| `_currentRide` | `RideRecord?` | `currentRide` | existing |
| `_assignedDriver` | `MockDriver?` | `assignedDriver` | existing |
| `_bookingStatus` | `BookingStatus` | `bookingStatus` | existing ride lifecycle |
| `_vehiclesLoading` | `bool` | `vehiclesLoading` | unchanged |
| `_currentLocationState` | `CurrentLocationState` | `currentLocationState` | replaces fake GPS |

Derived getters:

```dart
bool get hasConfirmedPickup;
bool get hasConfirmedDestination;
bool get hasValidRoute;            // both confirmed, ids differ
double? get estimatedDistanceKm;  // calculatedFare?.distanceKm (straight-line estimate)
bool get isPlacingOrder;          // submissionState == submitting
```

### 4.2 Mutators and orchestration

| Method | Contract |
|---|---|
| `setPickupLocation(SavedLocation)` | set pickup, mark confirmed, `_invalidateRouteDerived()`, notify. No-op while submitting. |
| `setDestinationLocation(SavedLocation)` | same for destination. |
| `enterLocationSelection()` | `_setStage(locationSelection)`. |
| `enterLocationConfirmation()` | `_setStage(locationConfirmation)` before pushing the picker. |
| `returnToHomeStage()` | stage `home`, `BookingStatus.idle` when in a selection state; keeps confirmed locations. |
| `prepareVehicleSelection()` | guard `hasValidRoute`; stage `vehicleSelection`; `_transition(selectingVehicle)`; `await loadVehicles()`; returns bool. |
| `loadVehicles()` | fare `loading`; repository call; re-check route signature after await; select preferred type or first option; set fare `ready`; empty → `unavailable`; throw → `error`. |
| `selectVehicle(VehicleOption)` | accept only an option in `_availableVehicles`; set preferred type, `calculatedFare = fareBreakdown`, `ready`. Never touches locations. |
| `validateBooking()` | delegates to the validation function. |
| `placeOrder()` | exactly-once orchestration (section 6). |
| `startDriverSearch()` | retry-safe demo search bound to `createdOrderId`. |
| `requestCurrentLocation()` | explicit action only; updates `_currentLocationState`; never writes pickup. |
| `applyCurrentLocationAsPickup()` | explicit action only; requires a real coordinate. |
| `cancelRide()` / `resetToIdle()` | existing behaviour plus full booking reset. |
| `retrySearch()` | fixed to call `startDriverSearch()` (handles `failed -> searchingDriver`). |

Legacy APIs retained: `proceedToVehicleSelection()` delegates to `prepareVehicleSelection()`; `proceedToFareReview()`, `proceedToConfirmation()`, `confirmBooking()` remain for old screens/tests. `confirmBooking()` is a compatibility alias for `startDriverSearch()` that auto-creates an order if none exists.

### 4.3 Stage/status consistency

- `home`: `BookingStatus.idle`.
- `locationSelection`/`locationConfirmation`: `selectingPickup` or `selectingDestination`; both already transition to `selectingVehicle`.
- `vehicleSelection`: `selectingVehicle`.
- `orderSubmission`: `selectingVehicle -> confirmingBooking -> searchingDriver -> driverAssigned -> ...` using the existing table. No new `BookingStatus` values; `_allowedTransitions` is not edited.

## 5. Location data services

### 5.1 Current location (decision B)

No new package. The app is web-only, `geolocator` is not installed, and browser permission flows cannot be verified on the VM. The requirement is "no fake GPS", not mandatory automatic GPS, so the build ships an explicit unavailable state behind an injectable interface; a real implementation can replace it without touching screens or `AppState`.

`E-go/lib/features/location/data/current_location_service.dart`:

```dart
enum CurrentLocationAvailability {
  available, permissionDenied, permissionDeniedForever,
  serviceDisabled, unsupported, error,
}

class CurrentLocationResult {
  final CurrentLocationAvailability availability;
  final LatLng? coordinate;
  final double? accuracy;
  final String? message;
}

abstract class CurrentLocationService {
  Future<CurrentLocationResult> getCurrentLocation();
}

class UnavailableCurrentLocationService implements CurrentLocationService {
  // returns unsupported, no coordinate, no delay
}
```

- `AppState` default is `UnavailableCurrentLocationService`; screens never construct a result.
- Request only from the map picker "Use current location" action. Never on Home startup, never silent pickup overwrite.
- Messages: denied "Location permission denied. Choose your pickup on the map or search."; denied forever "Location permission is blocked. Enable it in browser settings."; disabled "Location services are off."; unsupported "Current location is not available in this build."; error "Could not get your location. Try again."
- Home shows a location dot only when `currentLocationState.coordinate != null`; this build never provides one.
- `MockData.mockCurrentLocation` is retired from call sites.

### 5.2 Recent destinations — `E-go/lib/features/location/data/recent_destinations_store.dart`

```dart
class RecentDestinationsStore {
  static const String storageKey = 'ego.recent_destinations.v1';
  static const int maxEntries = 10;

  Future<List<SavedLocation>> load();          // newest first; [] when absent/corrupt
  Future<SavedLocation?> latest();             // first entry or null
  Future<void> record(SavedLocation location); // dedupe, prepend, cap
}
```

JSON array under `ego.recent_destinations.v1`:

```json
[
  {
    "id": "s1",
    "label": "Jhargram Bazar",
    "subtitle": "Market area, Jhargram",
    "lat": 22.4701,
    "lng": 86.9152,
    "type": "market",
    "savedAt": "2026-11-17T09:30:00.000Z"
  }
]
```

Rules:

- Newest first. `record` removes an existing entry with the same `id` or coordinates equal at 5 decimal places, prepends, truncates to `maxEntries`.
- Reject empty id/label, non-finite or out-of-range coordinates.
- Unknown/missing `type` → `PlaceType.other`; missing `subtitle` → null; `savedAt` is diagnostic.
- Corrupt JSON or wrong types → empty list; never fabricate entries.
- `IconData` is not persisted; `iconForPlaceType(PlaceType)` is added to `location_model.dart` and shared.
- Write point: once per successfully created order inside `placeOrder()`, best-effort after the ride is stored. History means "ordered destination", not "browsed destination". A preference write failure never fails the order (`_historyRecordedOrderId` guard).
- Home reads `latest()` and hides the section when null. Stage 2 reads `load()` and renders rows with a 48 px clear target. Empty copy: "No recent locations yet." There is no remove/clear affordance in the UI (not requested; avoids extra location-management scope).
- No seed data. `MockData.recentDestinations` and `RecentDestination` are retired.

### 5.3 Popular destinations — `E-go/lib/features/location/data/popular_destinations.dart`

```dart
abstract final class PopularDestinations {
  static const int maxCount = 4;
  static const List<String> ids = ['s1', 's2', 's3', 's6']; // Bazar, Railway Station, Palace, Bus Stand
  static List<SuggestedPlace> resolve(); // filters MockData.suggestedPlaces, preserves order, take(4)
}
```

Only identifiers live here; names/addresses/coordinates stay in the existing Jhargram dataset. Tests assert <= 4, unique ids, resolvable entries.

## 6. Order creation boundary (F)

### 6.1 When an order is created

At the Place order tap, after synchronous validation, before navigation and before driver search:

1. `submitting` → return `inProgress`.
2. `createdOrderId != null && currentRide != null` → return `alreadyPlaced(createdOrderId)`.
3. `validateBooking()` → on issues return `validationFailed(issues)` with no mutation.
4. If status is `selectingVehicle`, transition to `confirmingBooking` (existing FSM allows it). Skip if already `confirmingBooking` (legacy path).
5. Set `orderSubmissionState = submitting` and notify before any await.
6. Generate `id`; build the immutable snapshot: pickup, destination, `selectedVehicle.type`, `calculatedFare`, `paymentMethod`, `bookedAt`, `tripId: id`, `driver: null`, `status: RideStatus.upcoming`.
7. `bookingRepository.addRide(record)` (idempotent); set `_currentRide`, `_createdOrderId`, state `succeeded`; notify.
8. Best-effort single recent-destination write for the order.
9. Return `success(id)`; unexpected errors set `failed` and return `error`.

The created record is the immutable snapshot. Later location/vehicle changes never mutate it. After success the flow replaces Stage 3 with `/searching-driver`, so post-order edits are unreachable.

### 6.2 Duplicate prevention

- UI: button disabled while `isPlacingOrder`, label "Placing order...", `PopScope(canPop: !isPlacingOrder)`.
- State: synchronous `submitting` before the first await; second call returns `inProgress`.
- Repository: `addRide` ignores an existing id; `createdOrderId` short-circuits later calls.
- Navigation: `pushReplacementNamed` prevents returning to the same Stage 3 instance.

### 6.3 Driver search reuse

`startDriverSearch()`:

1. If `createdOrderId == null`, call `placeOrder()` first (keeps the legacy `/booking-confirmation` path working).
2. `_driverSearchStarted` guard prevents duplicate loops; reset on failure/cancel/reset.
3. Transition to `searchingDriver` from `confirmingBooking`, or from `failed` on retry; if status is `selectingVehicle`, go `confirmingBooking` first. Leave the existing FSM table unchanged.
4. Existing 4 s simulated delay, then `MockDriverRepository` bike/toto demo driver.
5. If still `searchingDriver`, apply `copyWith(driver: demoDriver, status: RideStatus.active)`, update repository, set `_assignedDriver`/`_currentRide`, transition `driverAssigned`.
6. `searching_driver_screen.dart` navigates to `/driver-assigned` as today. Driver/tracking screens are unchanged.
7. Keep the existing "Demo mode: No real driver will be dispatched." notice on Stage 3.

`retrySearch()` calls `startDriverSearch()` directly; the old double-transition bug is removed.

## 7. Fare model (D)

- Only source: `MockPricingService.calculateFare` via `VehicleRepository.getAvailableVehicles`. No new price table or client math.
- States: `idle` (no valid route/vehicle), `loading`, `ready`, `unavailable` (no vehicles), `error` (repository threw).
- `loadVehicles()` start: fare `loading`, calculated fare null, capture route signature (`pickup.id|destination.id|lat,lng...`). After the await, discard results if the signature changed.
- Success: select preferred type (last user choice) or first option; `calculatedFare = option.fareBreakdown`; `ready`.
- `selectVehicle(v)`: accept only a type in current options; set fare from the option; locations untouched.
- Pickup/destination mutation: clear `_availableVehicles`, `_selectedVehicle`, `_calculatedFare`, `_fareError`; `fareState = idle`. Retain `_preferredVehicleType` for the next load.
- UI renders a fare only when `ready` and non-null: loading "Estimating fare..."; unavailable "No vehicles available for this route"; error "Could not calculate fare" + retry; idle "Select a vehicle to see the fare".
- Distance is `calculatedFare.distanceKm`, labelled "Approx. straight-line distance" with the existing demo-estimate disclaimer.

## 8. Map and route summary (E)

- No routing service exists, so no polyline/route geometry is drawn anywhere.
- Stage 3: `FlutterMap` + existing OSM `TileLayer` pattern, camera fitted to both coordinates (`CameraFit.coordinates`), `EGoPickupMarker` and `EGoDestinationMarker` from `shared/widgets/location_components.dart`.
- A visible `RouteUnavailableNotice` chip states: "Route preview unavailable. Showing pickup and destination markers."
- Future geometry hook: a real routing service would set `List<LatLng>? routePolyline`; `PolylineLayer` renders only when non-null and non-empty. No dead field is added now.
- Labels: "Estimated fare (demo)", "Approx. straight-line distance", plus "Demo pricing — not a live quote." inside the fare card.
- Home map is interactive (pan/zoom), centered on `MockData.jhargramCenter`, with a current-location marker only when real data exists.

## 9. Navigation, screens and routes (C, I)

| Stage | Screen | Route | Notes |
|---|---|---|---|
| home | `EGoHomeScreen` | `/home` in `EGoMainShell` | interactive map + discovery panel; global nav via shell |
| locationSelection | `LocationSelectionScreen` | `/location-selection` | replaces `DestinationSelectionScreen` |
| locationConfirmation | `MapLocationPickerScreen` | `/map-location-picker` | replaces `PickupSelectionScreen`; target passed as `LocationSelectionTarget`, with an in-screen pickup/drop toggle |
| vehicleSelection / orderSubmission | `PlaceOrderScreen` | `/place-order` | replaces `VehicleSelectionScreen` |

All three are added to `EGoRouter.protectedRoutes`; all are root `MaterialPageRoute`s, so bottom nav is hidden. Add constants `locationSelection`, `mapLocationPicker`, `placeOrder`; remove `pickupSelection`, `destinationSelection`, `vehicleSelection`; update `my_rides_screen.dart:37` to `locationSelection`.

Legacy `/fare-details` and `/booking-confirmation` stay registered but deprecated: not linked from Home, Stage 2 or Stage 3, kept for existing booking/screenshot regression tests. Removing them is a later owner-approved cleanup with the same test updates.

```
Home destination field ─────────────────────► /location-selection
Home recent/popular ── setDestination ───────┬─ pickup confirmed ─► /place-order
                                             └─ no pickup ───────► /location-selection
/location-selection ── Select on map ───────► /map-location-picker
/map-location-picker ── confirm ────────────► back to /location-selection (both values kept)
/location-selection ── continue ────────────► /place-order
/place-order ── Place order ────────────────► /searching-driver → existing lifecycle
```

## 10. File structure (I)

Create:

```
E-go/lib/core/booking_stage.dart
E-go/lib/core/booking_validation.dart
E-go/lib/features/booking/domain/place_order_result.dart
E-go/lib/features/location/domain/location_selection_target.dart
E-go/lib/features/location/data/current_location_service.dart
E-go/lib/features/location/data/recent_destinations_store.dart
E-go/lib/features/location/data/popular_destinations.dart
E-go/lib/features/location/presentation/location_selection_screen.dart    (git mv from destination_selection_screen.dart)
E-go/lib/features/location/presentation/map_location_picker_screen.dart   (git mv from pickup_selection_screen.dart)
E-go/lib/features/location/presentation/widgets/location_selection_field.dart
E-go/lib/features/location/presentation/widgets/recent_location_tile.dart
E-go/lib/features/location/presentation/widgets/popular_destinations_section.dart
E-go/lib/features/home/presentation/widgets/home_destination_panel.dart
E-go/lib/features/home/presentation/widgets/home_map_view.dart
E-go/lib/features/booking/presentation/place_order_screen.dart            (git mv from vehicle_selection_screen.dart)
E-go/lib/features/booking/presentation/widgets/place_order_map_summary.dart
E-go/lib/features/booking/presentation/widgets/vehicle_option_card.dart
E-go/lib/features/booking/presentation/widgets/fare_summary_panel.dart
```

Modify: `app/app_state.dart`, `app/router.dart`, `features/booking/data/booking_repository.dart`, `features/booking/data/vehicle_repository.dart` (add interface), `features/location/data/location_repository.dart` (search only), `features/location/domain/location_model.dart` (icon helper), `features/home/presentation/home_screen.dart`, `features/rides/presentation/screens/my_rides_screen.dart`, `features/booking/presentation/ride_details_screen.dart`, `trip_completed_screen.dart`, `features/safety/presentation/screens/safety_screen.dart` (nullable driver guards).

Retire after zero references: `MockData.recentDestinations`, `MockData.mockCurrentLocation`, `RecentDestination`, `home_map_painter.dart`, `home_location_marker.dart`, `recent_destinations_bottom_sheet.dart`. Do not retire `saved_places_screen.dart` or `/saved-places` (Profile links).

## 11. Decision log

| ID | Decision | Rationale / trade-off |
|---|---|---|
| A | Keep `BookingStatus`; add `BookingStage`, confirmation/fare/submission enums and fields on `AppState`. | The ride FSM is correct and heavily tested for driver/trip lifecycle; merging stages would invalidate transitions used by searching/tracking. The two coordinate systems are linked by the consistency table in 4.3. |
| B | No new package. `CurrentLocationService` with `UnavailableCurrentLocationService`; real implementation is drop-in later. | Honest and deterministic. Avoids an unverifiable web permission flow, pubspec churn and plugin risk. The spec forbids fake GPS, not manual pickup. Trade-off: no automatic locate in this release; the button reports unavailable. |
| C | Rename/replace the three existing screens in place; add stage routes; keep `/fare-details` and `/booking-confirmation` as deprecated legacy routes. | One screen per stage, no duplicates. Fare/confirmation are pre-existing distinct screens needed by regression tests and are no longer linked from the primary flow. |
| D | Fare state in `AppState`; only `MockPricingService` via `VehicleRepository`; location mutation clears fare/vehicle/options. | Single pricing source, provable invalidation. Preferred vehicle type is reapplied on reload without retaining a stale fare. |
| E | No route line; markers + explicit unavailable notice; approximate straight-line labels. | No geometry source exists; a line would be fabricated. Future hook documented without dead state. |
| F | Order created at Place order as a pending `RideRecord` with nullable driver; demo driver assigned later under the same id. | Preserves the repository, confirmation/search flow and exactly-once reference. One entity. Trade-off: small null guards in three detail screens. |
| G | Store max 10, id/coordinate dedupe, one JSON prefs key; write only after order creation; Home `latest()`, Stage 2 `load()`; popular ids `s1,s2,s3,s6`. | History means ordered destinations; one write point avoids duplicates and fake browsing history. Popular coordinates stay dataset-owned. |
| H | Full validation with inline/banner messages; disabled submitting state; modal search + scrollable Stage 2 for keyboard safety. | Explicit, testable failures. Modal search eliminates keyboard overlap; the body remains scrollable. |
| I | Feature-first paths in section 10; transient state only in screens; shared widgets for rows/cards. | Matches existing layout and avoids duplicate widgets. |
| J | Unit tests for stage/validation/store/fare/order; widget tests for all stages/nav/responsive; screenshot slugs `home`, `location_selection`, `map_selection`, `place_order`. | Covers transitions, honesty invariants, exactly-once and visual acceptance. |

## 12. Risks and owner decisions

- Nullable `RideRecord.driver` touches three detail/status screens; add guards and tests.
- Home becomes a real `flutter_map`; widget/screenshot tests must tolerate failed OSM tile requests (see implementation plan).
- Three screen renames and three route-constant removals require updating all references, including tests. Do not leave aliases (they would duplicate routes).
- Owner decision only if automatic current location becomes mandatory this release; a geolocator-backed service can be added later behind the same interface.
- Fresh installs show no recent history by design; acceptance tests assert the empty state.
