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
import 'package:e_go/features/location/presentation/widgets/location_route_card.dart';
import 'package:e_go/features/location/presentation/widgets/pickup_timing_selector.dart';
import 'package:e_go/features/location/presentation/widgets/place_category_selector.dart';
import 'package:e_go/features/location/presentation/widgets/recent_places_content.dart';
import 'package:e_go/features/location/presentation/widgets/saved_places_content.dart';
import 'package:e_go/features/location/presentation/widgets/select_on_map_button.dart';

import '../helpers/test_tile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestApp(AppState state) {
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
              builder: (_) => const Scaffold(body: Text('Place order screen')),
            );
          }
          return null;
        },
      ),
    );
  }

  group('E-GO Location Selection Page Tests', () {
    testWidgets('renders all core components and verifies structure', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.byType(PickupTimingSelector), findsOneWidget);
      expect(find.byType(LocationRouteCard), findsOneWidget);
      expect(find.byType(SelectOnMapButton), findsOneWidget);
      expect(find.byType(PlaceCategorySelector), findsOneWidget);
      expect(find.byType(RecentPlacesContent), findsOneWidget);
      expect(find.text('Pick up now'), findsOneWidget);
      expect(find.text('Schedule for later'), findsOneWidget);
      expect(find.text('Select on map'), findsOneWidget);
      expect(find.text('Recent places'), findsOneWidget);
      expect(find.text('Saved places'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });

    testWidgets('Pickup timing switching toggles between now and later', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Tap Schedule for later
      await tester.tap(find.text('Schedule for later'));
      await tester.pumpAndSettle();

      // Tap Pick up now
      await tester.tap(find.text('Pick up now'));
      await tester.pumpAndSettle();

      expect(find.text('Pick up now'), findsOneWidget);
    });

    testWidgets('Recent / Saved places switching toggles content', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Initially on Recent places
      expect(find.byType(RecentPlacesContent), findsOneWidget);
      expect(find.byType(SavedPlacesContent), findsNothing);

      // Tap Saved places
      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();

      expect(find.byType(SavedPlacesContent), findsOneWidget);
      expect(find.byType(RecentPlacesContent), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);

      // Tap back to Recent places
      await tester.tap(find.text('Recent places'));
      await tester.pumpAndSettle();

      expect(find.byType(RecentPlacesContent), findsOneWidget);
      expect(find.byType(SavedPlacesContent), findsNothing);
    });

    testWidgets('All four primary UI combinations work independently', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Combination 1: Pick up now + Recent places
      expect(find.byType(RecentPlacesContent), findsOneWidget);

      // Combination 2: Pick up now + Saved places
      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedPlacesContent), findsOneWidget);

      // Combination 3: Schedule for later + Saved places
      await tester.tap(find.text('Schedule for later'));
      await tester.pumpAndSettle();
      expect(find.byType(SavedPlacesContent), findsOneWidget);

      // Combination 4: Schedule for later + Recent places
      await tester.tap(find.text('Recent places'));
      await tester.pumpAndSettle();
      expect(find.byType(RecentPlacesContent), findsOneWidget);
    });

    testWidgets('Empty recent places state displays correctly', (tester) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('No recent places yet'), findsOneWidget);
      expect(
        find.text('Your selected destinations will appear here'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.history_toggle_off), findsOneWidget);
    });

    testWidgets('Populated recent places displays list rows', (tester) async {
      final prefs = await SharedPreferences.getInstance();
      final store = RecentDestinationsStore(preferences: prefs);
      await store.record(
        const SavedLocation(
          id: 'recent-station',
          label: 'Jhargram Station',
          subtitle: 'Station Road SER Zone',
          coordinate: LatLng(22.4529, 86.9003),
          type: PlaceType.transport,
        ),
      );

      final state = AppState(recentDestinationsStore: store);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(find.text('Jhargram Station'), findsOneWidget);
      expect(find.text('Station Road SER Zone'), findsOneWidget);
      expect(find.text('No recent places yet'), findsNothing);
    });

    testWidgets('Populated saved places displays 3 reference places and add card', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Ward 8, Kadamkanan, Jhargram'), findsOneWidget);
      expect(find.text('Work'), findsOneWidget);
      expect(
        find.text('Jhargram Court Complex, DM Office Rd'),
        findsOneWidget,
      );
      expect(find.text('Jhargram Railway Station'), findsOneWidget);
      expect(find.text('Station Road, SER Zone'), findsOneWidget);
      expect(find.text('Add new location'), findsOneWidget);
    });

    testWidgets('Selecting a saved place sets destination and enables Continue', (
      tester,
    ) async {
      final state = AppState();
      state.setPickupLocation(
        const SavedLocation(
          id: 'pickup-bazar',
          label: 'Jhargram Bazar',
          subtitle: 'Main Market Area',
          coordinate: LatLng(22.4701, 86.9152),
        ),
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      expect(state.destinationLocation, isNull);

      // Switch to Saved places
      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();

      // Tap Home
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(state.destinationLocation?.label, 'Home');
      expect(state.pickupLocation?.label, 'Jhargram Bazar');
    });

    testWidgets('Selecting a recent place updates destination', (
      tester,
    ) async {
      final prefs = await SharedPreferences.getInstance();
      final store = RecentDestinationsStore(preferences: prefs);
      await store.record(
        const SavedLocation(
          id: 'recent-palace',
          label: 'Jhargram Palace',
          subtitle: 'Palace Road',
          coordinate: LatLng(22.4480, 86.8950),
          type: PlaceType.landmark,
        ),
      );

      final state = AppState(recentDestinationsStore: store);
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jhargram Palace'));
      await tester.pumpAndSettle();

      expect(state.destinationLocation?.label, 'Jhargram Palace');
    });

    testWidgets('Adding a saved place adds it to the list', (tester) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add new location'));
      await tester.pumpAndSettle();

      expect(find.text('Name (e.g. Gym, Library, Friend)'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Gym Club');
      await tester.enterText(
        find.byType(TextField).last,
        'Main Road, Jhargram',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Gym Club'), findsOneWidget);
    });

    testWidgets('Editing a saved place updates it', (tester) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();

      // Tap edit icon for Home
      await tester.tap(find.byTooltip('Edit Home'));
      await tester.pumpAndSettle();

      expect(find.text('Edit Home'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'My Sweet Home');
      await tester.tap(find.text('Update'));
      await tester.pumpAndSettle();

      expect(find.text('My Sweet Home'), findsOneWidget);
    });

    testWidgets('Select on map opens map picker and preserves state', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select on map'));
      await tester.pumpAndSettle();

      expect(find.byType(MapLocationPickerScreen), findsOneWidget);
      expect(state.bookingStage, BookingStage.locationConfirmation);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(state.bookingStage, BookingStage.locationSelection);
      expect(find.byType(LocationSelectionScreen), findsOneWidget);
    });

    testWidgets('Disabled Continue when destination is not chosen', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Destination is null, tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Booking stage remains locationSelection, no navigation
      expect(state.bookingStage, BookingStage.locationSelection);
      expect(find.text('Place order screen'), findsNothing);
    });

    testWidgets('Enabled Continue proceeds to Place Order when route is valid', (
      tester,
    ) async {
      final state = AppState();
      state.setPickupLocation(
        const SavedLocation(
          id: 'pickup-station',
          label: 'Jhargram Railway Station',
          subtitle: 'Station Road',
          coordinate: LatLng(22.4529, 86.9003),
        ),
      );
      state.setDestinationLocation(
        const SavedLocation(
          id: 'drop-bazar',
          label: 'Jhargram Bazar',
          subtitle: 'Market Area',
          coordinate: LatLng(22.4701, 86.9152),
        ),
      );

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Continue'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(state.bookingStage, BookingStage.vehicleSelection);
      expect(find.text('Place order screen'), findsOneWidget);
    });

    testWidgets('Preserving state when switching selectors', (tester) async {
      final state = AppState();
      state.setPickupLocation(
        const SavedLocation(
          id: 'pickup',
          label: 'Jhargram Station',
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

      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      // Switch timing
      await tester.tap(find.text('Schedule for later'));
      await tester.pumpAndSettle();

      // Check pickup & destination preserved
      expect(state.pickupLocation?.label, 'Jhargram Station');
      expect(state.destinationLocation?.label, 'Jhargram Bazar');

      // Switch category
      await tester.tap(find.text('Saved places'));
      await tester.pumpAndSettle();

      // Check pickup & destination still preserved
      expect(state.pickupLocation?.label, 'Jhargram Station');
      expect(state.destinationLocation?.label, 'Jhargram Bazar');
    });

    testWidgets('Back button preserves booking flow and returns home', (
      tester,
    ) async {
      final state = AppState();
      await tester.pumpWidget(buildTestApp(state));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();

      expect(state.bookingStage, BookingStage.home);
    });
  });
}
