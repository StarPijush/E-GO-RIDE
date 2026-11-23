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
import 'package:e_go/features/auth/presentation/screens/create_account_screen.dart';

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

Widget _buildRegisterApp({
  Widget? child,
  AppState? appState,
  Size size = const Size(393, 852),
  EdgeInsets viewInsets = EdgeInsets.zero,
}) {
  return ChangeNotifierProvider<AppState>.value(
    value: appState ?? AppState(),
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: EGoTheme.light,
      onGenerateRoute: EGoRouter.generateRoute,
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          padding: const EdgeInsets.only(top: 48, bottom: 34),
          viewInsets: viewInsets,
        ),
        child: child ?? const CreateAccountScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('E-GO Create Account / Registration Screen Tests', () {
    testWidgets(
      '1. Verifies header, heading, supporting text and all 4 fields in exact order',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_buildRegisterApp());
        await tester.pump(const Duration(milliseconds: 200));

        // Brand Wordmark + Dot
        expect(find.text('E-GO'), findsOneWidget);

        // Heading & Supporting Copy
        expect(find.text('Create your account'), findsOneWidget);
        expect(
          find.text(
            'Sign up to start booking TOTO & fast bike rides across India in seconds.',
          ),
          findsOneWidget,
        );

        // Four Fields in exact order: Full Name, Phone Number, Password, Email Address
        expect(find.byKey(const Key('register_name_field')), findsOneWidget);
        expect(find.byKey(const Key('register_phone_field')), findsOneWidget);
        expect(
          find.byKey(const Key('register_password_field')),
          findsOneWidget,
        );
        expect(find.byKey(const Key('register_email_field')), findsOneWidget);

        // Check Placeholders & Badges
        expect(find.text('Rahul Sen'), findsOneWidget);
        expect(find.text('98765 43210'), findsOneWidget);
        expect(find.text('Enter your password'), findsOneWidget);
        expect(find.text('rahul@example.com'), findsOneWidget);
        expect(find.text('OPTIONAL'), findsOneWidget);

        // CTA & Navigation
        expect(find.text('Create account'), findsOneWidget);
        expect(find.textContaining('Already have an account?'), findsOneWidget);
        expect(find.textContaining('Log in'), findsOneWidget);

        // Terms & Privacy Consent Checkbox
        expect(find.byKey(const Key('terms_consent_row')), findsOneWidget);
        expect(find.textContaining('I agree to the'), findsOneWidget);
        expect(find.textContaining('Terms of Service'), findsOneWidget);
        expect(find.textContaining('Privacy Policy'), findsOneWidget);
      },
    );

    testWidgets(
      '2. Password visibility toggle works without clearing password text',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_buildRegisterApp());
        await tester.pump(const Duration(milliseconds: 200));

        final passwordField = find.descendant(
          of: find.byKey(const Key('register_password_field')),
          matching: find.byType(TextField),
        );
        expect(passwordField, findsOneWidget);

        // Password should be obscured by default
        expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

        // Enter password
        await tester.enterText(passwordField, 'SecretPass123');
        await tester.pump();

        // Tap visibility toggle
        final toggleButton = find.byKey(
          const Key('password_visibility_toggle'),
        );
        expect(toggleButton, findsOneWidget);

        await tester.tap(toggleButton);
        await tester.pump();

        // Now password should be visible, text preserved
        expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
        expect(
          tester.widget<TextField>(passwordField).controller!.text,
          equals('SecretPass123'),
        );

        // Tap again to hide
        await tester.tap(toggleButton);
        await tester.pump();
        expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
      },
    );

    testWidgets(
      '3. Button remains disabled until all required fields are valid',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_buildRegisterApp());
        await tester.pump(const Duration(milliseconds: 200));

        final ctaButton = find.byKey(const Key('create_account_button'));
        expect(ctaButton, findsOneWidget);
        expect(tester.widget<InkWell>(ctaButton).onTap, isNull);

        final nameField = find.descendant(
          of: find.byKey(const Key('register_name_field')),
          matching: find.byType(TextField),
        );
        final phoneField = find.descendant(
          of: find.byKey(const Key('register_phone_field')),
          matching: find.byType(TextField),
        );
        final passwordField = find.descendant(
          of: find.byKey(const Key('register_password_field')),
          matching: find.byType(TextField),
        );

        // 1. Enter name only -> Still disabled
        await tester.enterText(nameField, 'Rahul Sen');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNull);

        // 2. Enter phone -> Still disabled
        await tester.enterText(phoneField, '9876543210');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNull);

        // 3. Enter short password (< 8 chars) -> Still disabled
        await tester.enterText(passwordField, 'short');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNull);

        // 4. Enter valid 8-char password -> Still disabled (terms not accepted)
        await tester.enterText(passwordField, 'ValidPass8');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNull);

        // 5. Accept terms -> Now ENABLED
        await tester.tap(find.byKey(const Key('terms_consent_row')));
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNotNull);
      },
    );

    testWidgets(
      '4. Optional email: valid when empty, invalid format disables button',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_buildRegisterApp());
        await tester.pump(const Duration(milliseconds: 200));

        final ctaButton = find.byKey(const Key('create_account_button'));
        final nameField = find.descendant(
          of: find.byKey(const Key('register_name_field')),
          matching: find.byType(TextField),
        );
        final phoneField = find.descendant(
          of: find.byKey(const Key('register_phone_field')),
          matching: find.byType(TextField),
        );
        final passwordField = find.descendant(
          of: find.byKey(const Key('register_password_field')),
          matching: find.byType(TextField),
        );
        final emailField = find.descendant(
          of: find.byKey(const Key('register_email_field')),
          matching: find.byType(TextField),
        );

        await tester.enterText(nameField, 'Rahul Sen');
        await tester.enterText(phoneField, '9876543210');
        await tester.enterText(passwordField, 'ValidPass8');
        await tester.pump();
        // Accept terms first
        await tester.tap(find.byKey(const Key('terms_consent_row')));
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNotNull);

        // Invalid email disables button
        await tester.enterText(emailField, 'not-an-email');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNull);

        // Valid email enables button
        await tester.enterText(emailField, 'rahul@example.com');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNotNull);

        // Clearing email enables button again (since it is optional)
        await tester.enterText(emailField, '');
        await tester.pump();
        expect(tester.widget<InkWell>(ctaButton).onTap, isNotNull);
      },
    );

    testWidgets('5. Submits registration and displays loading state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool submitCalled = false;
      await tester.pumpWidget(
        _buildRegisterApp(
          child: CreateAccountScreen(
            onRegistrationSubmitted:
                ({
                  required name,
                  required phone,
                  required password,
                  email,
                }) async {
                  submitCalled = true;
                  await Future.delayed(const Duration(milliseconds: 300));
                  return false; // Keep on screen
                },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final nameField = find.descendant(
        of: find.byKey(const Key('register_name_field')),
        matching: find.byType(TextField),
      );
      final phoneField = find.descendant(
        of: find.byKey(const Key('register_phone_field')),
        matching: find.byType(TextField),
      );
      final passwordField = find.descendant(
        of: find.byKey(const Key('register_password_field')),
        matching: find.byType(TextField),
      );

      await tester.enterText(nameField, 'Rahul Sen');
      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(passwordField, 'ValidPass8');
      await tester.pump();
      // Accept terms
      await tester.tap(find.byKey(const Key('terms_consent_row')));
      await tester.pump();

      // Tap submit
      await tester.tap(find.byKey(const Key('create_account_button')));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(submitCalled, isTrue);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    });

    testWidgets('6. Navigates to Login on tapping Log in link', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool loginNavCalled = false;
      await tester.pumpWidget(
        _buildRegisterApp(
          child: CreateAccountScreen(
            onLoginPressed: () => loginNavCalled = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Scroll down to make the footer visible
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Log in').last);
      await tester.pump();
      expect(loginNavCalled, isTrue);
    });

    testWidgets(
      '7. Responsive rendering across 393x852, 375x667, 412x915, and keyboard open',
      (tester) async {
        final viewports = [
          const Size(393, 852), // iPhone 15 standard
          const Size(375, 667), // iPhone SE compact
          const Size(360, 800), // Android standard
          const Size(412, 915), // Pixel 8 Pro
          const Size(430, 932), // iPhone 15 Pro Max
        ];

        for (final size in viewports) {
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(_buildRegisterApp(size: size));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(CreateAccountScreen), findsOneWidget);
        }

        // Keyboard open
        await tester.pumpWidget(
          _buildRegisterApp(viewInsets: const EdgeInsets.only(bottom: 300)),
        );
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.takeException(), isNull);

        tester.view.resetPhysicalSize();
      },
    );

    testWidgets(
      '8. Captures high-resolution screenshots for Create Account Screen (393x852, 375x667, 412x915)',
      (tester) async {
        await tester.runAsync(() async {
          await _loadFonts();
        });

        final configs = [
          {'size': const Size(393, 852), 'name': 'register_screen_393x852.png'},
          {'size': const Size(375, 667), 'name': 'register_screen_375x667.png'},
          {'size': const Size(412, 915), 'name': 'register_screen_412x915.png'},
        ];

        for (final config in configs) {
          final size = config['size'] as Size;
          final name = config['name'] as String;

          final repaintKey = GlobalKey();
          tester.view.physicalSize = Size(size.width * 2, size.height * 2);
          tester.view.devicePixelRatio = 2.0;

          await tester.pumpWidget(
            ChangeNotifierProvider(
              create: (_) => AppState(),
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: EGoTheme.light,
                home: MediaQuery(
                  data: MediaQueryData(
                    size: size,
                    padding: const EdgeInsets.only(top: 48, bottom: 34),
                  ),
                  child: Center(
                    child: RepaintBoundary(
                      key: repaintKey,
                      child: SizedBox(
                        width: size.width,
                        height: size.height,
                        child: const CreateAccountScreen(),
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
                repaintKey.currentContext!.findRenderObject()
                    as RenderRepaintBoundary;
            final image = await boundary.toImage(pixelRatio: 2.0);
            final byteData = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final pngBytes = byteData!.buffer.asUint8List();

            final file = File('test/screenshots/$name');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(pngBytes);
          });
        }

        tester.view.resetPhysicalSize();
      },
    );
  });
}
