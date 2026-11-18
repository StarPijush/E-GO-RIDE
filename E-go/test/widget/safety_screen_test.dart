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
import 'package:e_go/features/safety/presentation/screens/safety_screen.dart';

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

Widget buildTestWidget({AppState? state, Key? repaintKey, Size? size}) {
  SharedPreferences.setMockInitialValues({});
  final appState = state ?? AppState();
  final content = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: EGoTheme.light,
    onGenerateRoute: EGoRouter.generateRoute,
    home: RepaintBoundary(
      key: repaintKey,
      child: const SafetyScreen(),
    ),
  );

  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: size != null
        ? SizedBox(width: size.width, height: size.height, child: content)
        : content,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SafetyScreen Widget & Visual Tests', () {
    testWidgets('renders all expected headers, sections, rows and tips',
        (tester) async {
      await tester.runAsync(_loadFonts);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Top app bar
      expect(find.text('Safety'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Hero banner
      expect(find.text('Your safety matters'), findsOneWidget);
      expect(
        find.text(
          'Emergency assistance and ride safety information for every trip across India.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.verified_user), findsOneWidget);

      // Emergency Assistance
      expect(find.text('EMERGENCY ASSISTANCE'), findsOneWidget);
      expect(find.text('Emergency SOS'), findsWidgets);
      expect(
        find.text(
          'Instantly connect with local emergency services and alert your trusted contacts with live tracking.',
        ),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.emergency), findsOneWidget);

      // During Your Ride
      expect(find.text('DURING YOUR RIDE'), findsOneWidget);
      expect(find.text('Share Trip'), findsOneWidget);
      expect(find.text('Driver & Vehicle Details'), findsOneWidget);
      expect(find.text('Contact Driver'), findsOneWidget);
      expect(find.text('Report a Safety Issue'), findsOneWidget);

      // Travel Safely (scroll to reveal)
      await tester.scrollUntilVisible(
        find.text('TRAVEL SAFELY'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('TRAVEL SAFELY'), findsOneWidget);
      expect(find.text('01'), findsOneWidget);
      expect(
        find.text('Verify your driver and vehicle before boarding.'),
        findsOneWidget,
      );
      expect(find.text('02'), findsOneWidget);
      expect(
        find.text('Confirm your destination and fare before starting your trip.'),
        findsOneWidget,
      );
      expect(find.text('03'), findsOneWidget);
      expect(
        find.text('Share your trip details with someone you trust.'),
        findsOneWidget,
      );

      // Help & Support (scroll to bottom)
      await tester.scrollUntilVisible(
        find.text('Help & Support'),
        300,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Help & Support'), findsOneWidget);
      expect(
        find.text('Dedicated passenger incident team'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.support_agent), findsOneWidget);
    });

    testWidgets('Emergency SOS opens confirmation dialog and handles simulation',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      final sosButton = find.widgetWithText(ElevatedButton, 'Emergency SOS');
      expect(sosButton, findsOneWidget);

      await tester.tap(sosButton);
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
          'Notice: Real emergency service dispatch is not integrated in this simulated demo environment.',
        ),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Simulate Alert'), findsOneWidget);

      await tester.tap(find.text('Simulate Alert'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Emergency SOS triggered (Demo Simulation). No emergency services were contacted.',
        ),
        findsOneWidget,
      );
    });

    testWidgets(
        'During ride rows handle interactions gracefully without active ride',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap Share Trip
      await tester.tap(find.text('Share Trip'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No active ride to share. Trip sharing is active during ongoing rides.',
        ),
        findsOneWidget,
      );

      // Dismiss SnackBar and advance time
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Tap Driver & Vehicle Details
      await tester.tap(find.text('Driver & Vehicle Details'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No active ride. Driver details appear once a ride is assigned.',
        ),
        findsOneWidget,
      );

      // Dismiss SnackBar and advance time
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Scroll so Contact Driver is visible
      await tester.scrollUntilVisible(
        find.text('Contact Driver'),
        100,
        scrollable: find.byType(Scrollable),
      );

      // Tap Contact Driver
      await tester.tap(find.text('Contact Driver'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'No active driver to contact. Available during active bookings.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders properly across various viewports without layout errors',
        (tester) async {
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

        await tester.pumpWidget(buildTestWidget(size: size));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('captures top view at 393x852 showing updated hero and single-line SOS button',
        (tester) async {
      await tester.runAsync(_loadFonts);
      const size = Size(393, 852);
      const pixelRatio = 2.0;
      tester.view.physicalSize = size * pixelRatio;
      tester.view.devicePixelRatio = pixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        buildTestWidget(repaintKey: repaintKey, size: size),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = repaintKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('test/screenshots/final_safety_top_393x852.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        expect(file.existsSync(), isTrue);
      });
    });

    testWidgets('captures scrolled bottom view at 393x852 for visual verification',
        (tester) async {
      await tester.runAsync(_loadFonts);
      const size = Size(393, 852);
      const pixelRatio = 2.0;
      tester.view.physicalSize = size * pixelRatio;
      tester.view.devicePixelRatio = pixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        buildTestWidget(repaintKey: repaintKey, size: size),
      );
      await tester.pumpAndSettle();

      // Scroll to bottom so Travel Safely and Help & Support are in view
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = repaintKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: pixelRatio);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('test/screenshots/final_safety_scrolled_393x852.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        expect(file.existsSync(), isTrue);
      });
    });
  });
}
