import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/theme/colors.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/features/home/presentation/home_screen.dart';
import 'package:e_go/features/home/presentation/widgets/destination_search_card.dart';
import 'package:e_go/features/home/presentation/widgets/home_current_location_marker.dart';
import 'package:e_go/features/home/presentation/widgets/popular_destination_card.dart';
import 'package:e_go/features/home/presentation/widgets/recent_destination_card.dart';
import 'package:e_go/features/location/domain/location_model.dart';

import '../helpers/test_tile_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('EGoTheme creates valid ThemeData', () {
    final theme = EGoTheme.light;
    expect(theme, isNotNull);
    expect(theme.colorScheme.primary, equals(EGoColors.brandPrimary));
    expect(theme.colorScheme.surface, equals(const Color(0xFFFFFFFF)));
    expect(theme.scaffoldBackgroundColor, equals(EGoColors.grey50));
    expect(theme.appBarTheme.backgroundColor, equals(const Color(0xFFFFFFFF)));
    expect(theme.cardTheme.color, equals(const Color(0xFFFFFFFF)));
  });

  testWidgets('EGoHomeScreen renders the reference destination-first Home', (
    tester,
  ) async {
    final appState = AppState();

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          theme: EGoTheme.light,
          home: EGoHomeScreen(tileProvider: TestTileProvider()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Section B & C
    expect(find.text('Where to?'), findsOneWidget);
    expect(find.text('Choose your destination'), findsOneWidget);
    expect(find.byType(DestinationSearchCard), findsOneWidget);

    // Section D (zero placeholder when no recent history)
    expect(find.byType(RecentDestinationCard), findsNothing);
    expect(find.text('Last used'), findsNothing);

    // Section E: Exactly 4 popular cards
    expect(find.text('Popular in Jhargram'), findsOneWidget);
    expect(find.byType(PopularDestinationCard), findsNWidgets(4));
    expect(find.text('Jhargram Palace'), findsOneWidget);
    expect(find.text('Jhargram Station'), findsOneWidget);
    expect(find.text('Central Bus Stand'), findsOneWidget);
    expect(find.text('Kanak Durga Temple'), findsOneWidget);

    // Verified removal of GPS button and old overlays
    expect(find.byIcon(Icons.my_location), findsNothing);
    expect(find.text('Add saved place'), findsNothing);
    expect(find.text('CHOOSE LOCATION'), findsNothing);
    expect(find.text('PICKUP LOCATION'), findsNothing);
  });

  testWidgets('displays current location marker only with valid coordinates', (
    tester,
  ) async {
    final appState = AppState();

    // 1. Initially no coordinate -> marker is absent
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          theme: EGoTheme.light,
          home: EGoHomeScreen(tileProvider: TestTileProvider()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeCurrentLocationMarker), findsNothing);
  });

  testWidgets('each popular destination updates booking state correctly', (
    tester,
  ) async {
    final appState = AppState();
    const pickup = SavedLocation(
      id: 'pickup-1',
      label: 'My Station Pickup',
      coordinate: LatLng(22.4500, 86.9000),
    );
    appState.setPickupLocation(pickup);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: appState,
        child: MaterialApp(
          theme: EGoTheme.light,
          home: EGoHomeScreen(tileProvider: TestTileProvider()),
          onGenerateRoute: (settings) => MaterialPageRoute(
            builder: (_) => const Scaffold(body: Text('Route Target')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify tap on Jhargram Palace
    await tester.tap(find.text('Jhargram Palace'));
    await tester.pumpAndSettle();

    expect(appState.destinationLocation?.id, 's3');
    expect(appState.destinationLocation?.label, 'Jhargram Palace');
    expect(appState.pickupLocation?.id, pickup.id); // Pickup preserved!
  });
}
