import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:e_go/shared/widgets/ego_gooey_bottom_navigation.dart';

Future<void> _loadFonts() async {
  await _loadFontFamily('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await _loadFontFamily('Poppins', const [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
  ]);
  await _loadFontFamily('Manrope', const [
    'assets/fonts/manrope-regular.ttf',
    'assets/fonts/manrope-bold.ttf',
  ]);
  await _loadMaterialIcons();
}

Future<void> _loadFontFamily(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    final file = File(asset);
    if (await file.exists()) {
      final bytes = await file.readAsBytes();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
  }
  await loader.load();
}

Future<void> _loadMaterialIcons() async {
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final root?) ...[
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
      '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    ],
    _materialFontNearExecutable(),
  ];

  for (final candidate in candidates) {
    if (candidate.isEmpty) continue;
    final file = File(candidate);
    if (!file.existsSync()) continue;
    final loader = FontLoader('MaterialIcons');
    final bytes = await file.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    await loader.load();
    return;
  }
}

String _materialFontNearExecutable() {
  var directory = File(Platform.resolvedExecutable).parent;
  for (var i = 0; i < 8; i++) {
    for (final fontName in [
      'materialicons-regular.otf',
      'MaterialIcons-Regular.otf',
    ]) {
      final candidate = File(
        '${directory.path}${Platform.pathSeparator}bin'
        '${Platform.pathSeparator}cache${Platform.pathSeparator}artifacts'
        '${Platform.pathSeparator}material_fonts'
        '${Platform.pathSeparator}$fontName',
      );
      if (candidate.existsSync()) return candidate.path;
    }
    final parent = directory.parent;
    if (parent.path == directory.path) break;
    directory = parent;
  }
  return '';
}

Widget _buildTestApp({
  required String initialRoute,
  required AppState appState,
  Object? initialArguments,
  GlobalKey? repaintKey,
}) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EGoTheme.light,
      onGenerateRoute: (settings) {
        final targetRoute = (settings.name == null || settings.name == '/')
            ? initialRoute
            : settings.name!;
        return EGoRouter.generateRoute(
          RouteSettings(
            name: targetRoute,
            arguments: initialArguments ?? settings.arguments,
          ),
          isAuthenticated: () => true,
        );
      },
      builder: (context, child) {
        if (repaintKey != null) {
          return RepaintBoundary(key: repaintKey, child: child);
        }
        return child!;
      },
    ),
  );
}

Future<void> _pumpShell(
  WidgetTester tester, [
  Duration duration = const Duration(milliseconds: 600),
]) async {
  await tester.pump();
  await tester.pump(duration);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _captureScreen({
  required WidgetTester tester,
  required GlobalKey repaintKey,
  required String outputPath,
  double pixelRatio = 2.0,
}) async {
  await tester.runAsync(() async {
    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(byteData!.buffer.asUint8List());
    expect(file.existsSync(), isTrue);
  });
}

RideRecord _sampleRideRecord() {
  return RideRecord(
    id: 'ride-sample-01',
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
    bookedAt: DateTime.now().subtract(const Duration(hours: 1)),
    paymentMethod: PaymentMethod.cash,
    tripId: 'TRIP-SAMPLE-001',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppState appState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    appState = AppState();
    await _loadFonts();
  });

  group('E-GO Global Navigation Shell — Primary Destination Verification', () {
    testWidgets('Home route displays bottom navigation with Home active', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(initialRoute: EGoRouter.home, appState: appState),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Rides'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      final navState = tester.widget<EgoGooeyBottomNavigation>(
        find.byType(EgoGooeyBottomNavigation),
      );
      expect(navState.selectedIndex, equals(0));
    });

    testWidgets('Rides route displays bottom navigation with Rides active', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(initialRoute: EGoRouter.myRides, appState: appState),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
      expect(find.text('Your rides'), findsOneWidget);

      final navState = tester.widget<EgoGooeyBottomNavigation>(
        find.byType(EgoGooeyBottomNavigation),
      );
      expect(navState.selectedIndex, equals(1));
    });

    testWidgets('Safety route displays bottom navigation with Safety active', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(initialRoute: EGoRouter.safety, appState: appState),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);

      final navState = tester.widget<EgoGooeyBottomNavigation>(
        find.byType(EgoGooeyBottomNavigation),
      );
      expect(navState.selectedIndex, equals(2));
    });

    testWidgets(
      'Account route displays bottom navigation with Account active',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialRoute: EGoRouter.profile, appState: appState),
        );
        await _pumpShell(tester);

        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);

        final navState = tester.widget<EgoGooeyBottomNavigation>(
          find.byType(EgoGooeyBottomNavigation),
        );
        expect(navState.selectedIndex, equals(3));
      },
    );

    testWidgets(
      'switching tabs updates active tab without duplicate navigation bars',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialRoute: EGoRouter.home, appState: appState),
        );
        await _pumpShell(tester);

        // Tap Rides
        await tester.tap(find.text('Rides'));
        await _pumpShell(tester);
        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<EgoGooeyBottomNavigation>(
                find.byType(EgoGooeyBottomNavigation),
              )
              .selectedIndex,
          equals(1),
        );

        // Tap Safety
        await tester.tap(find.text('Safety'));
        await _pumpShell(tester);
        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<EgoGooeyBottomNavigation>(
                find.byType(EgoGooeyBottomNavigation),
              )
              .selectedIndex,
          equals(2),
        );

        // Tap Account
        await tester.tap(find.text('Account'));
        await _pumpShell(tester);
        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<EgoGooeyBottomNavigation>(
                find.byType(EgoGooeyBottomNavigation),
              )
              .selectedIndex,
          equals(3),
        );

        // Tap Home
        await tester.tap(find.text('Home'));
        await _pumpShell(tester);
        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<EgoGooeyBottomNavigation>(
                find.byType(EgoGooeyBottomNavigation),
              )
              .selectedIndex,
          equals(0),
        );
      },
    );

    testWidgets('back navigation on non-Home tab returns to Home tab', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(initialRoute: EGoRouter.home, appState: appState),
      );
      await _pumpShell(tester);

      // Switch to Account
      await tester.tap(find.text('Account'));
      await _pumpShell(tester);
      expect(
        tester
            .widget<EgoGooeyBottomNavigation>(
              find.byType(EgoGooeyBottomNavigation),
            )
            .selectedIndex,
        equals(3),
      );

      // Tap back button in Account app bar
      await tester.tap(find.byIcon(Icons.arrow_back));
      await _pumpShell(tester);

      // Restored to Home
      expect(
        tester
            .widget<EgoGooeyBottomNavigation>(
              find.byType(EgoGooeyBottomNavigation),
            )
            .selectedIndex,
        equals(0),
      );
    });
  });

  group('E-GO Global Navigation Shell — Child Screen Verification', () {
    testWidgets('Payment Methods route completely hides bottom navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.paymentMethods,
          appState: appState,
        ),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
      expect(find.text('Payment methods'), findsOneWidget);
    });

    testWidgets('Notifications route completely hides bottom navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.notifications,
          appState: appState,
        ),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
    });

    testWidgets('Ride Details route completely hides bottom navigation', (
      tester,
    ) async {
      final sampleRide = _sampleRideRecord();
      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.rideDetails,
          appState: appState,
          initialArguments: sampleRide,
        ),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
    });

    testWidgets('Edit Profile route completely hides bottom navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(initialRoute: EGoRouter.editProfile, appState: appState),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
      expect(find.text('Edit profile'), findsOneWidget);
    });

    testWidgets('Help & Support route completely hides bottom navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(initialRoute: EGoRouter.helpSupport, appState: appState),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
    });

    testWidgets('Location Selection route completely hides bottom navigation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.locationSelection,
          appState: appState,
        ),
      );
      await _pumpShell(tester);

      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
    });

    testWidgets(
      'navigating from Account to Payment Methods and back restores navigation',
      (tester) async {
        await tester.pumpWidget(
          _buildTestApp(initialRoute: EGoRouter.profile, appState: appState),
        );
        await _pumpShell(tester);

        // On Account: bottom nav visible, Account active
        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<EgoGooeyBottomNavigation>(
                find.byType(EgoGooeyBottomNavigation),
              )
              .selectedIndex,
          equals(3),
        );

        // Tap 'Payment methods' row
        await tester.tap(find.text('Payment methods'));
        await _pumpShell(tester);

        // On Payment Methods: bottom nav HIDDEN
        expect(find.byType(EgoGooeyBottomNavigation), findsNothing);
        expect(find.text('Cash'), findsOneWidget);

        // Tap Back button
        await tester.tap(find.byIcon(Icons.arrow_back));
        await _pumpShell(tester);

        // Back on Account: bottom nav restored, Account STILL active
        expect(find.byType(EgoGooeyBottomNavigation), findsOneWidget);
        expect(
          tester
              .widget<EgoGooeyBottomNavigation>(
                find.byType(EgoGooeyBottomNavigation),
              )
              .selectedIndex,
          equals(3),
        );
      },
    );
  });

  group('E-GO Global Navigation Screenshot Matrix QA', () {
    const logicalSize = Size(393, 852);

    testWidgets('captures Home screen with bottom navigation visible', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      tester.view.physicalSize = logicalSize * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.home,
          appState: appState,
          repaintKey: repaintKey,
        ),
      );
      await _pumpShell(tester);

      await _captureScreen(
        tester: tester,
        repaintKey: repaintKey,
        outputPath: 'test/screenshots/shell_home_visible_393x852.png',
      );
    });

    testWidgets('captures Your Rides screen with bottom navigation visible', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      tester.view.physicalSize = logicalSize * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.myRides,
          appState: appState,
          repaintKey: repaintKey,
        ),
      );
      await _pumpShell(tester);

      await _captureScreen(
        tester: tester,
        repaintKey: repaintKey,
        outputPath: 'test/screenshots/shell_rides_visible_393x852.png',
      );
    });

    testWidgets('captures Safety screen with bottom navigation visible', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      tester.view.physicalSize = logicalSize * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.safety,
          appState: appState,
          repaintKey: repaintKey,
        ),
      );
      await _pumpShell(tester);

      await _captureScreen(
        tester: tester,
        repaintKey: repaintKey,
        outputPath: 'test/screenshots/shell_safety_visible_393x852.png',
      );
    });

    testWidgets('captures Account screen with bottom navigation visible', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      tester.view.physicalSize = logicalSize * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.profile,
          appState: appState,
          repaintKey: repaintKey,
        ),
      );
      await _pumpShell(tester);

      await _captureScreen(
        tester: tester,
        repaintKey: repaintKey,
        outputPath: 'test/screenshots/shell_account_visible_393x852.png',
      );
    });

    testWidgets(
      'captures Payment Methods screen with bottom navigation hidden',
      (tester) async {
        final repaintKey = GlobalKey();
        tester.view.physicalSize = logicalSize * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            initialRoute: EGoRouter.paymentMethods,
            appState: appState,
            repaintKey: repaintKey,
          ),
        );
        await _pumpShell(tester);

        await _captureScreen(
          tester: tester,
          repaintKey: repaintKey,
          outputPath:
              'test/screenshots/shell_child_payment_methods_hidden_393x852.png',
        );
      },
    );

    testWidgets('captures Ride Details screen with bottom navigation hidden', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      final sampleRide = _sampleRideRecord();
      tester.view.physicalSize = logicalSize * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _buildTestApp(
          initialRoute: EGoRouter.rideDetails,
          appState: appState,
          initialArguments: sampleRide,
          repaintKey: repaintKey,
        ),
      );
      await _pumpShell(tester);

      await _captureScreen(
        tester: tester,
        repaintKey: repaintKey,
        outputPath:
            'test/screenshots/shell_child_ride_details_hidden_393x852.png',
      );
    });

    testWidgets(
      'captures Profile Editing screen with bottom navigation hidden',
      (tester) async {
        final repaintKey = GlobalKey();
        tester.view.physicalSize = logicalSize * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            initialRoute: EGoRouter.editProfile,
            appState: appState,
            repaintKey: repaintKey,
          ),
        );
        await _pumpShell(tester);

        await _captureScreen(
          tester: tester,
          repaintKey: repaintKey,
          outputPath:
              'test/screenshots/shell_child_edit_profile_hidden_393x852.png',
        );
      },
    );

    testWidgets(
      'captures Help & Support screen with bottom navigation hidden',
      (tester) async {
        final repaintKey = GlobalKey();
        tester.view.physicalSize = logicalSize * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          _buildTestApp(
            initialRoute: EGoRouter.helpSupport,
            appState: appState,
            repaintKey: repaintKey,
          ),
        );
        await _pumpShell(tester);

        await _captureScreen(
          tester: tester,
          repaintKey: repaintKey,
          outputPath:
              'test/screenshots/shell_child_help_support_hidden_393x852.png',
        );
      },
    );
  });
}
