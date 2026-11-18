import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/features/booking/presentation/place_order_screen.dart';
import 'package:e_go/features/home/presentation/home_screen.dart';
import 'package:e_go/features/home/presentation/widgets/destination_search_card.dart';
import 'package:e_go/features/home/presentation/widgets/home_current_location_marker.dart';
import 'package:e_go/features/home/presentation/widgets/popular_destination_card.dart';
import 'package:e_go/features/home/presentation/widgets/recent_destination_card.dart';
import 'package:e_go/features/location/data/recent_destinations_store.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';
import 'package:e_go/shared/shell/ego_main_shell.dart';
import 'package:e_go/shared/widgets/ego_gooey_bottom_navigation.dart';

import '../helpers/test_tile_provider.dart';

const _recent = SavedLocation(
  id: 'recent-test',
  label: 'Recent Test Place',
  subtitle: 'Recent Road, Jhargram',
  coordinate: LatLng(22.4600, 86.9100),
);

const _pickup = SavedLocation(
  id: 's2',
  label: 'Jhargram Railway Station',
  subtitle: 'Station Road, Jhargram',
  coordinate: LatLng(22.4529, 86.9003),
);

String _recentJson() => jsonEncode([
  {
    'id': _recent.id,
    'label': _recent.label,
    'subtitle': _recent.subtitle,
    'lat': _recent.coordinate.latitude,
    'lng': _recent.coordinate.longitude,
    'type': 'other',
  },
]);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget app(AppState state, {Widget? home, RouteFactory? onGenerateRoute}) {
    return ChangeNotifierProvider<AppState>.value(
      value: state,
      child: MaterialApp(
        theme: EGoTheme.light,
        home: home ?? EGoHomeScreen(tileProvider: TestTileProvider()),
        onGenerateRoute: onGenerateRoute ?? EGoRouter.generateRoute,
      ),
    );
  }

  testWidgets('renders map-first discovery without the obsolete Home UI', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('Choose your destination'), findsOneWidget);
    expect(find.byType(DestinationSearchCard), findsOneWidget);
    expect(find.text('Popular in Jhargram'), findsOneWidget);

    // Exactly 4 reference Popular Destination Cards
    expect(find.byType(PopularDestinationCard), findsNWidgets(4));
    expect(find.text('Jhargram Palace'), findsOneWidget);
    expect(find.text('Jhargram Station'), findsOneWidget);
    expect(find.text('Central Bus Stand'), findsOneWidget);
    expect(find.text('Kanak Durga Temple'), findsOneWidget);

    // No recent destination when store is empty
    expect(find.byType(RecentDestinationCard), findsNothing);
    expect(find.text('Last used'), findsNothing);

    // Obsolete items absent
    expect(find.text('Add saved place'), findsNothing);
    expect(find.text('CHOOSE LOCATION'), findsNothing);
    expect(find.text('PICKUP LOCATION'), findsNothing);
    expect(find.byType(HomeCurrentLocationMarker), findsNothing);

    // CRITICAL: GPS button is completely removed
    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('shows a persisted recent destination', (tester) async {
    SharedPreferences.setMockInitialValues({
      RecentDestinationsStore.storageKey: _recentJson(),
    });
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    expect(find.byType(RecentDestinationCard), findsOneWidget);
    expect(find.text(_recent.label), findsOneWidget);
    expect(find.text(_recent.subtitle!), findsOneWidget);
    expect(find.byType(PopularDestinationCard), findsNWidgets(4));
  });

  testWidgets('search card tap opens Location Selection', (tester) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose your destination'));
    await tester.pumpAndSettle();

    expect(find.byType(LocationSelectionScreen), findsOneWidget);
    expect(state.bookingStage.name, 'locationSelection');
  });

  testWidgets('popular tap without a confirmed pickup opens Stage 2', (
    tester,
  ) async {
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Jhargram Palace'));
    await tester.tap(find.text('Jhargram Palace'));
    await tester.pumpAndSettle();

    expect(find.byType(LocationSelectionScreen), findsOneWidget);
    expect(state.destinationLocation?.id, 's3');
    expect(state.destinationLocation?.label, 'Jhargram Palace');
    expect(state.bookingStage.name, 'locationSelection');
  });

  testWidgets('popular tap with a confirmed pickup opens Place Order', (
    tester,
  ) async {
    final state = AppState();
    state.setPickupLocation(_pickup);

    await tester.pumpWidget(
      app(
        state,
        onGenerateRoute: (settings) {
          if (settings.name == EGoRouter.placeOrder) {
            return MaterialPageRoute(
              builder: (_) => const Scaffold(body: Text('Place Order Route')),
            );
          }
          return EGoRouter.generateRoute(settings);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Jhargram Palace'));
    await tester.tap(find.text('Jhargram Palace'));
    await tester.pumpAndSettle();

    expect(find.text('Place Order Route'), findsOneWidget);
    expect(state.destinationLocation?.id, 's3');
    expect(state.pickupLocation?.id, _pickup.id);
    expect(state.bookingStage.name, 'vehicleSelection');
  });

  testWidgets('recent destination tap sets destination in booking state', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      RecentDestinationsStore.storageKey: _recentJson(),
    });
    final state = AppState();
    await tester.pumpWidget(app(state));
    await tester.pumpAndSettle();

    await tester.tap(find.text(_recent.label));
    await tester.pumpAndSettle();

    expect(find.byType(LocationSelectionScreen), findsOneWidget);
    expect(state.destinationLocation?.id, _recent.id);
    expect(state.destinationLocation?.label, _recent.label);
  });

  testWidgets('back from direct Place Order returns to Home', (tester) async {
    final state = AppState();
    state.setPickupLocation(_pickup);

    await tester.pumpWidget(
      app(
        state,
        onGenerateRoute: (settings) {
          if (settings.name == EGoRouter.placeOrder) {
            return MaterialPageRoute(
              builder: (_) =>
                  PlaceOrderScreen(tileProvider: TestTileProvider()),
            );
          }
          return EGoRouter.generateRoute(settings);
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Jhargram Palace'));
    await tester.tap(find.text('Jhargram Palace'));
    await tester.pumpAndSettle();

    expect(find.byType(PlaceOrderScreen), findsOneWidget);
    expect(state.bookingStage.name, 'vehicleSelection');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(EGoHomeScreen), findsOneWidget);
    expect(find.text('Where to?'), findsOneWidget);
    expect(state.bookingStage.name, 'home');
  });

  testWidgets('shell owns the global navigation on Home', (tester) async {
    final state = AppState();
    await tester.pumpWidget(
      app(state, home: EGoMainShell(tileProvider: TestTileProvider())),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Rides'), findsOneWidget);
    expect(find.text('Safety'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Where to?'), findsOneWidget);
  });
}
