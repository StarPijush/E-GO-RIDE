import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/features/location/domain/location_model.dart';

const _pickup = SavedLocation(
  id: 'pickup',
  label: 'Jhargram Station',
  coordinate: LatLng(22.4529, 86.9003),
);

const _destination = SavedLocation(
  id: 'destination',
  label: 'Jhargram Bazar',
  coordinate: LatLng(22.4701, 86.9152),
);

BookingValidationResult _validate({
  SavedLocation? pickup = _pickup,
  SavedLocation? destination = _destination,
  FareCalculationState fareState = FareCalculationState.ready,
  bool vehiclesLoading = false,
  int availableVehicleCount = 2,
  bool hasSelectedVehicle = true,
  bool isSubmitting = false,
}) {
  return validateBooking(
    pickup: pickup,
    destination: destination,
    fareState: fareState,
    vehiclesLoading: vehiclesLoading,
    availableVehicleCount: availableVehicleCount,
    hasSelectedVehicle: hasSelectedVehicle,
    isSubmitting: isSubmitting,
  );
}

void main() {
  group('validateBooking', () {
    test('valid booking has no issues', () {
      final result = _validate();
      expect(result.isValid, isTrue);
      expect(result.issues, isEmpty);
      expect(result.message, isEmpty);
    });

    test('submission in progress wins over missing locations', () {
      final result = _validate(pickup: null, isSubmitting: true);
      expect(result.isValid, isFalse);
      expect(result.firstIssue, BookingValidationIssue.submissionInProgress);
    });

    test('missing pickup is reported', () {
      final result = _validate(pickup: null);
      expect(result.firstIssue, BookingValidationIssue.pickupMissing);
      expect(result.message, 'Choose a pickup location.');
    });

    test('missing destination is reported', () {
      final result = _validate(destination: null);
      expect(result.firstIssue, BookingValidationIssue.destinationMissing);
      expect(result.message, 'Choose a drop location.');
    });

    test('invalid pickup coordinates are rejected', () {
      const invalid = SavedLocation(
        id: 'bad',
        label: 'Nowhere',
        coordinate: LatLng(0, 0),
      );
      final result = _validate(pickup: invalid);
      expect(
        result.firstIssue,
        BookingValidationIssue.pickupInvalidCoordinates,
      );
    });

    test('invalid destination coordinates are rejected', () {
      const invalid = SavedLocation(
        id: 'bad',
        label: 'Nowhere',
        coordinate: LatLng(91, 0),
      );
      final result = _validate(destination: invalid);
      expect(
        result.firstIssue,
        BookingValidationIssue.destinationInvalidCoordinates,
      );
    });

    test('pickup and drop cannot be the same', () {
      final result = _validate(destination: _pickup);
      expect(result.firstIssue, BookingValidationIssue.sameLocation);
      expect(result.message, 'Pickup and drop cannot be the same.');
    });

    test('vehicle loading blocks placement', () {
      final result = _validate(vehiclesLoading: true);
      expect(result.firstIssue, BookingValidationIssue.vehicleOptionsLoading);
    });

    test('no vehicle options blocks placement', () {
      final result = _validate(availableVehicleCount: 0);
      expect(result.firstIssue, BookingValidationIssue.noVehicleOptions);
    });

    test('missing vehicle selection blocks placement', () {
      final result = _validate(hasSelectedVehicle: false);
      expect(result.firstIssue, BookingValidationIssue.vehicleMissing);
      expect(result.message, 'Select a vehicle.');
    });

    test('fare must be ready before placing an order', () {
      final result = _validate(fareState: FareCalculationState.loading);
      expect(result.firstIssue, BookingValidationIssue.fareNotReady);
    });

    test('validation order checks pickup before destination', () {
      final result = _validate(pickup: null, destination: null);
      expect(result.issues, [BookingValidationIssue.pickupMissing]);
    });
  });

  group('isValidCoordinate', () {
    test('rejects null, out-of-range and null-island coordinates', () {
      expect(isValidCoordinate(null), isFalse);
      expect(isValidCoordinate(const LatLng(0, 0)), isFalse);
      expect(isValidCoordinate(const LatLng(90.1, 86.9)), isFalse);
      expect(isValidCoordinate(const LatLng(22.4, 180.1)), isFalse);
    });

    test('accepts real coordinates', () {
      expect(isValidCoordinate(const LatLng(22.4529, 86.9003)), isTrue);
    });
  });
}
