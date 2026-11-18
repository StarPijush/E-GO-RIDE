# E-GO Booking Workflow

Companion to `booking_system_architecture.md`. Defines user-visible behaviour, state transitions, back rules, validation, honesty rules and edge cases for the three-stage booking flow.

## 1. Entry points and shared state

| Entry | Action |
|---|---|
| Home "Choose your destination" field | open Location Selection |
| Home last-used or popular row | set destination, then Place Order if pickup is confirmed, otherwise Location Selection |
| Rides empty-state "Book a TOTO" | open Location Selection |
| Location Selection field tap | open search for that field |
| Location Selection map icon / "Select on map" | open Map Location Picker for that field |

All entries share `AppState`. No screen keeps its own pickup/destination/vehicle/fare copy. Screens own only: search text/results, map camera, map-picker candidate, and transient error text for local async actions.

Stage variables: `bookingStage`, `pickupConfirmation`, `destinationConfirmation`, `selectedVehicle`, `calculatedFare`, `fareState`, `orderSubmissionState`, `createdOrderId`.

## 2. Stage 1 — Home

Layout (top to bottom): interactive map fills the space; white panel with 28 px rounded top overlays the map; global four-item bottom nav from `EGoMainShell`.

Panel contents, in this exact order (spec):

1. Drag handle (visual only).
2. Heading "Where to?".
3. Tappable field with search icon and placeholder "Choose your destination" (or the current destination label).
4. Conditional "Last used" section, only when `RecentDestinationsStore.latest()` returns a persisted entry.
5. "Popular places" / "Popular in Jhargram" section, at most four rows from `PopularDestinations.resolve()`.

Removed: E-GO logo pill, "Add saved place" pill, "CHOOSE LOCATION"/"SELECT VEHICLE" CTA, hand-drawn map painter, fake pickup injection. No pickup summary row is added: the spec fixes the panel contents/order and the pickup is handled in Stage 2.

Map: OSM tiles, initial center `MockData.jhargramCenter`, initial zoom ~14, interactive pan/zoom. A current-location marker is rendered only when `currentLocationState.coordinate != null`; this build never has one. The recenter action calls `requestCurrentLocation()` and shows the unavailable message via snackbar; it never moves to mock coordinates.

Tap behaviour:

- Destination field: `enterLocationSelection()` then push `/location-selection`.
- Last-used/popular row: `setDestinationLocation(savedLocation)` (confirmed), then:
  - pickup confirmed → `prepareVehicleSelection()` and push `/place-order`;
  - pickup missing → push `/location-selection` with the destination already shown in the Drop field.
- Bottom nav: existing shell behaviour unchanged.

The Home map must not request location on startup. Home history load is asynchronous; while loading show no section skeleton rows and no fake placeholders.

## 3. Stage 2 — Location Selection

Route `/location-selection`, root navigator, no global bottom nav, white background, AppBar back arrow.

Content order:

1. AppBar title "Plan your ride" (or "Set your locations"); back arrow.
2. Two separated fields:
   - "Pickup location" with pickup icon; shows `pickupLocation?.label` or placeholder "Choose pickup location".
   - "Drop location" with destination icon; shows `destinationLocation?.label` or placeholder "Choose drop location".
   - Each field is a 56 px tappable row; tapping opens the existing `EGoLocationSearchDelegate` for that target. Each row has a trailing map button ("Select on map") that opens the map picker for that target.
   - Inline error text under the invalid field after a failed continue attempt.
3. Recent locations list from `RecentDestinationsStore.load()`:
   - Each row: `iconForPlaceType(type)` icon, label, secondary address and a 48 px clear tap target. No remove/clear affordance (not requested).
   - Tapping the row sets the Drop location (recent entries are destinations), marks it confirmed, and dismisses errors.
   - Empty state: "No recent locations yet." with supporting line "Your ordered destinations will appear here." No fake rows.
4. Sticky bottom "Continue" button (inside the scroll view's bottom safe area, not overlapping the keyboard because search is modal).

Continue behaviour:

1. Validate: pickup missing → error "Choose a pickup location"; destination missing → "Choose a drop location"; identical/too close → "Pickup and drop must be different"; invalid coordinates → "Selected location is invalid."
2. On failure, show the message inline for the relevant field and do not navigate.
3. On success: `prepareVehicleSelection()`; on true push `/place-order`.

Search behaviour: `showSearch` with `EGoLocationSearchDelegate`; selecting a result sets only the active field via `setPickupLocation` or `setDestinationLocation`. Keyboard is owned by the modal search route, so the Stage 2 layout cannot be covered. If inline searching is later added, the body must remain a scroll view with `resizeToAvoidBottomInset: true` and bottom padding equal to `MediaQuery.viewInsets.bottom`.

Map picker launch: `enterLocationConfirmation()`, push `/map-location-picker` with the target, then on return `enterLocationSelection()`. A full-width "Select on map" action below the two fields opens the picker with an in-screen Pickup/Drop toggle; the small map icon on each field opens the same picker preselected to that field. The value is committed only when the picker returns a confirmed `SavedLocation`; back/cancel returns null and preserves both current values.

## 4. Map Location Picker

Route `/map-location-picker`, root navigator, no bottom nav. Argument: `LocationSelectionTarget.pickup | destination`.

- AppBar title: "Select pickup on map" / "Select drop on map"; back arrow.
- Full-screen interactive `FlutterMap`; fixed center pin; a segmented Pickup / Drop toggle at the top lets the user switch the active target without leaving the screen; "Pickup point"/"Drop point" label follows the active target.
- Initial camera: the active field's value if present, otherwise the other field's value, otherwise `MockData.jhargramCenter`. Switching the toggle recenters to that field's current value when present.
- Dragging the map produces a candidate with label "Pinned location" and subtitle with 4-decimal coordinates. No reverse geocoding, so no invented street address.
- Search icon opens `EGoLocationSearchDelegate`; selecting a result moves the camera and shows that result's real name/address.
- "Use current location" action: calls `requestCurrentLocation()`. If `available`, moves the camera to the real coordinate; any other availability shows the mapped message in a snackbar. It never substitutes mock coordinates. If pickup is set this way, the user still taps confirm.
- Bottom card: candidate label/subtitle and a confirm button ("Confirm pickup" / "Confirm drop").
- Confirm: pop with a `SavedLocation` (id preserved for dataset results; `map-pick-<epochMs>` for pinned points, type `PlaceType.other`). Stage 2 commits it to the active target; the other field is untouched. The same flow can be repeated for the other field.
- Back: pop with null; Stage 2 values unchanged.

## 5. Stage 3 — Place Order

Route `/place-order`, root navigator, no global bottom nav, background `#F5F7FA`.

Content (single scroll view, fixed bottom action bar):

1. AppBar: back arrow -> pop to Location Selection with pickup/destination preserved; title "Review your ride".
2. **Map summary card** (height ~200–220):
   - Interactive-disabled `FlutterMap` (gestures allowed but no location selection here), camera fit to pickup + destination.
   - `EGoPickupMarker` at pickup, `EGoDestinationMarker` at destination.
   - No polyline (no real route data). A subtle notice chip under/over the map: "Route preview unavailable. Showing pickup and destination markers."
3. **Location summary card**:
   - Pickup row: dark ring/dot icon, label "Pickup", name, secondary address.
   - Destination row: location pin icon, label "Drop", name, secondary address.
   - A "Change" text action returns to Location Selection (preserves values). No additional stops.
4. **Vehicle selection** — exactly two cards, single-select:
   - Electric Rickshaw (Toto): `Icons.electric_rickshaw` in a yellow/navy premium tile; name "E-Rickshaw"; subtitle "Electric · up to 3 passengers"; fare shown when `fareState == ready`.
   - Bike: `Icons.two_wheeler`; name "Bike"; subtitle "Fast · 1 passenger"; fare shown when ready.
   - Selected card: yellow-tinted border/2px, navy text, check badge. Unselected: white with divider border.
   - Selecting a vehicle updates `selectedVehicle` and `calculatedFare` immediately; locations are untouched.
5. **Fare panel**:
   - `ready`: "Estimated fare (demo)" + total `₹NN`, distance "Approx. straight-line distance X.X km", platform/base/distance breakdown (compact), disclaimer "Demo pricing — not a live quote."
   - `loading`: shimmer/inline progress + "Estimating fare...".
   - `unavailable`: "No vehicles available for this route."
   - `error`: "Could not calculate fare" + Retry.
   - `idle`: "Select a vehicle to see the fare." Never show a number in non-ready states.
6. **Demo notice** (existing wording): "Demo mode: No real driver will be dispatched."
7. **Bottom action bar**: primary button "Place order"; disabled unless `validateBooking().isValid` and not submitting. While submitting: spinner + "Placing order..." and `PopScope(canPop:false)`.

On success: app replaces the route with `/searching-driver`; the existing demo search/assignment/tracking flow runs. On failure: stay on screen, show mapped inline/snackbar message, re-enable the button. On already placed: navigate to `/searching-driver` using the existing order reference, never create another.

## 6. State transition table

| # | Event | Guard | State effect | Side effect |
|---|---|---|---|---|
| 1 | Home destination field tap | authenticated | `stage = locationSelection`; booking status `selectingDestination` | push `/location-selection` |
| 2 | Home recent/popular tap | valid persisted location | `setDestinationLocation`; `destinationConfirmation = confirmed`; invalidate derived | pickup confirmed -> `prepareVehicleSelection()` + push `/place-order`; else push `/location-selection` |
| 3 | Stage 2 field tap | none | stage unchanged | modal search; on pick `setPickupLocation`/`setDestinationLocation` |
| 4 | Stage 2 "Select on map" / field map icon | none | `stage = locationConfirmation` | push `/map-location-picker` with target |
| 5 | Picker toggle | picker mounted | active target changes (local UI only) | recenter |
| 6 | Picker search select | valid result | local candidate only until confirm | move camera |
| 7 | Picker confirm | valid candidate coordinate | `setPickupLocation`/`setDestinationLocation`; stage back to `locationSelection` | pop with location |
| 8 | Picker back | none | stage back to `locationSelection` | pop null; values unchanged |
| 9 | Stage 2 Continue | both confirmed, distinct, valid coords | `prepareVehicleSelection()` -> `stage = vehicleSelection`; status `selectingVehicle`; fare `loading` | push `/place-order` |
| 10 | Stage 2 Continue invalid | see validation | no stage change | inline errors, no navigation |
| 11 | Place Order loads vehicles | route valid | fare `loading` -> `ready`/`unavailable`/`error`; preferred vehicle re-selected | none |
| 12 | Vehicle card tap | option exists in current options | `selectedVehicle`; `calculatedFare`; fare `ready`; preferred type stored | none |
| 13 | Location changed (any path) | not submitting | clear options/vehicle/fare; fare `idle`; confirmation set | reload only when both confirmed and route valid |
| 14 | Place order tap | full validation | `submissionState = submitting`; status `confirmingBooking`; create pending ride; `createdOrderId`; `submissionState = succeeded`; record recent destination | replace route with `/searching-driver`; call driver search |
| 15 | Search retry | status `failed` | status `searchingDriver` (guarded) | demo assignment |
| 16 | Search failure | timeout | status `failed` | retry UI; no second order |
| 17 | Cancel ride | searching/assigned | existing cancel path + reset stage home | repository status cancelled; navigate home |
| 18 | Back from Stage 3 | not submitting | stage `locationSelection` | pop; locations/fare inputs preserved, derived fare recalculates |
| 19 | Back from Stage 2 | not submitting | stage `home` | pop; confirmed pickup preserved; destination preserved until reset |
| 20 | Order success -> home | after lifecycle | `resetToIdle()` clears booking fields; stage home | recent history persists independently |

## 7. Back-navigation rules

- Home: system back follows existing shell behavior (non-Home tabs -> Home tab; Home root exits).
- Stage 2 -> Home: `Navigator.pop`; keep confirmed pickup and any destination already selected; stage `home`; `BookingStatus.idle` if it was a selection state.
- Map picker -> Stage 2: pop with null on back; both fields unchanged; stage returns to `locationSelection`.
- Stage 3 -> Stage 2: pop; pickup/destination remain; vehicle/fare derived state is invalidated/reloaded if needed.
- During submission: back is blocked while `submitting`; after success the route is replaced, so Stage 3 cannot be revisited.
- Switching vehicle never resets locations. Changing a location never resets the other location.

## 8. Validation, errors and loading

Validation order (shared `validateBooking`): submission in progress; pickup missing; destination missing; invalid coordinates; identical/near-identical pickup and destination (<0.05 km or same id); no vehicle options; vehicle missing; fare not ready.

Stage 2:
- Field-level inline errors, cleared when the field changes.
- Continue disabled only while submitting (otherwise tapping shows errors).
- Search modal shows loading; empty query shows no fabricated results; empty result shows "No places found"; search failure shows error with retry.

Map picker:
- Candidate invalid/not yet moved: confirm still allowed using the initial valid coordinate.
- Location unavailable: snackbar with mapped message; no mock fallback.
- OSM tile load failure: map remains interactive over the surface; no crash.

Stage 3:
- Fare loading: disabled Place order + progress.
- Fare unavailable/error: disabled Place order + retry.
- Submission error: snackbar "Could not place order. Please try again."; state `failed`; button re-enabled.
- Already placed: navigate forward with existing order id; no duplicate record.

## 9. Recent and popular destinations

Recent:
- Source: `RecentDestinationsStore` (shared_preferences key `ego.recent_destinations.v1`, max 10).
- Written once after successful order creation, not on search/typing/browsing.
- Deduped by id or coordinates (5 decimals); newest first; corrupt data -> empty.
- Home shows only the latest entry and hides the section when none.
- Stage 2 shows the full list (max 10), each with icon/name/address/48 px tap target; tapping fills Drop and confirms it.
- No fake seed rows, no empty placeholder rows, no remove UI.

Popular:
- `PopularDestinations.resolve()` from `MockData.suggestedPlaces` ids `s1,s2,s3,s6` (Jhargram Bazar, Railway Station, Palace, Bus Stand), max 4, no duplicates.
- Selecting a popular place sets the destination and marks it confirmed; pickup is preserved. If no pickup is confirmed, Stage 2 opens with Drop prefilled.
- Popular entries are never written to recent history merely by being displayed.

## 10. Fare invalidation and recalculation

- Any pickup or destination mutation synchronously clears `availableVehicles`, `selectedVehicle`, `calculatedFare`, `fareError`; sets `fareState = idle`. No stale fare can be observed.
- Recalculation happens when `prepareVehicleSelection()` is called with both confirmed locations; it uses `MockPricingService` via `MockVehicleRepository` only.
- In-flight results are discarded when the route signature changed (compare pickup/destination ids + coordinates captured before await).
- Switching vehicle only swaps to that option's already-calculated breakdown; it does not reuse another vehicle's fare.
- Distance is straight-line (Haversine) and labelled approximate; there is no road-route distance source, so the route line is absent and disclosed.

## 11. Exactly-once order submission

- First tap synchronously sets `submitting` before any await; re-entry returns `inProgress`.
- `createdOrderId` short-circuits subsequent attempts and returns the same reference.
- `MockBookingRepository.addRide` ignores an existing id.
- Immutable order snapshot: pickup, destination, vehicle type, fare breakdown, payment method, `bookedAt`, `tripId`, driver null. Later UI/state changes cannot alter it.
- Navigation uses `pushReplacement`, so Stage 3 cannot be submitted twice from the stack.
- No real driver claim: the pending order shows "Driver assignment pending"; the existing demo search/assignment then attaches a clearly labelled demo driver.

## 12. Edge cases

- Fresh install: no recents; no current-location marker; manual pickup required.
- Pickup == destination: blocked with inline error.
- Invalid timetable/corrupt coordinates: blocked.
- Location changed after fare loaded: fare disappears immediately; no stale number.
- Vehicle options empty / repository failure: unavailable/error state with retry; order blocked.
- Back during submission: blocked; back after failure: allowed.
- Search returns empty: explicit empty state; no invented results.
- Network/tile failure: map container still renders; controls functional.
- Keyboard: search is modal; Stage 2 body scrollable with `resizeToAvoidBottomInset`; bottom action sits above safe area.
- Long names/addresses: ellipsis with maxLines; no overflow at 320–430 px.
- Permission/location unsupported: mapped snackbar; never substitutes coordinates.

## 13. Copy, accessibility and responsive rules

Canonical copy: `Where to?`, `Choose your destination`, `Pickup location`, `Drop location`, `Select on map`, `Continue`, `Place order`, `Placing order...`, `No recent locations yet.`, `Popular in Jhargram`, `Estimated fare (demo)`, `Route preview unavailable. Showing pickup and destination markers.`, `Demo pricing — not a live quote.`

Accessibility:
- All icon-only buttons have tooltips/semantics; selected vehicle exposes `selected`; error text announced via `Semantics(liveRegion: true)`.
- Minimum 48×48 touch targets; contrast uses existing navy/yellow tokens.

Responsive:
- 320/360/375/393/430 widths: map + panel use flexible heights; panel content scrolls when needed; Stage 2/3 bodies are scroll views; bottom buttons use `SafeArea`; no horizontal overflow; long labels ellipsize.

