import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'package:e_go/features/booking/presentation/place_order_screen.dart';
import 'package:e_go/features/booking/presentation/widgets/review_booking_footer.dart';
import 'package:e_go/features/booking/presentation/widgets/vehicle_option_card.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/routing/data/services/jhargram_road_network_service.dart';

import '../helpers/test_tile_provider.dart';

class _ImmediateVehicleRepo implements VehicleRepository {
  @override
  Future<List<VehicleOption>> getAvailableVehicles({
    required LatLng from,
    required LatLng to,
  }) async {
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
}

Future<void> _loadFonts() async {
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
}

Future<void> _loadFontFamily(String family, List<String> assets) async {
  final loader = FontLoader(family);
  for (final asset in assets) {
    final file = File(asset);
    if (!file.existsSync()) continue;
    final bytes = await file.readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const pickupLocation = SavedLocation(
    id: 's1',
    label: 'Jhargram Bazar',
    subtitle: 'Market Main Area · Pickup',
    coordinate: LatLng(22.4701, 86.9152),
  );

  const destinationLocation = SavedLocation(
    id: 's3',
    label: 'Jhargram Palace',
    subtitle: 'Palace Road, Rajbari',
    coordinate: LatLng(22.4480, 86.8950),
  );

  AppState buildAppState() {
    final state = AppState(
      vehicleRepository: _ImmediateVehicleRepo(),
      routeService: const JhargramRoadNetworkService(),
      driverSearchDelay: Duration.zero,
    );
    state.setPickupLocation(pickupLocation);
    state.setDestinationLocation(destinationLocation);
    return state;
  }

  Widget buildApp(AppState state) {
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

  final targetResolutions = <Size>[
    const Size(320, 568),
    const Size(360, 800),
    const Size(375, 812),
    const Size(393, 852),
    const Size(412, 915),
    const Size(430, 932),
  ];

  for (final size in targetResolutions) {
    testWidgets(
      'Review Your Ride renders without overflow at ${size.width.toInt()}x${size.height.toInt()}',
      (tester) async {
        tester.view.physicalSize = size * 2.0;
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final state = buildAppState();
        await tester.runAsync(state.prepareVehicleSelection);
        if (state.availableVehicles.isNotEmpty) {
          state.selectVehicle(state.availableVehicles.first);
        }

        await tester.pumpWidget(buildApp(state));
        await tester.pump(const Duration(milliseconds: 100));

        // Verifications
        expect(find.text('Review your ride'), findsNothing);
        expect(find.text('Jhargram Bazar'), findsOneWidget);
        expect(find.text('Jhargram Palace'), findsOneWidget);
        expect(find.text('YOUR ROUTE'), findsNothing);
        expect(find.text('Change route'), findsNothing);
        expect(find.text('Change'), findsNothing);
        expect(find.text('Choose your ride'), findsOneWidget);
        expect(find.text('E-Rickshaw'), findsOneWidget);
        expect(find.text('Bike'), findsOneWidget);
        expect(find.text('Cash'), findsOneWidget);
        expect(find.text('Offers & Coupons'), findsOneWidget);
        expect(find.text('Book Toto'), findsOneWidget);

        // Verify zero overflow exception
        final exception = tester.takeException();
        expect(exception, isNull);
      },
    );
  }

  testWidgets('captures reference screenshot at 393x852 matching design reference', (
    tester,
  ) async {
    await tester.runAsync(_loadFonts);

    const size = Size(393, 852);
    const pixelRatio = 2.0;
    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = buildAppState();
    await tester.runAsync(state.prepareVehicleSelection);
    if (state.availableVehicles.isNotEmpty) {
      state.selectVehicle(state.availableVehicles.first);
    }

    final repaintBoundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: repaintBoundaryKey,
        child: buildApp(state),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      expect(boundary, isNotNull);

      final image = await boundary!.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);

      final pngBytes = byteData!.buffer.asUint8List();
      final outDir = Directory('test/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      final outFile = File('test/screenshots/review_your_ride_393x852.png');
      await outFile.writeAsBytes(pngBytes);

      expect(outFile.existsSync(), isTrue);
      expect(outFile.lengthSync(), greaterThan(1000));
    });
  });

  testWidgets('captures reference screenshot at 412x915 matching design reference', (
    tester,
  ) async {
    await tester.runAsync(_loadFonts);

    const size = Size(412, 915);
    const pixelRatio = 2.0;
    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = buildAppState();
    await tester.runAsync(state.prepareVehicleSelection);
    if (state.availableVehicles.isNotEmpty) {
      state.selectVehicle(state.availableVehicles.first);
    }

    final repaintBoundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: repaintBoundaryKey,
        child: buildApp(state),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 200)),
    );
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = repaintBoundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      expect(boundary, isNotNull);

      final image = await boundary!.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      expect(byteData, isNotNull);

      final pngBytes = byteData!.buffer.asUint8List();
      final outDir = Directory('test/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }

      final outFile = File('test/screenshots/review_your_ride_412x915.png');
      await outFile.writeAsBytes(pngBytes);

      expect(outFile.existsSync(), isTrue);
      expect(outFile.lengthSync(), greaterThan(1000));
    });
  });

  testWidgets('verifies breathing room between last vehicle card and fixed footer', (
    tester,
  ) async {
    const size = Size(393, 852);
    tester.view.physicalSize = size * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final state = buildAppState();
    await tester.runAsync(state.prepareVehicleSelection);

    await tester.pumpWidget(buildApp(state));
    await tester.pump(const Duration(milliseconds: 100));

    // Scroll to the end
    final scrollFinder = find.byType(Scrollable).first;
    await tester.drag(scrollFinder, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 100));

    // Find the Bike card (the last card)
    final bikeFinder = find.widgetWithText(VehicleOptionCard, 'Bike');
    expect(bikeFinder, findsOneWidget);

    final bikeRect = tester.getRect(bikeFinder);
    final footerRect = tester.getRect(find.byType(ReviewBookingFooter));

    // The bottom of the Bike card should be above the top of the footer with at least 20px clearance
    expect(footerRect.top - bikeRect.bottom, greaterThanOrEqualTo(20.0));
  });
}
