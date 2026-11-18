import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_one.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_two.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_three.dart';
import 'package:e_go/features/onboarding/presentation/theme/onboarding_constants.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_hero.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_progress.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

Widget _wrap(Widget screen, {Size size = const Size(393, 852)}) {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MaterialApp(
      onGenerateRoute: EGoRouter.generateRoute,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: SizedBox(width: size.width, height: size.height, child: screen),
      ),
    ),
  );
}

Widget _screen1({Size size = const Size(393, 852)}) =>
    _wrap(const OnboardingScreenOne(enableAnimations: false), size: size);

Widget _screen2({Size size = const Size(393, 852)}) =>
    _wrap(const OnboardingScreenTwo(enableAnimations: false), size: size);

Widget _screen3({Size size = const Size(393, 852)}) =>
    _wrap(const OnboardingScreenThree(enableAnimations: false), size: size);

// ── Shared dimensions helper ──────────────────────────────────────────────────

Size _heroSize(WidgetTester tester) {
  final heroFinder = find.byType(OnboardingHero);
  expect(heroFinder, findsOneWidget);
  final box = tester.renderObject(heroFinder) as RenderBox;
  return box.size;
}

Size _buttonSize(WidgetTester tester) {
  final btnFinder = find.byType(OnboardingPrimaryButton);
  expect(btnFinder, findsOneWidget);
  final box = tester.renderObject(btnFinder) as RenderBox;
  return box.size;
}

Offset _heroTopLeft(WidgetTester tester) {
  return tester.getTopLeft(find.byType(OnboardingHero));
}

Offset _heroCenter(WidgetTester tester) {
  return tester.getCenter(find.byType(OnboardingHero));
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── 1. Hero coordinate and geometry consistency ───────────────────────────
  group('Hero geometry & coordinates — identical across all three screens', () {
    testWidgets('All three heroes have the same width and height', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();
      final size1 = _heroSize(tester);

      await tester.pumpWidget(_screen2());
      await tester.pumpAndSettle();
      final size2 = _heroSize(tester);

      await tester.pumpWidget(_screen3());
      await tester.pumpAndSettle();
      final size3 = _heroSize(tester);

      expect(size1.width, closeTo(OnboardingConstants.heroAreaSize, 1.0));
      expect(size2.width, closeTo(size1.width, 1.0));
      expect(size3.width, closeTo(size1.width, 1.0));

      expect(size1.height, closeTo(OnboardingConstants.heroAreaSize, 1.0));
      expect(size2.height, closeTo(size1.height, 1.0));
      expect(size3.height, closeTo(size1.height, 1.0));
    });

    testWidgets(
      'All three heroes have the exact same vertical position (Top and Center)',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_screen1());
        await tester.pumpAndSettle();
        final top1 = _heroTopLeft(tester);
        final center1 = _heroCenter(tester);

        await tester.pumpWidget(_screen2());
        await tester.pumpAndSettle();
        final top2 = _heroTopLeft(tester);
        final center2 = _heroCenter(tester);

        await tester.pumpWidget(_screen3());
        await tester.pumpAndSettle();
        final top3 = _heroTopLeft(tester);
        final center3 = _heroCenter(tester);

        // Assert Screen 2 matches Screen 1
        expect(
          top2.dy,
          closeTo(top1.dy, 1.0),
          reason: 'Screen 2 hero top must match Screen 1',
        );
        expect(
          center2.dy,
          closeTo(center1.dy, 1.0),
          reason: 'Screen 2 hero center must match Screen 1',
        );

        // Assert Screen 3 matches Screen 1 (fixes previous 24px vertical offset)
        expect(
          top3.dy,
          closeTo(top1.dy, 1.0),
          reason: 'Screen 3 hero top must match Screen 1',
        );
        expect(
          center3.dy,
          closeTo(center1.dy, 1.0),
          reason: 'Screen 3 hero center must match Screen 1',
        );
      },
    );

    testWidgets('Screen 1 hero explicitly renders the 216 px ambient ring', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();

      // Find ring container (width 216, height 216, shape BoxShape.circle)
      final ringContainers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(OnboardingHero),
          matching: find.byType(Container),
        ),
      );

      final hasRing = ringContainers.any((c) {
        final dec = c.decoration;
        if (dec is BoxDecoration) {
          final isCircle = dec.shape == BoxShape.circle;
          return isCircle && dec.border != null;
        }
        return false;
      });

      expect(
        hasRing,
        isTrue,
        reason: 'Screen 1 hero must explicitly contain the ambient ring',
      );
    });
  });

  // ── 2. Standardized description region ────────────────────────────────────
  group('Description region — reserved 72px area (supports 3 lines)', () {
    testWidgets(
      'Headings on all three screens start at identical vertical top',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_screen1());
        await tester.pumpAndSettle();
        final hTop1 = tester
            .getTopLeft(find.text('Move your way,\nevery day'))
            .dy;

        await tester.pumpWidget(_screen2());
        await tester.pumpAndSettle();
        final hTop2 = tester
            .getTopLeft(find.text('Fast bike rides,\nanytime'))
            .dy;

        await tester.pumpWidget(_screen3());
        await tester.pumpAndSettle();
        final hTop3 = tester.getTopLeft(find.text('Ride across\nJhargram')).dy;

        expect(hTop2, closeTo(hTop1, 1.0));
        expect(hTop3, closeTo(hTop1, 1.0));
      },
    );

    testWidgets(
      'Progress indicator and CTA button vertical positions are identical across all screens',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_screen1());
        await tester.pumpAndSettle();
        final prog1 = tester.getTopLeft(find.byType(OnboardingProgress)).dy;
        final cta1 = tester.getTopLeft(find.byType(OnboardingPrimaryButton)).dy;

        await tester.pumpWidget(_screen2());
        await tester.pumpAndSettle();
        final prog2 = tester.getTopLeft(find.byType(OnboardingProgress)).dy;
        final cta2 = tester.getTopLeft(find.byType(OnboardingPrimaryButton)).dy;

        await tester.pumpWidget(_screen3());
        await tester.pumpAndSettle();
        final prog3 = tester.getTopLeft(find.byType(OnboardingProgress)).dy;
        final cta3 = tester.getTopLeft(find.byType(OnboardingPrimaryButton)).dy;

        expect(prog2, closeTo(prog1, 1.0));
        expect(prog3, closeTo(prog1, 1.0));

        expect(cta2, closeTo(cta1, 1.0));
        expect(cta3, closeTo(cta1, 1.0));
      },
    );
  });

  // ── 3. CTA button consistency ─────────────────────────────────────────────
  group('CTA button — identical dimensions across all three screens', () {
    testWidgets('All three CTA buttons have the same height and width', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();
      final s1 = _buttonSize(tester);

      await tester.pumpWidget(_screen2());
      await tester.pumpAndSettle();
      final s2 = _buttonSize(tester);

      await tester.pumpWidget(_screen3());
      await tester.pumpAndSettle();
      final s3 = _buttonSize(tester);

      expect(s1.height, closeTo(OnboardingConstants.ctaHeight, 1.0));
      expect(s2.height, closeTo(s1.height, 1.0));
      expect(s3.height, closeTo(s1.height, 1.0));

      expect(s2.width, closeTo(s1.width, 1.0));
      expect(s3.width, closeTo(s1.width, 1.0));
    });
  });

  // ── 4. No arrow icon on any screen ───────────────────────────────────────
  group('CTA buttons — text-centered, no arrow icon', () {
    testWidgets('Screen 1 Get started button has no arrow icon', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();

      expect(find.text('Get started'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('Screen 2 Next button has no arrow icon', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen2());
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('Screen 3 Next button has no arrow icon', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen3());
      await tester.pumpAndSettle();

      expect(find.text('Next'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });
  });

  // ── 5. Correct progress steps ─────────────────────────────────────────────
  group('Progress indicator — correct active step per screen', () {
    testWidgets('Screen 1 shows step 1 (index 0) active', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();

      final p = tester.widget<OnboardingProgress>(
        find.byType(OnboardingProgress),
      );
      expect(p.currentStep, 0);
      expect(p.totalSteps, 3);
    });

    testWidgets('Screen 2 shows step 2 (index 1) active', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen2());
      await tester.pumpAndSettle();

      final p = tester.widget<OnboardingProgress>(
        find.byType(OnboardingProgress),
      );
      expect(p.currentStep, 1);
      expect(p.totalSteps, 3);
    });

    testWidgets('Screen 3 shows step 3 (index 2) active', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen3());
      await tester.pumpAndSettle();

      final p = tester.widget<OnboardingProgress>(
        find.byType(OnboardingProgress),
      );
      expect(p.currentStep, 2);
      expect(p.totalSteps, 3);
    });
  });

  // ── 6. No overflow at all 6 viewport sizes (including 375×667) ────────────
  group('No RenderFlex overflow across all responsive viewports', () {
    final sizes = [
      const Size(375, 667), // iPhone SE / 8 compact
      const Size(360, 800), // Standard Android
      const Size(375, 812), // iPhone X/11/12 mini
      const Size(393, 852), // Canonical Reference
      const Size(412, 915), // Pixel 7 / Large Android
      const Size(430, 932), // iPhone 14/15 Plus/Pro Max
    ];

    for (final size in sizes) {
      testWidgets('Screen 1 — no overflow at $size', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_screen1(size: size));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on Screen 1 at $size',
        );
      });

      testWidgets('Screen 2 — no overflow at $size', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_screen2(size: size));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on Screen 2 at $size',
        );
      });

      testWidgets('Screen 3 — no overflow at $size', (tester) async {
        tester.view.physicalSize = Size(size.width * 2, size.height * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(tester.view.resetPhysicalSize);

        await tester.pumpWidget(_screen3(size: size));
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'Overflow on Screen 3 at $size',
        );
      });
    }
  });

  // ── 7. Header wordmark visibility ─────────────────────────────────────────
  group('Header wordmark visibility', () {
    testWidgets('Screen 1 shows E-GO wordmark', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();
      expect(find.text('E-GO'), findsOneWidget);
    });

    testWidgets('Screen 2 hides E-GO wordmark', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen2());
      await tester.pumpAndSettle();
      expect(find.text('E-GO'), findsNothing);
    });

    testWidgets('Screen 3 hides E-GO wordmark', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen3());
      await tester.pumpAndSettle();
      expect(find.text('E-GO'), findsNothing);
    });
  });

  // ── 8. CTA labels ─────────────────────────────────────────────────────────
  group('CTA labels are correct per screen', () {
    testWidgets('Screen 1 CTA label is "Get started"', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen1());
      await tester.pumpAndSettle();
      expect(find.text('Get started'), findsOneWidget);
    });

    testWidgets('Screen 2 CTA label is "Next"', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen2());
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('Screen 3 CTA label is "Next"', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(_screen3());
      await tester.pumpAndSettle();
      expect(find.text('Next'), findsOneWidget);
    });
  });
}
