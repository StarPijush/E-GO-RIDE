// E-GO booking flow stages.
//
// `BookingStatus` (core/booking_state.dart) owns the ride lifecycle.
// `BookingStage` owns the customer journey through the booking screens.
// They are deliberately separate: a stage can be revisited (e.g. changing
// the drop location) without corrupting the ride state machine.

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

/// Returns true when moving from [from] to [to] is a supported journey.
///
/// The primary flow is:
/// home -> locationSelection -> locationConfirmation -> vehicleSelection
/// -> orderSubmission.
///
/// Back navigation and the Home "last used/popular" shortcut (which can go
/// straight to vehicle selection once a pickup exists) are also allowed.
bool isValidBookingStageTransition(BookingStage from, BookingStage to) {
  if (from == to) return true;

  switch (from) {
    case BookingStage.home:
      return to == BookingStage.locationSelection ||
          to == BookingStage.vehicleSelection;
    case BookingStage.locationSelection:
      return to == BookingStage.home ||
          to == BookingStage.locationConfirmation ||
          to == BookingStage.vehicleSelection;
    case BookingStage.locationConfirmation:
      return to == BookingStage.locationSelection ||
          to == BookingStage.vehicleSelection;
    case BookingStage.vehicleSelection:
      return to == BookingStage.home ||
          to == BookingStage.locationSelection ||
          to == BookingStage.orderSubmission;
    case BookingStage.orderSubmission:
      return to == BookingStage.home ||
          to == BookingStage.vehicleSelection;
  }
}
