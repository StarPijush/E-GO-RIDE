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
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/account/presentation/about_screen.dart';
import 'package:e_go/features/account/presentation/edit_profile_screen.dart';
import 'package:e_go/features/account/presentation/payment_methods_screen.dart';
import 'package:e_go/features/account/presentation/profile_screen.dart';
import 'package:e_go/features/account/presentation/settings_screen.dart';
import 'package:e_go/features/booking/presentation/booking_confirmation_screen.dart';
import 'package:e_go/features/booking/presentation/fare_details_screen.dart';
import 'package:e_go/features/booking/presentation/place_order_screen.dart';
import 'package:e_go/features/booking/presentation/vehicle_selection_screen.dart';
import 'package:e_go/shared/shell/ego_main_shell.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';
import 'package:e_go/features/location/presentation/map_location_picker_screen.dart';
import 'package:e_go/features/location/presentation/saved_places_screen.dart';
import 'package:e_go/features/notifications/presentation/notifications_screen.dart';
import 'package:e_go/features/rides/presentation/screens/my_rides_screen.dart';
import 'package:e_go/features/safety/presentation/screens/safety_screen.dart';
import 'package:e_go/features/support/presentation/help_support_screen.dart';

import '../helpers/test_tile_provider.dart';

class _ScreenScenario {
  const _ScreenScenario({
    required this.slug,
    required this.screen,
    this.prepare,
    this.settle = true,
    this.seedRoute = true,
  });

  final String slug;
  final Widget Function() screen;
  final Future<void> Function(AppState state)? prepare;
  final bool settle;
  final bool seedRoute;
}

final List<_ScreenScenario> _scenarios = [
  _ScreenScenario(
    slug: 'home',
    screen: () => EGoMainShell(tileProvider: TestTileProvider()),
    settle: false,
    seedRoute: false,
  ),
  _ScreenScenario(
    slug: 'location_selection',
    screen: () => const LocationSelectionScreen(),
  ),
  _ScreenScenario(
    slug: 'map_selection',
    screen: () => MapLocationPickerScreen(
      target: LocationSelectionTarget.destination,
      tileProvider: TestTileProvider(),
    ),
    settle: false,
  ),
  _ScreenScenario(
    slug: 'place_order',
    screen: () => PlaceOrderScreen(tileProvider: TestTileProvider()),
    prepare: (state) async {
      await state.prepareVehicleSelection();
      if (state.availableVehicles.isNotEmpty) {
        state.selectVehicle(state.availableVehicles.first);
      }
    },
    settle: false,
  ),
  _ScreenScenario(slug: 'my_rides', screen: () => const MyRidesScreen()),
  _ScreenScenario(
    slug: 'vehicle_selection',
    screen: () => const VehicleSelectionScreen(),
    prepare: (state) => state.proceedToVehicleSelection(),
  ),
  _ScreenScenario(
    slug: 'fare_details',
    screen: () => const FareDetailsScreen(),
    prepare: (state) async {
      await state.proceedToVehicleSelection();
      state.selectVehicle(state.availableVehicles.first);
      state.proceedToFareReview();
    },
  ),
  _ScreenScenario(
    slug: 'booking_confirmation',
    screen: () => const BookingConfirmationScreen(),
    prepare: (state) async {
      await state.proceedToVehicleSelection();
      state.selectVehicle(state.availableVehicles.first);
      state.proceedToConfirmation();
    },
  ),
  _ScreenScenario(slug: 'safety', screen: () => const SafetyScreen()),
  _ScreenScenario(
    slug: 'help_support',
    screen: () => const HelpSupportScreen(),
  ),
  _ScreenScenario(slug: 'profile', screen: () => const ProfileScreen()),
  _ScreenScenario(
    slug: 'edit_profile',
    screen: () => const EditProfileScreen(),
  ),
  _ScreenScenario(slug: 'settings', screen: () => const SettingsScreen()),
  _ScreenScenario(
    slug: 'notifications',
    screen: () => const NotificationsScreen(),
  ),
  _ScreenScenario(
    slug: 'payment_methods',
    screen: () => const PaymentMethodsScreen(),
  ),
  _ScreenScenario(slug: 'about', screen: () => const AboutScreen()),
  _ScreenScenario(
    slug: 'saved_places',
    screen: () => const SavedPlacesScreen(),
  ),
];

Future<void> _loadFonts() async {
  await _loadFontFamily('Poppins', const [
    'assets/fonts/Poppins-Regular.ttf',
    'assets/fonts/Poppins-Medium.ttf',
    'assets/fonts/Poppins-SemiBold.ttf',
    'assets/fonts/Poppins-Bold.ttf',
    'assets/fonts/Poppins-ExtraBold.ttf',
  ]);
  await _loadFontFamily('Inter', const [
    'assets/fonts/Inter-Regular.ttf',
    'assets/fonts/Inter-Medium.ttf',
    'assets/fonts/Inter-SemiBold.ttf',
    'assets/fonts/Inter-Bold.ttf',
  ]);
  await _loadFontFamily('Manrope', const [
    'assets/fonts/manrope-regular.ttf',
    'assets/fonts/manrope-bold.ttf',
    'assets/fonts/manrope-extrabold.ttf',
  ]);
  await _loadMaterialIcons();
}

Future<void> _loadFontFamily(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    final bytes = await File(asset).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

Future<void> _loadMaterialIcons() async {
  final candidates = <String>[
    if (Platform.environment['FLUTTER_ROOT'] case final root?)
      '$root/bin/cache/artifacts/material_fonts/materialicons-regular.otf',
    _materialFontNearExecutable(),
  ];

  for (final candidate in candidates) {
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
  for (var i = 0; i < 7; i++) {
    final candidate = File(
      '${directory.path}${Platform.pathSeparator}bin'
      '${Platform.pathSeparator}cache${Platform.pathSeparator}artifacts'
      '${Platform.pathSeparator}material_fonts'
      '${Platform.pathSeparator}materialicons-regular.otf',
    );
    if (candidate.existsSync()) return candidate.path;
    directory = directory.parent;
  }
  return '';
}

Widget _buildApp({
  required Widget child,
  required AppState state,
  required Size size,
  Key? repaintKey,
}) {
  return ChangeNotifierProvider<AppState>.value(
    value: state,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EGoTheme.light,
      home: RepaintBoundary(
        key: repaintKey,
        child: SizedBox(width: size.width, height: size.height, child: child),
      ),
    ),
  );
}

void _seedRoute(AppState state) {
  state.setPickupLocation(
    const SavedLocation(
      id: 'p-test',
      label: 'Jhargram Station',
      subtitle: 'Station Road',
      coordinate: LatLng(22.4529, 86.9003),
    ),
  );
  state.setDestinationLocation(
    const SavedLocation(
      id: 'd-test',
      label: 'Jhargram Bazar',
      subtitle: 'Main Market Area',
      coordinate: LatLng(22.4701, 86.9152),
    ),
  );
}

Future<void> _capture(
  WidgetTester tester,
  _ScreenScenario scenario, {
  required Size size,
  required String outputPath,
}) async {
  await tester.runAsync(_loadFonts);

  const pixelRatio = 2.0;
  tester.view.physicalSize = size * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  SharedPreferences.setMockInitialValues({});
  final state = AppState();
  if (scenario.seedRoute) _seedRoute(state);
  if (scenario.prepare case final prepare?) {
    await tester.runAsync(() => prepare(state));
  }

  final repaintKey = GlobalKey();
  await tester.pumpWidget(
    _buildApp(
      child: scenario.screen(),
      state: state,
      size: size,
      repaintKey: repaintKey,
    ),
  );
  if (scenario.settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump(const Duration(milliseconds: 500));
  }

  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 300)),
  );
  await tester.pump();

  expect(tester.takeException(), isNull);

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in _scenarios) {
    testWidgets('captures ${scenario.slug} at 393x852', (tester) async {
      await _capture(
        tester,
        scenario,
        size: const Size(393, 852),
        outputPath: 'test/screenshots/final_${scenario.slug}_393x852.png',
      );
    });
  }

  testWidgets('all screens fit every target viewport without layout errors', (
    tester,
  ) async {
    await tester.runAsync(_loadFonts);
    const viewports = [
      Size(320, 568),
      Size(360, 800),
      Size(375, 667),
      Size(375, 812),
      Size(393, 852),
      Size(430, 932),
    ];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in viewports) {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;

      for (final scenario in _scenarios) {
        SharedPreferences.setMockInitialValues({});
        final state = AppState();
        if (scenario.seedRoute) _seedRoute(state);
        if (scenario.prepare case final prepare?) {
          await tester.runAsync(() => prepare(state));
        }

        await tester.pumpWidget(
          _buildApp(child: scenario.screen(), state: state, size: size),
        );
        if (scenario.settle) {
          await tester.pumpAndSettle();
        } else {
          await tester.pump(const Duration(milliseconds: 300));
        }

        expect(
          tester.takeException(),
          isNull,
          reason:
              '${scenario.slug} produced a layout error at '
              '${size.width.toInt()}x${size.height.toInt()}',
        );
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}
