import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:e_go/features/auth/presentation/login_screen.dart';
import 'package:e_go/features/auth/presentation/otp_screen.dart';
import 'package:e_go/features/home/presentation/home_screen.dart';

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

void _usePhoneViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(393 * 2, 852 * 2);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.resetPhysicalSize);
}

Future<void> _pumpApp(
  WidgetTester tester,
  AppState appState, {
  required String initialRoute,
}) async {
  await tester.pumpWidget(_buildApp(appState, initialRoute: initialRoute));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
}

Finder _fieldIn(String key) =>
    find.descendant(of: find.byKey(Key(key)), matching: find.byType(TextField));

Future<void> _login(
  WidgetTester tester, {
  required String phone,
  required String password,
}) async {
  await tester.enterText(find.byKey(const Key('login_phone_input')), phone);
  await tester.enterText(_fieldIn('login_password_field'), password);
  await tester.pump();
  await tester.tap(find.text('Continue'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> _fillRegistration(
  WidgetTester tester, {
  required String name,
  required String phone,
  required String password,
  String? email,
}) async {
  await tester.enterText(_fieldIn('register_name_field'), name);
  await tester.enterText(_fieldIn('register_phone_field'), phone);
  await tester.enterText(_fieldIn('register_password_field'), password);
  if (email != null) {
    await tester.enterText(_fieldIn('register_email_field'), email);
  }
  await tester.pump();
  // Accept terms consent checkbox
  await tester.tap(find.byKey(const Key('terms_consent_row')));
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Login screen flow', () {
    testWidgets('demo credentials navigate to Home and create a session', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.login);
      expect(find.byType(LoginScreen), findsOneWidget);

      await _login(
        tester,
        phone: MockAuthRepository.demoPhone,
        password: MockAuthRepository.demoPassword,
      );

      expect(find.byType(EGoHomeScreen), findsOneWidget);
      expect(appState.isLoggedIn, isTrue);
      expect(appState.profile.name, MockAuthRepository.demoName);

      // Flush the mock location lookup timer before disposing the tree.
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('wrong password stays on Login with the exact error message', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.login);
      await _login(
        tester,
        phone: MockAuthRepository.demoPhone,
        password: 'wrong-password',
      );

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(appState.isLoggedIn, isFalse);
      expect(
        find.descendant(
          of: find.byKey(const Key('login_error_message')),
          matching: find.text(
            'Incorrect phone number or password. Please try again.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('unknown phone shows the create-account error', (tester) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.login);
      await _login(tester, phone: '9876543210', password: 'Anything1');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(
        find.text('No account found. Please create an account first.'),
        findsOneWidget,
      );
      expect(appState.isLoggedIn, isFalse);
    });

    testWidgets('invalid mobile number shows the exact validation message', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.login);
      await tester.enterText(
        find.byKey(const Key('login_phone_input')),
        '3123456789',
      );
      await tester.enterText(_fieldIn('login_password_field'), 'Anything1');
      await tester.pump();
      // The CTA is disabled for an invalid number, so submit from the keyboard
      // to exercise the inline error path.
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();

      expect(
        find.text('Please enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Registration and OTP flow', () {
    testWidgets(
      'valid registration requires OTP, then navigates to Home and signs in',
      (tester) async {
        _usePhoneViewport(tester);
        final appState = _newAppState();

        await _pumpApp(tester, appState, initialRoute: EGoRouter.createAccount);
        await _fillRegistration(
          tester,
          name: 'Rahul Sen',
          phone: '9876543210',
          password: 'Password123',
          email: 'rahul@example.com',
        );

        await tester.tap(find.byKey(const Key('create_account_button')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(OtpScreen), findsOneWidget);
        expect(appState.isLoggedIn, isFalse);

        await tester.enterText(find.byKey(const Key('otp_digit_0')), '123456');
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(EGoHomeScreen), findsOneWidget);
        expect(appState.isLoggedIn, isTrue);
        expect(appState.profile.phone, '+919876543210');
        expect(appState.profile.name, 'Rahul Sen');

        // Flush the mock location lookup timer before disposing the tree.
        await tester.pump(const Duration(milliseconds: 700));
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );

    testWidgets('invalid OTP keeps registration pending and shows an error', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.createAccount);
      await _fillRegistration(
        tester,
        name: 'Rahul Sen',
        phone: '9876543210',
        password: 'Password123',
      );
      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.enterText(find.byKey(const Key('otp_digit_0')), '000000');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(OtpScreen), findsOneWidget);
      expect(find.byKey(const Key('otp_error_message')), findsOneWidget);
      expect(find.text('Invalid OTP. Please try again.'), findsOneWidget);
      expect(appState.isLoggedIn, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('OTP resend becomes available after the cooldown', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.createAccount);
      await _fillRegistration(
        tester,
        name: 'Rahul Sen',
        phone: '9876543210',
        password: 'Password123',
      );
      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Resend OTP in 30s'), findsOneWidget);
      expect(find.byKey(const Key('otp_resend_button')), findsNothing);

      await tester.pump(const Duration(seconds: 31));
      expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('otp_resend_button')));
      await tester.pump();
      expect(find.text('Resend OTP in 30s'), findsOneWidget);
      expect(appState.isLoggedIn, isFalse);

      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('duplicate phone registration surfaces the error', (
      tester,
    ) async {
      _usePhoneViewport(tester);
      final appState = _newAppState();

      await _pumpApp(tester, appState, initialRoute: EGoRouter.createAccount);
      await _fillRegistration(
        tester,
        name: 'Copy Cat',
        phone: MockAuthRepository.demoPhone,
        password: 'Password123',
      );
      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(OtpScreen), findsNothing);
      expect(
        find.text(
          'An account with this phone number already exists. Please log in.',
        ),
        findsOneWidget,
      );
      expect(appState.isLoggedIn, isFalse);
    });
  });
}
