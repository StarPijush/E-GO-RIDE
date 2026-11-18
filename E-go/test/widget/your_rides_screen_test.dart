import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/booking_repository.dart';
import 'package:e_go/features/booking/data/driver_repository.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';
import 'package:e_go/features/rides/presentation/screens/my_rides_screen.dart';
import 'package:e_go/features/rides/presentation/widgets/ride_filter_tabs.dart';
import 'package:e_go/features/rides/presentation/widgets/rides_empty_state.dart';
import 'package:e_go/features/rides/presentation/widgets/ride_card.dart';

Widget _buildTestApp(Widget child, AppState appState, {Size? size}) {
  final content = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: EGoTheme.light,
    onGenerateRoute: EGoRouter.generateRoute,
    home: child,
  );

  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: size != null
        ? SizedBox(width: size.width, height: size.height, child: content)
        : content,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    appState = AppState();
  });

  group('Your Rides Screen Widget & Functional Tests', () {
    testWidgets(
      'renders app bar, category tabs, and empty state without bottom nav',
      (tester) async {
        await tester.pumpWidget(_buildTestApp(const MyRidesScreen(), appState));
        await tester.pumpAndSettle();

        // Top App Bar
        expect(find.text('Your rides'), findsOneWidget);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);

        // Category Tabs
        expect(find.byType(RideFilterTabs), findsOneWidget);
        expect(find.text('All'), findsOneWidget);
        expect(find.text('Electric TOTOs'), findsOneWidget);
        expect(find.text('Bike'), findsOneWidget);

        // Empty State
        expect(find.byType(RidesEmptyState), findsOneWidget);
        expect(find.text('No rides yet'), findsOneWidget);
        expect(
          find.text('Your completed and cancelled rides will appear here.'),
          findsOneWidget,
        );
        expect(find.text('Book Your'), findsOneWidget);
        expect(find.text('Ride'), findsOneWidget);

        // Bottom nav is strictly NOT rendered
        expect(find.text('Home'), findsNothing);
        expect(find.text('Safety'), findsNothing);
        expect(find.text('Profile'), findsNothing);
      },
    );

    testWidgets('tab switching updates selected tab filter', (tester) async {
      await tester.pumpWidget(_buildTestApp(const MyRidesScreen(), appState));
      await tester.pumpAndSettle();

      // Tap Electric TOTOs
      await tester.tap(find.text('Electric TOTOs'));
      await tester.pumpAndSettle();
      expect(find.byType(RidesEmptyState), findsOneWidget);

      // Tap Bike
      await tester.tap(find.text('Bike'));
      await tester.pumpAndSettle();
      expect(find.byType(RidesEmptyState), findsOneWidget);

      // Tap All
      await tester.tap(find.text('All'));
      await tester.pumpAndSettle();
      expect(find.byType(RidesEmptyState), findsOneWidget);
    });

    testWidgets('Book Your Ride CTA navigates to destination selection flow', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(const MyRidesScreen(), appState));
      await tester.pumpAndSettle();

      final bookButton = find.widgetWithText(ElevatedButton, 'Book Your');
      expect(bookButton, findsOneWidget);

      await tester.tap(bookButton);
      await tester.pumpAndSettle();

      // Successfully navigated to the location selection stage
      expect(find.byType(MyRidesScreen), findsNothing);
      expect(find.byType(LocationSelectionScreen), findsOneWidget);
    });

    testWidgets('displays populated ride cards when rides exist in AppState', (
      tester,
    ) async {
      // Seed a completed toto ride
      final totoRide = RideRecord(
        id: 'ride-test-toto-01',
        pickupLocation: const SavedLocation(
          id: 'p1',
          label: 'Jhargram Station',
          subtitle: 'Station Road',
          coordinate: LatLng(22.4500, 86.9900),
        ),
        destinationLocation: const SavedLocation(
          id: 'd1',
          label: 'Jhargram Raj Palace',
          subtitle: 'Palace Compound',
          coordinate: LatLng(22.4550, 86.9950),
        ),
        vehicleType: VehicleType.toto,
        fareBreakdown: const FareBreakdown(
          vehicleType: VehicleType.toto,
          baseFare: 20,
          distanceFare: 20,
          platformFee: 5,
          distanceKm: 2.5,
          estimatedMinutes: 8,
          estimatedArrivalMinutes: 3,
        ),
        driver: const MockDriver(
          id: 'driver-01',
          name: 'Biren Mahato',
          rating: 4.8,
          totalRides: 412,
          vehicleNumber: 'WB-34-T-8821',
          vehicleName: 'Toto E-Rickshaw',
          vehicleColor: 'Yellow & Black',
          avatarIcon: Icons.electric_rickshaw,
        ),
        status: RideStatus.completed,
        bookedAt: DateTime.now().subtract(const Duration(hours: 2)),
        paymentMethod: PaymentMethod.cash,
        tripId: 'TRIP-TOTO-001',
      );
      appState.bookingRepository.addRide(totoRide);

      await tester.pumpWidget(_buildTestApp(const MyRidesScreen(), appState));
      await tester.pumpAndSettle();

      // On 'All' tab: Populated list with RideCard appears, empty state disappears
      expect(find.byType(RideCard), findsOneWidget);
      expect(find.byType(RidesEmptyState), findsNothing);
      expect(find.text('Jhargram Station'), findsOneWidget);

      // On 'Electric TOTOs' tab: Still shows the toto ride
      await tester.tap(find.text('Electric TOTOs'));
      await tester.pumpAndSettle();
      expect(find.byType(RideCard), findsOneWidget);
      expect(find.byType(RidesEmptyState), findsNothing);

      // On 'Bike' tab: Honest empty state because no bike rides exist
      await tester.tap(find.text('Bike'));
      await tester.pumpAndSettle();
      expect(find.byType(RideCard), findsNothing);
      expect(find.byType(RidesEmptyState), findsOneWidget);
      expect(find.text('No rides yet'), findsOneWidget);
    });

    testWidgets('tapping a ride card opens ride details', (tester) async {
      appState.bookingRepository.addRide(
        RideRecord(
          id: 'ride-details-01',
          pickupLocation: const SavedLocation(
            id: 'p1',
            label: 'Jhargram Station',
            subtitle: 'Station Road',
            coordinate: LatLng(22.4500, 86.9900),
          ),
          destinationLocation: const SavedLocation(
            id: 'd1',
            label: 'Jhargram Raj Palace',
            subtitle: 'Palace Compound',
            coordinate: LatLng(22.4550, 86.9950),
          ),
          vehicleType: VehicleType.toto,
          fareBreakdown: const FareBreakdown(
            vehicleType: VehicleType.toto,
            baseFare: 20,
            distanceFare: 20,
            platformFee: 5,
            distanceKm: 2.5,
            estimatedMinutes: 8,
            estimatedArrivalMinutes: 3,
          ),
          driver: const MockDriver(
            id: 'driver-01',
            name: 'Biren Mahato',
            rating: 4.8,
            totalRides: 412,
            vehicleNumber: 'WB-34-T-8821',
            vehicleName: 'Toto E-Rickshaw',
            vehicleColor: 'Yellow & Black',
            avatarIcon: Icons.electric_rickshaw,
          ),
          status: RideStatus.completed,
          bookedAt: DateTime(2026, 11, 6, 14, 30),
        ),
      );

      await tester.pumpWidget(_buildTestApp(const MyRidesScreen(), appState));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(RideCard));
      await tester.pumpAndSettle();

      expect(find.text('Ride details'), findsOneWidget);
      expect(find.text('Fare breakdown'), findsOneWidget);
    });

    testWidgets(
      'renders properly across various viewports without layout errors',
      (tester) async {
        const viewports = [
          Size(360, 800),
          Size(375, 667),
          Size(393, 852),
          Size(412, 915),
        ];

        for (final size in viewports) {
          tester.view.physicalSize = size * 2;
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await tester.pumpWidget(
            _buildTestApp(const MyRidesScreen(), appState, size: size),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        }
      },
    );
  });
}
