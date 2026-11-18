// E-GO booking validation.
//
// Single source of truth for "can the customer place this order?".
// UI screens and AppState must use this instead of duplicating checks.

import 'package:latlong2/latlong.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/location/domain/location_model.dart';

enum BookingValidationIssue {
  submissionInProgress,
  pickupMissing,
  destinationMissing,
  pickupInvalidCoordinates,
  destinationInvalidCoordinates,
  sameLocation,
  vehicleOptionsLoading,
  noVehicleOptions,
  vehicleMissing,
  fareNotReady,
}

class BookingValidationResult {
  const BookingValidationResult(this.issues);

  final List<BookingValidationIssue> issues;

  bool get isValid => issues.isEmpty;

  BookingValidationIssue? get firstIssue =>
      issues.isEmpty ? null : issues.first;

  String get message {
    final issue = firstIssue;
    if (issue == null) return '';
    switch (issue) {
      case BookingValidationIssue.submissionInProgress:
        return 'Your order is already being placed.';
      case BookingValidationIssue.pickupMissing:
        return 'Choose a pickup location.';
      case BookingValidationIssue.destinationMissing:
        return 'Choose a drop location.';
      case BookingValidationIssue.pickupInvalidCoordinates:
        return 'The pickup location is not valid.';
      case BookingValidationIssue.destinationInvalidCoordinates:
        return 'The drop location is not valid.';
      case BookingValidationIssue.sameLocation:
        return 'Pickup and drop cannot be the same.';
      case BookingValidationIssue.vehicleOptionsLoading:
        return 'Vehicles are still loading.';
      case BookingValidationIssue.noVehicleOptions:
        return 'No vehicles are available right now.';
      case BookingValidationIssue.vehicleMissing:
        return 'Select a vehicle.';
      case BookingValidationIssue.fareNotReady:
        return 'Fare is not ready yet.';
    }
  }
}

/// Coordinates must be finite, in range and not the null-island placeholder.
bool isValidCoordinate(LatLng? coordinate) {
  if (coordinate == null) return false;
  final lat = coordinate.latitude;
  final lng = coordinate.longitude;
  if (!lat.isFinite || !lng.isFinite) return false;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return false;
  if (lat == 0 && lng == 0) return false;
  return true;
}

/// Validates a booking in a deterministic order.
///
/// [availableVehicleCount] and [hasSelectedVehicle] keep this core helper
/// independent of the vehicle feature layer.
BookingValidationResult validateBooking({
  required SavedLocation? pickup,
  required SavedLocation? destination,
  required FareCalculationState fareState,
  required bool vehiclesLoading,
  required int availableVehicleCount,
  required bool hasSelectedVehicle,
  required bool isSubmitting,
  double sameLocationKm = 0.05,
}) {
  if (isSubmitting) {
    return const BookingValidationResult([
      BookingValidationIssue.submissionInProgress,
    ]);
  }

  if (pickup == null) {
    return const BookingValidationResult([BookingValidationIssue.pickupMissing]);
  }
  if (destination == null) {
    return const BookingValidationResult([
      BookingValidationIssue.destinationMissing,
    ]);
  }
  if (!isValidCoordinate(pickup.coordinate)) {
    return const BookingValidationResult([
      BookingValidationIssue.pickupInvalidCoordinates,
    ]);
  }
  if (!isValidCoordinate(destination.coordinate)) {
    return const BookingValidationResult([
      BookingValidationIssue.destinationInvalidCoordinates,
    ]);
  }

  final distanceKm = MockPricingService.distanceKm(
    pickup.coordinate,
    destination.coordinate,
  );
  if (distanceKm < sameLocationKm) {
    return const BookingValidationResult([BookingValidationIssue.sameLocation]);
  }

  if (vehiclesLoading) {
    return const BookingValidationResult([
      BookingValidationIssue.vehicleOptionsLoading,
    ]);
  }
  if (availableVehicleCount == 0) {
    return const BookingValidationResult([
      BookingValidationIssue.noVehicleOptions,
    ]);
  }
  if (!hasSelectedVehicle) {
    return const BookingValidationResult([BookingValidationIssue.vehicleMissing]);
  }
  if (fareState != FareCalculationState.ready) {
    return const BookingValidationResult([BookingValidationIssue.fareNotReady]);
  }

  return const BookingValidationResult([]);
}
