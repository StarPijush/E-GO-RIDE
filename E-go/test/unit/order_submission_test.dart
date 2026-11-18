import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/booking_state.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';
import 'package:e_go/features/booking/data/driver_repository.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/booking/domain/place_order_result.dart';
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

class _FakeVehicleRepository implements VehicleRepository {
  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) async {
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

class _FakeDriverRepository implements DriverRepository {
  @override
  Future<MockDriver> getAssignedDriver() async => _driver;

  @override
  Future<MockDriver> getAssignedTotoDriver() async => _driver;

  static const _driver = MockDriver(
    id: 'driver-test',
    name: 'Test Driver',
    rating: 4.7,
    totalRides: 10,
    vehicleNumber: 'WB 00 T 0000',
    vehicleName: 'Test Vehicle',
    vehicleColor: 'Yellow',
    avatarIcon: Icons.person,
  );
}

class _ThrowingBookingRepository extends MockBookingRepository {
  @override
  bool addRide(RideRecord ride) {
    throw Exception('storage failure');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState newState({
    MockBookingRepository? bookingRepository,
    Duration driverSearchDelay = const Duration(milliseconds: 1),
  }) {
    return AppState(
      vehicleRepository: _FakeVehicleRepository(),
      driverRepository: _FakeDriverRepository(),
      bookingRepository: bookingRepository,
      driverSearchDelay: driverSearchDelay,
    );
  }

  Future<AppState> readyState({
    MockBookingRepository? bookingRepository,
    Duration driverSearchDelay = const Duration(milliseconds: 1),
  }) async {
    final state = newState(
      bookingRepository: bookingRepository,
      driverSearchDelay: driverSearchDelay,
    );
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);
    await state.prepareVehicleSelection();
    state.selectVehicle(state.availableVehicles.first);
    return state;
  }

  test('invalid booking cannot place an order', () async {
    final state = newState();

    final result = await state.placeOrder();

    expect(result.status, PlaceOrderStatus.invalid);
    expect(result.isSuccess, isFalse);
    expect(state.allRides, isEmpty);
    expect(state.submissionState, OrderSubmissionState.idle);
    expect(state.createdOrderId, isNull);
  });

  test('successful placeOrder creates one pending order snapshot', () async {
    final state = await readyState();
    final selected = state.selectedVehicle!;

    final result = await state.placeOrder();

    expect(result.status, PlaceOrderStatus.success);
    expect(result.orderId, isNotNull);
    expect(state.submissionState, OrderSubmissionState.succeeded);
    expect(state.bookingStage, BookingStage.orderSubmission);
    expect(state.allRides.length, 1);

    final ride = state.currentRide!;
    expect(ride.id, result.orderId);
    expect(ride.driver, isNull);
    expect(ride.status, RideStatus.upcoming);
    expect(ride.vehicleType, selected.type);
    expect(ride.fareBreakdown.totalFare, selected.fareBreakdown.totalFare);
    expect(ride.pickupLocation.id, _pickup.id);
    expect(ride.destinationLocation.id, _destination.id);
    expect(ride.tripId, ride.id);
  });

  test('placeOrder is idempotent for repeated calls', () async {
    final state = await readyState();

    final first = await state.placeOrder();
    final second = await state.placeOrder();

    expect(first.isSuccess, isTrue);
    expect(second.isSuccess, isTrue);
    expect(second.orderId, first.orderId);
    expect(state.allRides.length, 1);
  });

  test('placeOrder emits the submitting state before success', () async {
    final state = await readyState();
    final seen = <OrderSubmissionState>[];
    state.addListener(() => seen.add(state.submissionState));

    await state.placeOrder();

    expect(seen, contains(OrderSubmissionState.submitting));
    expect(seen.last, OrderSubmissionState.succeeded);
  });

  test(
    'startDriverSearch creates the pending order when called directly',
    () async {
      final state = await readyState();

      await state.startDriverSearch();

      expect(state.createdOrderId, isNotNull);
      expect(state.currentRide, isNotNull);
      expect(state.allRides.length, 1);
      expect(state.bookingStatus, BookingStatus.driverAssigned);
    },
  );

  test('successful order records the destination exactly once', () async {
    final state = await readyState();

    await state.placeOrder();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final firstHistory = await state.loadRecentDestinations();
    expect(firstHistory.length, 1);
    expect(firstHistory.first.id, _destination.id);

    await state.placeOrder();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final secondHistory = await state.loadRecentDestinations();
    expect(secondHistory.length, 1);
  });

  test('repository addRide is idempotent', () {
    final repository = MockBookingRepository();
    final ride = RideRecord(
      id: 'EGO-test',
      pickupLocation: _pickup,
      destinationLocation: _destination,
      vehicleType: VehicleType.bike,
      fareBreakdown: MockPricingService.calculateFare(
        vehicleType: VehicleType.bike,
        from: _pickup.coordinate,
        to: _destination.coordinate,
      ),
      driver: null,
      status: RideStatus.upcoming,
      bookedAt: DateTime(2026),
      tripId: 'EGO-test',
    );

    expect(repository.addRide(ride), isTrue);
    expect(repository.addRide(ride), isFalse);
    expect(repository.getAllRides().length, 1);
  });

  test('storage failure marks submission failed without an order', () async {
    final state = await readyState(
      bookingRepository: _ThrowingBookingRepository(),
    );

    final result = await state.placeOrder();

    expect(result.status, PlaceOrderStatus.failure);
    expect(result.isSuccess, isFalse);
    expect(state.submissionState, OrderSubmissionState.failed);
    expect(state.createdOrderId, isNull);
    expect(state.currentRide, isNull);
    expect(state.allRides, isEmpty);
  });

  test('cancelling a pending order marks the record cancelled', () async {
    final state = await readyState();
    final result = await state.placeOrder();
    final orderId = result.orderId!;

    await state.cancelRide();

    final stored = state.bookingRepository.getRideById(orderId);
    expect(stored, isNotNull);
    expect(stored!.status, RideStatus.cancelled);
    expect(state.bookingStatus, BookingStatus.idle);
    expect(state.createdOrderId, isNull);
    expect(state.currentRide, isNull);
  });

  test('cancelling invalidates an in-flight driver search', () async {
    final state = await readyState(
      driverSearchDelay: const Duration(milliseconds: 100),
    );
    await state.placeOrder();

    final search = state.startDriverSearch();
    expect(state.bookingStatus, BookingStatus.searchingDriver);

    await state.cancelRide();
    await search;

    expect(state.bookingStatus, BookingStatus.idle);
    expect(state.assignedDriver, isNull);
    expect(state.currentRide, isNull);
  });

  test('legacy confirmBooking reuses the pending order', () async {
    final state = await readyState();
    state.proceedToFareReview();
    state.proceedToConfirmation();

    final future = state.confirmBooking();
    expect(state.bookingStatus, BookingStatus.searchingDriver);

    await future;

    expect(state.bookingStatus, BookingStatus.driverAssigned);
    expect(state.currentRide?.status, RideStatus.active);
    expect(state.currentRide?.driver, isNotNull);
    expect(state.allRides.length, 1);
  });
}
