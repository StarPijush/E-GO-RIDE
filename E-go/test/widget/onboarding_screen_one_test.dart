import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_one.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_header.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_hero.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_progress.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_primary_button.dart';
import 'package:e_go/features/onboarding/presentation/widgets/onboarding_illustrations/location_illustration.dart';

Widget _createTestableWidget({
  VoidCallback? onNext,
  VoidCallback? onSkip,
  bool enableAnimations = false,
  Size screenSize = const Size(393, 852),
}) {
  return ChangeNotifierProvider(
    create: (_) => AppState(),
    child: MaterialApp(
      onGenerateRoute: EGoRouter.generateRoute,
      home: MediaQuery(
        data: MediaQueryData(
          size: screenSize,
          padding: const EdgeInsets.only(top: 44, bottom: 34),
        ),
        child: SizedBox(
          width: screenSize.width,
          height: screenSize.height,
          child: OnboardingScreenOne(
            onNext: onNext,
            onSkip: onSkip,
            enableAnimations: enableAnimations,
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('E-GO Onboarding Screen One — Pixel-Perfect Verification', () {
    testWidgets('Renders all visual components and typography correctly', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget());
      await tester.pumpAndSettle();

      // 1. Header Bar
      expect(find.byType(OnboardingHeader), findsOneWidget);
      expect(find.text('E-GO'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);

      // 2. Hero & Illustration
      expect(find.byType(OnboardingHero), findsOneWidget);
      expect(find.byType(LocationIllustration), findsOneWidget);
      expect(find.text('URBAN FLOW'), findsOneWidget);

      // 3. Heading & Supporting Text
      expect(find.text('Move your way,\nevery day'), findsOneWidget);
      expect(
        find.text(
          "Set your pickup, choose a vehicle, and ride — it's that simple.",
        ),
        findsOneWidget,
      );

      // 4. Progress Indicator & Controls
      expect(find.byType(OnboardingProgress), findsOneWidget);
      expect(find.byType(OnboardingPrimaryButton), findsOneWidget);
      expect(find.text('Get started'), findsOneWidget);
      // Screen 01 CTA must have NO arrow icon — text centered only
      expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
    });

    testWidgets('Header Skip button triggers skip callback', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var skipped = false;
      await tester.pumpWidget(
        _createTestableWidget(onSkip: () => skipped = true),
      );
      await tester.pumpAndSettle();

      final skipFinder = find.text('Skip');
      expect(skipFinder, findsOneWidget);

      await tester.tap(skipFinder);
      await tester.pumpAndSettle();

      expect(skipped, isTrue);
    });

    testWidgets('Primary CTA triggers onNext callback', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      var nextTriggered = false;
      await tester.pumpWidget(
        _createTestableWidget(onNext: () => nextTriggered = true),
      );
      await tester.pumpAndSettle();

      final buttonTextFinder = find.text('Get started');
      expect(buttonTextFinder, findsOneWidget);

      await tester.tap(buttonTextFinder);
      await tester.pumpAndSettle();

      expect(nextTriggered, isTrue);
    });

    testWidgets('Progress indicator displays step 1 as active capsule', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_createTestableWidget());
      await tester.pumpAndSettle();

      final progressFinder = find.byType(OnboardingProgress);
      expect(progressFinder, findsOneWidget);

      final progressWidget = tester.widget<OnboardingProgress>(progressFinder);
      expect(progressWidget.currentStep, equals(0));
      expect(progressWidget.totalSteps, equals(3));
    });

    testWidgets(
      'Responsive verification across multiple device screen sizes without overflow',
      (tester) async {
        final testSizes = [
          const Size(360, 800), // Standard Android
          const Size(375, 812), // iPhone X/11/12 mini
          const Size(393, 852), // Canonical Reference (iPhone 14/15/16 Pro)
          const Size(412, 915), // Pixel 7 / Large Android
          const Size(430, 932), // iPhone 14/15 Plus/Pro Max
        ];

        for (final size in testSizes) {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(_createTestableWidget(screenSize: size));
          await tester.pumpAndSettle();

          // Ensure no RenderFlex overflow exception occurred
          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed for screen size: $size',
          );

          // Ensure essential components are rendered
          expect(find.text('E-GO'), findsOneWidget);
          expect(find.text('Move your way,\nevery day'), findsOneWidget);
          expect(find.text('Get started'), findsOneWidget);
        }

        tester.view.resetPhysicalSize();
      },
    );
  });
}
