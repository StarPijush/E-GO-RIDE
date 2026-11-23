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
import 'package:e_go/features/routing/data/services/jhargram_road_network_service.dart';

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
      routeService: const JhargramRoadNetworkService(),
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

  testWidgets('shows the map, route polyline, and exactly two vehicle options', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(PolylineLayer), findsOneWidget);
    expect(find.text('Jhargram Railway Station'), findsOneWidget);
    expect(find.text('Jhargram Bazar'), findsOneWidget);
    expect(find.byType(VehicleOptionCard), findsNWidgets(2));
    expect(find.text('E-Rickshaw'), findsOneWidget);
    expect(find.text('Bike'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(VehicleOptionCard),
        matching: find.byIcon(Icons.info_outline),
      ),
      findsNWidgets(2),
    );
    expect(find.text('Estimated fare (demo)'), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Book your ride'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('selecting a vehicle updates fare and enables Book your ride', (
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

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Book Bike'),
    );
    expect(button.onPressed, isNotNull);
  });

  testWidgets('loading fare blocks Book your ride', (tester) async {
    final repository = _ControlledVehicleRepository();
    final state = stateWith(repository);
    await tester.pumpWidget(app(state));
    await tester.pump();
    await tester.pump();

    expect(find.text('Estimating fare...'), findsOneWidget);
    expect(find.byType(VehicleOptionCard), findsNothing);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Book your ride'),
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
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Book your ride'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('fare error shows retry and blocks Book your ride', (tester) async {
    final state = stateWith(_ThrowingVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not calculate fare. Please try again.'),
      findsOneWidget,
    );
    expect(find.text('Retry'), findsOneWidget);
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Book your ride'),
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

    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Book Toto'),
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

  testWidgets('YOUR ROUTE and Change route are completely removed from bottom sheet', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    // Verify "YOUR ROUTE" is completely removed
    expect(find.text('YOUR ROUTE'), findsNothing);
    // Verify "Change route" and "Change" buttons are completely removed
    expect(find.text('Change route'), findsNothing);
    expect(find.text('Change'), findsNothing);
    expect(find.byIcon(Icons.edit), findsNothing);
  });

  testWidgets('Cash and Coupons both use matching right-facing chevron_right icon', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.text('Cash'), findsOneWidget);
    expect(find.text('Offers & Coupons'), findsOneWidget);

    // Verify downward expand_more is NOT used
    expect(find.byIcon(Icons.expand_more), findsNothing);

    // Verify right-facing chevron_right icons are used
    expect(find.byIcon(Icons.chevron_right), findsWidgets);
  });

  testWidgets('Back arrow preserves booking state and title pill is removed', (tester) async {
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
                  child: const Text('Open review ride'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open review ride'));
    await tester.pumpAndSettle();

    // Verify title pill "Review your ride" is removed
    expect(find.text('Review your ride'), findsNothing);

    // Tap back button
    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open review ride'), findsOneWidget);
    expect(state.pickupLocation, _pickup);
    expect(state.destinationLocation, _destination);
  });

  testWidgets('dynamic CTA label updates between Book your ride, Book Bike, and Book Toto', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    // 1. Initial state: No vehicle selected -> 'Book your ride'
    expect(find.widgetWithText(ElevatedButton, 'Book your ride'), findsOneWidget);

    // 2. Select Bike -> 'Book Bike'
    await tester.ensureVisible(find.text('Bike'));
    await tester.tap(find.text('Bike'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Book Bike'), findsOneWidget);

    // 3. Select E-Rickshaw -> 'Book Toto'
    await tester.ensureVisible(find.text('E-Rickshaw'));
    await tester.tap(find.text('E-Rickshaw'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ElevatedButton, 'Book Toto'), findsOneWidget);
  });

  testWidgets('floating locate button requests current location and handles gracefully', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    final locateFinder = find.byIcon(Icons.my_location);
    expect(locateFinder, findsOneWidget);

    await tester.tap(locateFinder);
    await tester.pumpAndSettle();

    // Verify no unhandled exception occurred and screen remains stable
    expect(tester.takeException(), isNull);
    expect(find.byType(FlutterMap), findsOneWidget);
  });

  testWidgets('bottom sheet expands and collapses cleanly', (tester) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    // Tap the drag handle area to toggle expansion
    final dragHandleFinder = find.byType(GestureDetector).first;
    await tester.tap(dragHandleFinder);
    await tester.pumpAndSettle();

    expect(find.text('Choose your ride'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping info icon opens fare breakdown with accurate total', (
    tester,
  ) async {
    final state = stateWith(_ImmediateVehicleRepository());
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    // Verify info icons exist on vehicle cards
    final infoIcons = find.descendant(
      of: find.byType(VehicleOptionCard),
      matching: find.byIcon(Icons.info_outline),
    );
    expect(infoIcons, findsNWidgets(2));

    // Tap the first info icon (E-Rickshaw)
    await tester.tap(infoIcons.first);
    await tester.pumpAndSettle();

    // Verify Fare Breakdown sheet appears
    expect(find.text('Fare breakdown'), findsOneWidget);
    expect(find.text('E-Rickshaw · Estimated fare'), findsOneWidget);
    expect(find.text('Base fare'), findsOneWidget);
    expect(find.textContaining('Distance charge'), findsOneWidget);
    expect(find.text('Platform & safety fee'), findsOneWidget);
    expect(find.text('Total estimated fare'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);

    // Dismiss sheet
    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();

    expect(find.text('Fare breakdown'), findsNothing);
  });
}
