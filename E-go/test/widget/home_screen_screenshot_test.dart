import 'dart:convert';
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
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/location/data/current_location_service.dart';
import 'package:e_go/features/location/data/recent_destinations_store.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/mock_data/mock_data.dart';
import 'package:e_go/shared/shell/ego_main_shell.dart';

import '../helpers/test_tile_provider.dart';

class _FakeAvailableLocationService implements CurrentLocationService {
  const _FakeAvailableLocationService();

  @override
  Future<CurrentLocationResult> getCurrentLocation() async {
    return const CurrentLocationResult.available(
      LatLng(22.4560, 86.9030),
      accuracy: 10.0,
    );
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
  await _loadMaterialIcons();
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('captures Home screen without recent history at 393x852', (
    tester,
  ) async {
    await tester.runAsync(_loadFonts);
    const size = Size(393, 852);
    const pixelRatio = 2.0;

    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    SharedPreferences.setMockInitialValues({});
    final state = AppState(
      currentLocationService: const _FakeAvailableLocationService(),
    );
    await tester.runAsync(state.refreshCurrentLocation);

    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: EGoTheme.light,
          home: RepaintBoundary(
            key: repaintKey,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: EGoMainShell(tileProvider: TestTileProvider()),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
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
      final file = File('test/screenshots/final_home_393x852.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      expect(file.existsSync(), isTrue);

      final noHistoryFile = File('test/screenshots/final_home_no_history_393x852.png');
      await noHistoryFile.writeAsBytes(byteData.buffer.asUint8List());
    });
  });

  testWidgets('captures Home screen with recent history at 393x852', (
    tester,
  ) async {
    await tester.runAsync(_loadFonts);
    const size = Size(393, 852);
    const pixelRatio = 2.0;

    tester.view.physicalSize = size * pixelRatio;
    tester.view.devicePixelRatio = pixelRatio;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final recentJson = jsonEncode([
      {
        'id': 's1',
        'label': 'Jhargram Bazar',
        'subtitle': 'Market Area, Jhargram',
        'lat': 22.4701,
        'lng': 86.9152,
        'type': 'market',
      },
    ]);
    SharedPreferences.setMockInitialValues({
      RecentDestinationsStore.storageKey: recentJson,
    });

    final state = AppState(
      currentLocationService: const _FakeAvailableLocationService(),
    );
    await tester.runAsync(state.refreshCurrentLocation);

    final repaintKey = GlobalKey();
    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: EGoTheme.light,
          home: RepaintBoundary(
            key: repaintKey,
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: EGoMainShell(tileProvider: TestTileProvider()),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
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
      final file = File('test/screenshots/final_home_with_recent_393x852.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      expect(file.existsSync(), isTrue);
    });
  });

  testWidgets('verifies responsive layout across all 6 target viewports without overflow', (
    tester,
  ) async {
    await tester.runAsync(_loadFonts);
    const viewports = [
      Size(320, 568),
      Size(360, 800),
      Size(375, 667),
      Size(393, 852),
      Size(412, 915),
      Size(430, 932),
    ];
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in viewports) {
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;

      SharedPreferences.setMockInitialValues({});
      final state = AppState(
        currentLocationService: const _FakeAvailableLocationService(),
      );
      await tester.runAsync(state.refreshCurrentLocation);

      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: state,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: EGoTheme.light,
            home: SizedBox(
              width: size.width,
              height: size.height,
              child: EGoMainShell(tileProvider: TestTileProvider()),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester.takeException(),
        isNull,
        reason: 'Home produced layout error at ${size.width.toInt()}x${size.height.toInt()}',
      );

      // Verify that "Where to?" and all 4 destinations are present
      expect(find.text('Where to?'), findsOneWidget);
      expect(find.text('Choose your destination'), findsOneWidget);
      expect(find.text('Jhargram Palace'), findsOneWidget);
      expect(find.text('Jhargram Station'), findsOneWidget);
      expect(find.text('Central Bus Stand'), findsOneWidget);
      expect(find.text('Kanak Durga Temple'), findsOneWidget);

      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
