import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/features/location/presentation/map_location_picker_screen.dart';

import '../helpers/test_tile_provider.dart';

class _PickerLauncher extends StatelessWidget {
  const _PickerLauncher({required this.state, required this.target});

  final AppState state;
  final LocationSelectionTarget target;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>.value(
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
                    builder: (_) => MapLocationPickerScreen(
                      target: target,
                      tileProvider: TestTileProvider(),
                    ),
                  ),
                ),
                child: const Text('Open picker'),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> openPicker(
    WidgetTester tester,
    AppState state, {
    LocationSelectionTarget target = LocationSelectionTarget.destination,
  }) async {
    await tester.pumpWidget(_PickerLauncher(state: state, target: target));
    await tester.tap(find.text('Open picker'));
    await tester.pumpAndSettle();
  }

  testWidgets('does not invent a location before the customer chooses one', (
    tester,
  ) async {
    final state = AppState();
    await openPicker(tester, state);

    expect(find.text('Choose a point on the map'), findsOneWidget);
    expect(find.text('Move the map or search for a place.'), findsOneWidget);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm drop location'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('search selects a known place and confirms it', (tester) async {
    final state = AppState();
    await openPicker(tester, state);

    await tester.tap(find.byTooltip('Search for a place'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Bazar');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Jhargram Bazar').last);
    await tester.pumpAndSettle();

    expect(find.text('Jhargram Bazar'), findsOneWidget);
    await tester.tap(find.text('Confirm drop location'));
    await tester.pumpAndSettle();

    expect(state.destinationLocation?.label, 'Jhargram Bazar');
    expect(find.text('Open picker'), findsOneWidget);
  });

  testWidgets('toggle switches between pickup and drop', (tester) async {
    final state = AppState();
    await openPicker(tester, state);

    await tester.tap(find.text('Pickup'));
    await tester.pump();

    expect(find.text('Set pickup point'), findsOneWidget);
    expect(find.text('Confirm pickup location'), findsOneWidget);
  });

  testWidgets('unavailable current location shows an honest error', (
    tester,
  ) async {
    final state = AppState();
    await openPicker(tester, state, target: LocationSelectionTarget.pickup);

    await tester.tap(find.byTooltip('Use current location'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(
      find.textContaining('Current location is not available'),
      findsOneWidget,
    );
    expect(state.pickupLocation, isNull);
  });

  testWidgets('an existing field location is reused, not invented', (
    tester,
  ) async {
    final state = AppState();
    state.setPickupLocation(
      const SavedLocation(
        id: 'pickup',
        label: 'Jhargram Railway Station',
        subtitle: 'Station Road, Jhargram',
        coordinate: LatLng(22.4529, 86.9003),
      ),
    );

    await openPicker(tester, state, target: LocationSelectionTarget.pickup);

    expect(find.text('Jhargram Railway Station'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm pickup location'),
    );
    expect(button.onPressed, isNotNull);
  });
}
