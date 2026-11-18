import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/booking_state.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/location/domain/location_model.dart';

const _pickup = SavedLocation(
  id: 'pickup',
  label: 'Jhargram Station',
  coordinate: LatLng(22.4529, 86.9003),
);

const _pickupTwo = SavedLocation(
  id: 'pickup-two',
  label: 'Jhargram Palace',
  coordinate: LatLng(22.4480, 86.8950),
);

const _destination = SavedLocation(
  id: 'destination',
  label: 'Jhargram Bazar',
  coordinate: LatLng(22.4701, 86.9152),
);

class _FakeVehicleRepository implements VehicleRepository {
  _FakeVehicleRepository({this.fail = false});

  final bool fail;

  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) async {
    if (fail) throw Exception('vehicle service unavailable');
    return [
      VehicleOption(
        type: VehicleType.bike,
        name: 'Bike',
        subtitle: 'Fast & affordable',
        capacity: 1,
        iconData: Icons.two_wheeler,
        fareBreakdown: MockPricingService.calculateFare(
          vehicleType: VehicleType.bike,
          from: from,
          to: to,
        ),
      ),
      VehicleOption(
        type: VehicleType.toto,
        name: 'Toto',
        subtitle: 'E-Rickshaw · Up to 3 passengers',
        capacity: 3,
        iconData: Icons.electric_rickshaw,
        fareBreakdown: MockPricingService.calculateFare(
          vehicleType: VehicleType.toto,
          from: from,
          to: to,
        ),
      ),
    ];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState newState({VehicleRepository? vehicles}) {
    return AppState(
      vehicleRepository: vehicles ?? _FakeVehicleRepository(),
    );
  }

  test('starts at Home with no confirmed route or fare', () {
    final state = newState();

    expect(state.bookingStage, BookingStage.home);
    expect(state.pickupConfirmation, LocationConfirmationStatus.unconfirmed);
    expect(
      state.destinationConfirmation,
      LocationConfirmationStatus.unconfirmed,
    );
    expect(state.fareState, FareCalculationState.idle);
    expect(state.submissionState, OrderSubmissionState.idle);
    expect(state.hasConfirmedRoute, isFalse);
    expect(state.bookingValidation.isValid, isFalse);
  });

  test('selecting pickup and destination confirms both', () {
    final state = newState();

    state.setPickupLocation(_pickup);
    expect(state.pickupConfirmation, LocationConfirmationStatus.confirmed);
    expect(state.hasConfirmedRoute, isFalse);

    state.setDestinationLocation(_destination);
    expect(
      state.destinationConfirmation,
      LocationConfirmationStatus.confirmed,
    );
    expect(state.hasConfirmedRoute, isTrue);
  });

  test('changing one location clears fare but keeps the other location', () async {
    final state = newState();
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);
    await state.prepareVehicleSelection();
    state.selectVehicle(state.availableVehicles.first);
    expect(state.fareState, FareCalculationState.ready);
    expect(state.selectedVehicle, isNotNull);

    state.setPickupLocation(_pickupTwo);

    expect(state.pickupLocation?.id, _pickupTwo.id);
    expect(state.destinationLocation?.id, _destination.id);
    expect(state.fareState, FareCalculationState.idle);
    expect(state.selectedVehicle, isNull);
    expect(state.availableVehicles, isEmpty);
    expect(state.calculatedFare, isNull);
  });

  test('prepare loads exactly the two vehicle options', () async {
    final state = newState();
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);

    final prepared = await state.prepareVehicleSelection();

    expect(prepared, isTrue);
    expect(state.bookingStage, BookingStage.vehicleSelection);
    expect(state.bookingStatus, BookingStatus.selectingVehicle);
    expect(state.fareState, FareCalculationState.ready);
    expect(state.availableVehicles.length, 2);
    expect(
      state.availableVehicles.map((v) => v.type),
      containsAll([VehicleType.bike, VehicleType.toto]),
    );
    expect(state.selectedVehicle, isNull);
  });

  test('preferred vehicle is re-applied after a location change', () async {
    final state = newState();
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);
    await state.prepareVehicleSelection();
    final toto = state.availableVehicles.firstWhere(
      (v) => v.type == VehicleType.toto,
    );
    state.selectVehicle(toto);

    state.setDestinationLocation(_destination);
    expect(state.selectedVehicle, isNotNull);

    state.setPickupLocation(_pickupTwo);
    await state.prepareVehicleSelection();

    expect(state.selectedVehicle?.type, VehicleType.toto);
    expect(state.calculatedFare?.vehicleType, VehicleType.toto);
  });

  test('vehicle repository failure surfaces an error state', () async {
    final state = newState(
      vehicles: _FakeVehicleRepository(fail: true),
    );
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);

    final prepared = await state.prepareVehicleSelection();

    expect(prepared, isFalse);
    expect(state.fareState, FareCalculationState.error);
    expect(state.fareError, isNotNull);
    expect(state.availableVehicles, isEmpty);
  });

  test('stage transitions follow the booking flow and can return home', () {
    final state = newState();

    state.beginLocationSelection();
    expect(state.bookingStage, BookingStage.locationSelection);

    state.beginLocationConfirmation();
    expect(state.bookingStage, BookingStage.locationConfirmation);

    state.returnToLocationSelection();
    expect(state.bookingStage, BookingStage.locationSelection);

    state.beginVehicleSelection();
    expect(state.bookingStage, BookingStage.vehicleSelection);

    state.beginOrderSubmission();
    expect(state.bookingStage, BookingStage.orderSubmission);

    state.returnHome();
    expect(state.bookingStage, BookingStage.home);
  });

  test('returnHome keeps selected locations, resetToIdle clears them', () {
    final state = newState();
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);
    state.beginLocationSelection();

    state.returnHome();
    expect(state.bookingStage, BookingStage.home);
    expect(state.pickupLocation, isNotNull);
    expect(state.destinationLocation, isNotNull);

    state.resetToIdle();
    expect(state.bookingStage, BookingStage.home);
    expect(state.pickupLocation, isNull);
    expect(state.destinationLocation, isNull);
    expect(state.hasConfirmedRoute, isFalse);
  });

  test('legacy proceedToVehicleSelection still loads vehicles', () async {
    final state = newState();
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);

    await state.proceedToVehicleSelection();

    expect(state.bookingStatus, BookingStatus.selectingVehicle);
    expect(state.availableVehicles.length, 2);
    expect(state.fareState, FareCalculationState.ready);
  });
}
