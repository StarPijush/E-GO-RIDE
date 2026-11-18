import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/driver_repository.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/booking/presentation/place_order_screen.dart';
import 'package:e_go/features/booking/presentation/widgets/vehicle_option_card.dart';
import 'package:e_go/features/location/domain/location_model.dart';

import '../helpers/test_tile_provider.dart';

const _pickup = SavedLocation(
  id: 'pickup',
  label: 'Jhargram Railway Station',
  subtitle: 'Station Road, Jhargram',
  coordinate: LatLng(22.4529, 86.9003),
);

const _destination = SavedLocation(
  id: 'drop',
  label: 'Jhargram Bazar',
  subtitle: 'Market area, Jhargram',
  coordinate: LatLng(22.4701, 86.9152),
);

List<VehicleOption> _options(LatLng from, LatLng to) {
  return [
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
  ];
}

const _demoDriver = MockDriver(
  id: 'driver-test',
  name: 'Demo Driver',
  rating: 4.5,
  totalRides: 10,
  vehicleNumber: 'WB 00 T 0000',
  vehicleName: 'E-Rickshaw',
  vehicleColor: 'Green',
  avatarIcon: Icons.person,
);

class _ImmediateDriverRepository implements DriverRepository {
  @override
  Future<MockDriver> getAssignedDriver() async => _demoDriver;

  @override
  Future<MockDriver> getAssignedTotoDriver() async => _demoDriver;
}

class _ImmediateVehicleRepository implements VehicleRepository {
  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) async => _options(from, to);
}

class _EmptyVehicleRepository implements VehicleRepository {
  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) async => const [];
}

class _ThrowingVehicleRepository implements VehicleRepository {
  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) async => throw Exception('fare service unavailable');
}

class _ControlledVehicleRepository implements VehicleRepository {
  final Completer<List<VehicleOption>> completer = Completer();

  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) => completer.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  AppState stateWith(VehicleRepository vehicles) {
    final state = AppState(
      vehicleRepository: vehicles,
      driverRepository: _ImmediateDriverRepository(),
      driverSearchDelay: Duration.zero,
    );
    state.setPickupLocation(_pickup);
    state.setDestinationLocation(_destination);
    return state;
  }

  Widget app(AppState state) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        theme: EGoTheme.light,
        home: PlaceOrderScreen(tileProvider: TestTileProvider()),
        onGenerateRoute: (settings) {
          if (settings.name == EGoRouter.searchingDriver) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Searching')),
            );
          }
          return null;
        },
      ),
    );
  }

  testWidgets('shows the map, route and exactly two vehicle options', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsNothing);
    expect(find.text('Jhargram Railway Station'), findsOneWidget);
    expect(find.text('Jhargram Bazar'), findsOneWidget);
    expect(find.byType(VehicleOptionCard), findsNWidgets(2));
    expect(find.text('E-Rickshaw'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(find.text('Select a vehicle to see the fare.'), findsOneWidget);
    expect(find.text('Estimated fare (demo)'), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a vehicle updates fare and enables Place order', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('E-Rickshaw'));
    await tester.tap(find.text('E-Rickshaw'));
    await tester.pumpAndSettle();

    expect(state.selectedVehicle?.type, VehicleType.toto);
    expect(
      find.descendant(
        of: find.byType(VehicleOptionCard),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );
    expect(find.text('Estimated fare (demo)'), findsOneWidget);
    expect(find.textContaining('₹'), findsWidgets);

    final totoFare = state.calculatedFare!.totalFare;
    await tester.ensureVisible(find.text('Bike'));
    await tester.tap(find.text('Bike'));
    await tester.pumpAndSettle();

    expect(state.selectedVehicle?.type, VehicleType.bike);
    expect(state.calculatedFare!.totalFare, isNot(totoFare));
    expect(
      find.descendant(
        of: find.byType(VehicleOptionCard),
        matching: find.byIcon(Icons.check_circle),
      ),
      findsOneWidget,
    );

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('loading fare blocks Place order', (tester) async {
    final repository = _ControlledVehicleRepository();
    final state = stateWith(repository);
    await tester.pumpWidget(app(state));
    await tester.pump();
    await tester.pump();

    expect(find.text('Estimating fare...'), findsOneWidget);
    expect(find.byType(VehicleOptionCard), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    expect(button.onPressed, isNull);

    repository.completer.complete(
      _options(_pickup.coordinate, _destination.coordinate),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VehicleOptionCard), findsNWidgets(2));
  });

  testWidgets('unavailable vehicles show an honest state', (tester) async {
    final state = stateWith(_EmptyVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.text('No vehicles available for this route.'), findsOneWidget);
    expect(find.byType(VehicleOptionCard), findsNothing);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('fare error shows retry and blocks Place order', (tester) async {
    final state = stateWith(_ThrowingVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not calculate fare. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('place order creates one order and replaces the route', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('E-Rickshaw'));
    await tester.tap(find.text('E-Rickshaw'));
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Place order'),
    );
    button.onPressed!();
    button.onPressed!();
    await tester.pumpAndSettle();

    expect(find.text('Searching'), findsOneWidget);
    expect(state.createdOrderId, isNotNull);
    expect(
      state.allRides
          .where((ride) => ride.pickupLocation.id == _pickup.id)
          .length,
      1,
    );
  });

  testWidgets('Change returns to Stage 2 and preserves both locations', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          theme: EGoTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlaceOrderScreen(tileProvider: TestTileProvider()),
                    ),
                  ),
                  child: const Text('Open place order'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open place order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(find.text('Open place order'), findsOneWidget);
    expect(state.pickupLocation, _pickup);
    expect(state.destinationLocation, _destination);
  });
}
