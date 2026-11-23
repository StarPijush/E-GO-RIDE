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
import 'package:e_go/app/theme/theme.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';

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

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('capture Reference Set A (Empty Recent Places)', (tester) async {
    await tester.runAsync(_loadFonts);

    final state = AppState();
    state.setPickupLocation(
      const SavedLocation(
        id: 'pickup-bazar',
        label: 'Jhargram Bazar',
        subtitle: 'Main Market Area, Station Link Rd',
        coordinate: LatLng(22.4701, 86.9152),
      ),
    );

    final repaintKey = GlobalKey();
    const size = Size(393, 852);
    tester.view.physicalSize = size * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: EGoTheme.light,
          home: RepaintBoundary(
            key: repaintKey,
            child: const SizedBox(
              width: 393,
              height: 852,
              child: LocationSelectionScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('test/screenshots/reference_a_verified_393x852.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });

  testWidgets('capture Reference Set B (Populated Saved Places)', (tester) async {
    await tester.runAsync(_loadFonts);

    final state = AppState();
    state.setPickupLocation(
      const SavedLocation(
        id: 'pickup-bazar',
        label: 'Jhargram Bazar',
        subtitle: 'Main Market Area',
        coordinate: LatLng(22.4701, 86.9152),
      ),
    );
    state.setDestinationLocation(
      const SavedLocation(
        id: 'drop-home',
        label: 'Home (Kadamkanan)',
        subtitle: 'Ward 8, Kadamkanan, Jhargram',
        coordinate: LatLng(22.4580, 86.9080),
      ),
    );

    final repaintKey = GlobalKey();
    const size = Size(393, 852);
    tester.view.physicalSize = size * 2.0;
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppState>.value(
        value: state,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: EGoTheme.light,
          home: RepaintBoundary(
            key: repaintKey,
            child: const SizedBox(
              width: 393,
              height: 852,
              child: LocationSelectionScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap Saved places tab
    await tester.tap(find.text('Saved places'));
    await tester.pumpAndSettle();

    await tester.runAsync(() async {
      final boundary =
          repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('test/screenshots/reference_b_verified_393x852.png');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(byteData!.buffer.asUint8List());
    });
  });
}
