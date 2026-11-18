import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_one.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_two.dart';
import 'package:e_go/features/onboarding/presentation/screens/onboarding_screen_three.dart';
import 'package:e_go/features/auth/presentation/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Complete 3-screen onboarding flow: Screen 1 -> Screen 2 -> Screen 3 -> Login',
    (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final appState = AppState();

      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: appState,
          child: const MaterialApp(
            initialRoute: EGoRouter.onboarding,
            onGenerateRoute: EGoRouter.generateRoute,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Screen 01 is rendered
      expect(find.byType(OnboardingScreenOne), findsOneWidget);
      expect(find.text('Move your way,\nevery day'), findsOneWidget);

      // Tap CTA on Screen 01 ("Get started")
      await tester.tap(find.text('Get started'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 2. Verify Screen 02 is rendered
      expect(find.byType(OnboardingScreenTwo), findsOneWidget);
      expect(find.text('Fast bike rides,\nanytime'), findsOneWidget);

      // Tap CTA on Screen 02 ("Next")
      await tester.tap(
        find.descendant(
          of: find.byType(OnboardingScreenTwo),
          matching: find.text('Next'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 3. Verify Screen 03 is rendered
      expect(find.byType(OnboardingScreenThree), findsOneWidget);
      expect(find.text('Ride across\nJhargram'), findsOneWidget);

      // Tap CTA on Screen 03 ("Next")
      await tester.tap(
        find.descendant(
          of: find.byType(OnboardingScreenThree),
          matching: find.text('Next'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 4. Verify Onboarding completes and routes to LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(appState.hasCompletedOnboarding, isTrue);

      // Flush splash screen navigation delay timer
      await tester.pump(const Duration(seconds: 3));
    },
  );
}
