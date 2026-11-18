import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/features/account/presentation/profile_screen.dart';
import 'package:e_go/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:e_go/features/auth/presentation/login_screen.dart';
import 'package:e_go/features/support/presentation/help_support_screen.dart';

Widget _buildApp(AppState appState, {required String initialRoute}) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: initialRoute,
      onGenerateRoute: (settings) => EGoRouter.generateRoute(
        settings,
        isAuthenticated: () => appState.isLoggedIn,
      ),
      onGenerateInitialRoutes: (initialRoute) => [
        EGoRouter.generateRoute(
          RouteSettings(name: initialRoute),
          isAuthenticated: () => appState.isLoggedIn,
        ),
      ],
    ),
  );
}

AppState _newAppState() {
  final appState = AppState(
    authRepository: MockAuthRepository(latency: Duration.zero),
  );
  addTearDown(appState.dispose);
  return appState;
}

Future<void> _waitForAuthInit(AppState appState) async {
  while (!appState.isAuthInitialized) {
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('protected route redirects an unauthenticated visitor to Login', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = _newAppState();
    await tester.pumpWidget(
      _buildApp(appState, initialRoute: EGoRouter.profile),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(appState.isLoggedIn, isFalse);
  });

  testWidgets('public Help & Support route stays accessible without auth', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = _newAppState();
    await tester.pumpWidget(
      _buildApp(appState, initialRoute: EGoRouter.helpSupport),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.byType(HelpSupportScreen), findsOneWidget);
    expect(find.byType(LoginScreen), findsNothing);
  });

  testWidgets('logout clears the session and returns to Login', (tester) async {
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);

    final appState = _newAppState();
    await tester.runAsync(() async {
      await _waitForAuthInit(appState);
      final success = await appState.loginWithPassword(
        phone: MockAuthRepository.demoPhone,
        password: MockAuthRepository.demoPassword,
      );
      expect(success, isTrue);
    });

    await tester.pumpWidget(
      _buildApp(appState, initialRoute: EGoRouter.profile),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(ProfileScreen), findsOneWidget);

    await tester.ensureVisible(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Log out'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.byType(ProfileScreen), findsNothing);
    expect(appState.isLoggedIn, isFalse);
    expect(appState.profile.phone, isEmpty);
  });

  test('onboarding completion survives logout', () async {
    final appState = _newAppState();
    await _waitForAuthInit(appState);
    await appState.loginWithPassword(
      phone: MockAuthRepository.demoPhone,
      password: MockAuthRepository.demoPassword,
    );
    await appState.markOnboardingComplete();

    expect(appState.isLoggedIn, isTrue);
    expect(appState.hasCompletedOnboarding, isTrue);

    await appState.logout();

    expect(appState.isLoggedIn, isFalse);
    expect(appState.hasCompletedOnboarding, isTrue);
  });
}
