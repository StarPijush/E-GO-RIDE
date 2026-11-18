import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/features/location/data/recent_destinations_store.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/features/location/presentation/map_location_picker_screen.dart';
import 'package:e_go/features/location/presentation/widgets/location_selection_field.dart';

import '../helpers/test_tile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(AppState state) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        theme: EGoTheme.light,
        home: const LocationSelectionScreen(),
        onGenerateRoute: (settings) {
          if (settings.name == EGoRouter.mapLocationPicker) {
            final target = settings.arguments;
            return MaterialPageRoute<MapLocationPickerResult>(
              builder: (_) => MapLocationPickerScreen(
                target: target is LocationSelectionTarget
                    ? target
                    : LocationSelectionTarget.destination,
                tileProvider: TestTileProvider(),
              ),
            );
          }
          if (settings.name == EGoRouter.placeOrder) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Place order')),
            );
          }
          return null;
        },
      ),
    );
  }

  testWidgets('renders honest empty state and no global navigation', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.text('Select your locations'), findsOneWidget);
    expect(find.byType(LocationSelectionField), findsNWidgets(2));
    expect(find.text('Choose pickup location'), findsOneWidget);
    expect(find.text('Choose drop location'), findsOneWidget);
    expect(find.text('Select on map'), findsOneWidget);
    expect(find.text('Recent locations'), findsOneWidget);
    expect(find.text('No recent locations yet'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.byType(BottomNavigationBar), findsNothing);
    expect(state.bookingStage, BookingStage.locationSelection);
  });

  testWidgets('requires both pickup and drop before continuing', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(find.text('Choose a pickup location.'), findsOneWidget);
    expect(find.text('Choose a drop location.'), findsOneWidget);
    expect(state.bookingStage, BookingStage.locationSelection);
    expect(find.text('Place order'), findsNothing);
  });

  testWidgets('recent destination fills the drop field without fake pickup', (
    tester,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final store = RecentDestinationsStore(preferences: prefs);
    await store.record(
      const SavedLocation(
        id: 'recent-1',
        label: 'Jhargram Bazar',
        subtitle: 'Market area, Jhargram',
        coordinate: LatLng(22.4701, 86.9152),
        type: PlaceType.market,
      ),
    );

    final state = AppState(recentDestinationsStore: store);
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.text('Jhargram Bazar'), findsOneWidget);
    await tester.tap(find.text('Jhargram Bazar'));
    await tester.pump();

    expect(state.destinationLocation?.label, 'Jhargram Bazar');
    expect(state.pickupLocation, isNull);
    expect(find.byIcon(Icons.delete), findsNothing);
  });

  testWidgets('search sets a pickup without inventing a drop', (tester) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose pickup location'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Railway');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jhargram Railway Station').last);
    await tester.pumpAndSettle();

    expect(state.pickupLocation?.label, 'Jhargram Railway Station');
    expect(state.destinationLocation, isNull);
  });

  testWidgets('map picker opens for the selected field and resets its stage', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Select pickup on map'));
    await tester.pumpAndSettle();

    expect(find.text('Set pickup point'), findsOneWidget);
    expect(state.bookingStage, BookingStage.locationConfirmation);

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(state.bookingStage, BookingStage.locationSelection);
  });

  testWidgets('continue loads the two fare options and opens place order', (
    tester,
  ) async {
    final state = AppState();
    state.setPickupLocation(
      const SavedLocation(
        id: 'pickup',
        label: 'Jhargram Railway Station',
        coordinate: LatLng(22.4529, 86.9003),
      ),
    );
    state.setDestinationLocation(
      const SavedLocation(
        id: 'drop',
        label: 'Jhargram Bazar',
        coordinate: LatLng(22.4701, 86.9152),
      ),
    );

    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(state.bookingStage, BookingStage.vehicleSelection);
    expect(state.availableVehicles.length, 2);
    expect(find.text('Place order'), findsOneWidget);
  });
}
