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
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_one.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_two.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_three.dart';

Future<void> _loadFonts() async {
  Future<ByteData> bytes(String path) async {
    final data = await File(path).readAsBytes();
    return ByteData.view(data.buffer);
  }

  final poppins = FontLoader(EGoTypography.fontFamilyDisplay)
    ..addFont(bytes('assets/fonts/Poppins-SemiBold.ttf'))
    ..addFont(bytes('assets/fonts/Poppins-Bold.ttf'))
    ..addFont(bytes('assets/fonts/Poppins-ExtraBold.ttf'));
  await poppins.load();

  final inter = FontLoader(EGoTypography.fontFamilyBody)
    ..addFont(bytes('assets/fonts/Inter-Regular.ttf'))
    ..addFont(bytes('assets/fonts/Inter-Medium.ttf'))
    ..addFont(bytes('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(bytes('assets/fonts/Inter-Bold.ttf'));
  await inter.load();
}

Future<void> _captureScreen({
  required WidgetTester tester,
  required Widget screen,
  required Size logicalSize,
  required EdgeInsets padding,
  required String outputPath,
}) async {
  SharedPreferences.setMockInitialValues({});
  await tester.runAsync(() async {
    await _loadFonts();
  });

  final repaintKey = GlobalKey();
  const pixelRatio = 2.0;

  tester.view.physicalSize = Size(
    logicalSize.width * pixelRatio,
    logicalSize.height * pixelRatio,
  );
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(() => tester.view.resetPhysicalSize());

  await tester.pumpWidget(
    ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: EGoTheme.light,
        onGenerateRoute: EGoRouter.generateRoute,
        home: MediaQuery(
          data: MediaQueryData(size: logicalSize, padding: padding),
          child: Center(
            child: RepaintBoundary(
              key: repaintKey,
              child: SizedBox(
                width: logicalSize.width,
                height: logicalSize.height,
                child: screen,
              ),
            ),
          ),
        ),
      ),
    ),
  );

  await tester.pump(const Duration(milliseconds: 500));

  await tester.runAsync(() async {
    final boundary =
        repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final file = File(outputPath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(pngBytes);
    expect(file.existsSync(), isTrue);
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── Canonical Viewport: 393 × 852 ──────────────────────────────────────────
  group('393x852 Screenshots', () {
    testWidgets('Screen 1 at 393x852', (tester) async {
      await _captureScreen(
        tester: tester,
        screen: const OnboardingScreenOne(enableAnimations: false),
        logicalSize: const Size(393, 852),
        padding: const EdgeInsets.only(top: 48, bottom: 34),
        outputPath: 'test/screenshots/onboarding_screen_one_393x852.png',
      );
    });

    testWidgets('Screen 2 at 393x852', (tester) async {
      await _captureScreen(
        tester: tester,
        screen: const OnboardingScreenTwo(enableAnimations: false),
        logicalSize: const Size(393, 852),
        padding: const EdgeInsets.only(top: 48, bottom: 34),
        outputPath: 'test/screenshots/onboarding_screen_two_393x852.png',
      );
    });

    testWidgets('Screen 3 at 393x852', (tester) async {
      await _captureScreen(
        tester: tester,
        screen: const OnboardingScreenThree(enableAnimations: false),
        logicalSize: const Size(393, 852),
        padding: const EdgeInsets.only(top: 48, bottom: 34),
        outputPath: 'test/screenshots/onboarding_screen_three_393x852.png',
      );
    });
  });

  // ── Compact Viewport: 375 × 667 (iPhone SE) ──────────────────────────────
  group('375x667 Screenshots', () {
    testWidgets('Screen 1 at 375x667', (tester) async {
      await _captureScreen(
        tester: tester,
        screen: const OnboardingScreenOne(enableAnimations: false),
        logicalSize: const Size(375, 667),
        padding: const EdgeInsets.only(top: 20, bottom: 0),
        outputPath: 'test/screenshots/onboarding_screen_one_375x667.png',
      );
    });

    testWidgets('Screen 2 at 375x667', (tester) async {
      await _captureScreen(
        tester: tester,
        screen: const OnboardingScreenTwo(enableAnimations: false),
        logicalSize: const Size(375, 667),
        padding: const EdgeInsets.only(top: 20, bottom: 0),
        outputPath: 'test/screenshots/onboarding_screen_two_375x667.png',
      );
    });

    testWidgets('Screen 3 at 375x667', (tester) async {
      await _captureScreen(
        tester: tester,
        screen: const OnboardingScreenThree(enableAnimations: false),
        logicalSize: const Size(375, 667),
        padding: const EdgeInsets.only(top: 20, bottom: 0),
        outputPath: 'test/screenshots/onboarding_screen_three_375x667.png',
      );
    });
  });
}
