import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const testViewports = [
    Size(320, 568),
    Size(360, 800),
    Size(375, 812),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  for (final size in testViewports) {
    testWidgets(
      'LocationSelectionScreen renders with zero overflow at ${size.width.toInt()}x${size.height.toInt()} (Reference Set A)',
      (tester) async {
        final state = AppState();
        state.setPickupLocation(
          const SavedLocation(
            id: 'pickup',
            label: 'Jhargram Bazar',
            subtitle: 'Main Market Area, Station Link Rd',
            coordinate: LatLng(22.4701, 86.9152),
          ),
        );

        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: EGoTheme.light,
              home: SizedBox(
                width: size.width,
                height: size.height,
                child: const LocationSelectionScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Pick up now'), findsOneWidget);
        expect(find.text('Schedule for later'), findsOneWidget);
        expect(find.text('Select on map'), findsOneWidget);
        expect(find.text('Recent places'), findsOneWidget);
        expect(find.text('Saved places'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );

    testWidgets(
      'LocationSelectionScreen renders with zero overflow at ${size.width.toInt()}x${size.height.toInt()} (Reference Set B)',
      (tester) async {
        final state = AppState();
        state.setPickupLocation(
          const SavedLocation(
            id: 'pickup',
            label: 'Jhargram Bazar',
            subtitle: 'Main Market Area',
            coordinate: LatLng(22.4701, 86.9152),
          ),
        );
        state.setDestinationLocation(
          const SavedLocation(
            id: 'drop',
            label: 'Home (Kadamkanan)',
            subtitle: 'Ward 8, Kadamkanan, Jhargram',
            coordinate: LatLng(22.4580, 86.9080),
          ),
        );

        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(
          ChangeNotifierProvider<AppState>.value(
            value: state,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: EGoTheme.light,
              home: SizedBox(
                width: size.width,
                height: size.height,
                child: const LocationSelectionScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch to Saved places
        await tester.tap(find.text('Saved places'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Work'), findsOneWidget);
        expect(find.text('Jhargram Railway Station'), findsOneWidget);
        expect(find.text('Add new location'), findsOneWidget);
        expect(find.text('Continue'), findsOneWidget);
      },
    );
  }
}
