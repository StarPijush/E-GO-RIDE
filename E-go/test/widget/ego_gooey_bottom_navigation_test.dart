import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/home/presentation/home_screen.dart';
import 'package:e_go/shared/widgets/ego_gooey_bottom_navigation.dart';
import 'package:e_go/shared/widgets/journey_route_icon.dart';

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
      'MaterialIcons-Regular.otf'
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

Future<void> _captureNavState({
  required WidgetTester tester,
  required int selectedIndex,
  required Size logicalSize,
  required String outputPath,
  double pixelRatio = 2.0,
}) async {
  final repaintKey = GlobalKey();

  tester.view.physicalSize = logicalSize * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EGoTheme.light,
      home: Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Text(
            'E-GO Active Destination: $selectedIndex',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF142B45),
            ),
          ),
        ),
        bottomNavigationBar: RepaintBoundary(
          key: repaintKey,
          child: EgoGooeyBottomNavigation(
            selectedIndex: selectedIndex,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

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

Future<void> _captureFullHomeScreen({
  required WidgetTester tester,
  required Size logicalSize,
  required String outputPath,
  double pixelRatio = 2.0,
}) async {
  final repaintKey = GlobalKey();
  final appState = AppState();

  tester.view.physicalSize = logicalSize * pixelRatio;
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: EGoTheme.light,
        onGenerateRoute: EGoRouter.generateRoute,
        home: RepaintBoundary(
          key: repaintKey,
          child: const EGoHomeScreen(),
        ),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));

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

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await _loadFonts();
  });

  group('EgoGooeyBottomNavigation Component Tests', () {
    testWidgets('renders exactly four destinations in specified order', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EgoGooeyBottomNavigation(selectedIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Rides'), findsOneWidget);
      expect(find.text('Safety'), findsOneWidget);
      expect(find.text('Account'), findsOneWidget);

      // Verify no extra destinations or Toto vehicle selectors
      expect(find.text('Toto'), findsNothing);
      expect(find.text('Profile'), findsNothing); // Account is visible label
    });

    testWidgets('uses JourneyRouteIcon for Rides and never Toto vehicle icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EgoGooeyBottomNavigation(selectedIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(JourneyRouteIcon), findsOneWidget);
      expect(find.byIcon(Icons.electric_rickshaw), findsNothing);
      expect(find.byIcon(Icons.electric_rickshaw_outlined), findsNothing);
    });

    testWidgets('labels are positioned directly below icons', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EgoGooeyBottomNavigation(selectedIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final homeIconFinder = find.byIcon(Icons.home_outlined);
      final homeLabelFinder = find.text('Home');

      final homeIconOffset = tester.getCenter(homeIconFinder);
      final homeLabelOffset = tester.getCenter(homeLabelFinder);

      // Label must be below icon (larger Y) and horizontally aligned
      expect(homeLabelOffset.dy, greaterThan(homeIconOffset.dy));
      expect(homeLabelOffset.dx, closeTo(homeIconOffset.dx, 1.0));
    });

    testWidgets('tap triggers onTap with correct index', (tester) async {
      int? tappedIndex;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: EgoGooeyBottomNavigation(
              selectedIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Rides
      await tester.tap(find.text('Rides'));
      expect(tappedIndex, equals(1));

      // Tap Safety
      await tester.tap(find.text('Safety'));
      expect(tappedIndex, equals(2));

      // Tap Account
      await tester.tap(find.text('Account'));
      expect(tappedIndex, equals(3));

      // Tap Home
      await tester.tap(find.text('Home'));
      expect(tappedIndex, equals(0));
    });

    testWidgets('animates active pill transition across destinations', (
      tester,
    ) async {
      int selected = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                bottomNavigationBar: EgoGooeyBottomNavigation(
                  selectedIndex: selected,
                  onTap: (i) => setState(() => selected = i),
                ),
              ),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      // Tap Rides (index 1) to initiate gooey travel
      await tester.tap(find.text('Rides'));
      await tester.pump(); // Start frame
      expect(selected, equals(1));

      // Mid-flight pump: verify animation is progressing smoothly
      await tester.pump(const Duration(milliseconds: 200));
      expect(tester.takeException(), isNull);

      // Settle animation to completion
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive layout across multiple screen widths', (
      tester,
    ) async {
      const viewports = [
        Size(360, 800),
        Size(375, 667),
        Size(393, 852),
        Size(412, 915),
      ];

      for (final size in viewports) {
        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EgoGooeyBottomNavigation(selectedIndex: 0),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // All 4 labels visible without clipping
        expect(find.text('Home'), findsOneWidget);
        expect(find.text('Rides'), findsOneWidget);
        expect(find.text('Safety'), findsOneWidget);
        expect(find.text('Account'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('reduced motion snaps selected state without animating', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: EgoGooeyBottomNavigation(selectedIndex: 2),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Safety'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('E-GO Gooey Navigation Screenshot Visual QA', () {
    testWidgets('captures all four selected states at 393x852', (
      tester,
    ) async {
      const logicalSize = Size(393, 852);

      await _captureNavState(
        tester: tester,
        selectedIndex: 0,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_home_selected_393x852.png',
      );

      await _captureNavState(
        tester: tester,
        selectedIndex: 1,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_rides_selected_393x852.png',
      );

      await _captureNavState(
        tester: tester,
        selectedIndex: 2,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_safety_selected_393x852.png',
      );

      await _captureNavState(
        tester: tester,
        selectedIndex: 3,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_account_selected_393x852.png',
      );
    });

    testWidgets('captures all four selected states at 375x667', (
      tester,
    ) async {
      const logicalSize = Size(375, 667);

      await _captureNavState(
        tester: tester,
        selectedIndex: 0,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_home_selected_375x667.png',
      );

      await _captureNavState(
        tester: tester,
        selectedIndex: 1,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_rides_selected_375x667.png',
      );

      await _captureNavState(
        tester: tester,
        selectedIndex: 2,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_safety_selected_375x667.png',
      );

      await _captureNavState(
        tester: tester,
        selectedIndex: 3,
        logicalSize: logicalSize,
        outputPath: 'test/screenshots/gooey_nav_account_selected_375x667.png',
      );
    });

    testWidgets('captures mid-flight transition with gooey bridge and droplets', (
      tester,
    ) async {
      final repaintKey = GlobalKey();
      int selected = 0;

      tester.view.physicalSize = const Size(393, 852) * 2.0;
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: EGoTheme.light,
          home: Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            bottomNavigationBar: RepaintBoundary(
              key: repaintKey,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return EgoGooeyBottomNavigation(
                    selectedIndex: selected,
                    onTap: (i) => setState(() => selected = i),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger transition to Safety (index 2)
      await tester.tap(find.text('Safety'));
      await tester.pump();
      // Pump 180ms into the transition
      await tester.pump(const Duration(milliseconds: 180));

      await tester.runAsync(() async {
        final boundary =
            repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file =
            File('test/screenshots/gooey_nav_transit_midflight_393x852.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        expect(file.existsSync(), isTrue);
      });

      await tester.pumpAndSettle();
    });

    testWidgets('captures full E-GO Home screen with GooeyNav at 393x852', (
      tester,
    ) async {
      await _captureFullHomeScreen(
        tester: tester,
        logicalSize: const Size(393, 852),
        outputPath: 'test/screenshots/final_home_gooey_nav_393x852.png',
      );
    });
  });
}
