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
import 'package:e_go/features/auth/presentation/login_screen.dart';

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

Widget _buildTestApp({
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
        child: child ?? const LoginScreen(),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('E-GO Phone Number Login Screen with Password Tests', () {
    testWidgets(
      '1. Verifies all mandatory visual and brand elements are present',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_buildTestApp());
        await tester.pump(const Duration(milliseconds: 200));

        // Brand Wordmark + Dot
        expect(find.text('E-GO'), findsOneWidget);
        expect(find.text('Help'), findsOneWidget);

        // Heading & Subtitle
        expect(find.text('Enter your\nphone number'), findsOneWidget);
        expect(
          find.text("We'll send a 6-digit verification code via SMS."),
          findsOneWidget,
        );

        // Phone Input Section
        expect(find.text('PHONE NUMBER'), findsOneWidget);
        expect(find.text('🇮🇳'), findsOneWidget);
        expect(find.text('+91'), findsOneWidget);
        expect(find.text('98765 43210'), findsOneWidget);

        // Password Input Section
        expect(find.text('PASSWORD'), findsOneWidget);
        expect(find.text('Enter your password'), findsOneWidget);
        expect(find.byKey(const Key('login_password_field')), findsOneWidget);

        // Security Note
        expect(
          find.text('Your number is kept secure & encrypted'),
          findsOneWidget,
        );

        // CTA Button
        expect(find.text('Continue'), findsOneWidget);

        // Secondary Navigation
        expect(find.textContaining('New to E-GO?'), findsOneWidget);
        expect(find.textContaining('Create account'), findsOneWidget);

        // Legal Footnote
        expect(
          find.text(
            'By continuing, you agree to the Terms of Service and Privacy Policy of E-GO.',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      '2. Verifies button enables only upon entering valid phone AND non-empty password',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(_buildTestApp());
        await tester.pump(const Duration(milliseconds: 200));

        final continueButton = find.byKey(const Key('continue_button'));
        expect(continueButton, findsOneWidget);
        expect(tester.widget<InkWell>(continueButton).onTap, isNull);

        final phoneField = find.widgetWithText(TextField, '98765 43210');
        final passwordField = find.widgetWithText(
          TextField,
          'Enter your password',
        );

        // 1. Enter valid phone only -> Still disabled (needs password)
        await tester.enterText(phoneField, '9876543210');
        await tester.pump();
        expect(tester.widget<InkWell>(continueButton).onTap, isNull);

        // 2. Enter a short password -> Enabled; login accepts any non-empty value
        await tester.enterText(passwordField, 'short');
        await tester.pump();
        expect(tester.widget<InkWell>(continueButton).onTap, isNotNull);

        // 3. Clearing the password disables it again
        await tester.enterText(passwordField, '');
        await tester.pump();
        expect(tester.widget<InkWell>(continueButton).onTap, isNull);

        // 4. Enter valid password (8+ chars) -> ENABLED
        await tester.enterText(passwordField, 'ValidPass8');
        await tester.pump();
        expect(tester.widget<InkWell>(continueButton).onTap, isNotNull);

        // Green checkmark on valid phone
        expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      },
    );

    testWidgets('3. Password visibility toggle works without clearing text', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 200));

      final passwordField = find.widgetWithText(
        TextField,
        'Enter your password',
      );
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.enterText(passwordField, 'SuperSecret123');
      await tester.pump();

      final toggleButton = find.byKey(const Key('password_visibility_toggle'));
      expect(toggleButton, findsOneWidget);

      // Toggle to visible
      await tester.tap(toggleButton);
      await tester.pump();
      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
      expect(
        tester.widget<TextField>(passwordField).controller!.text,
        equals('SuperSecret123'),
      );

      // Toggle back to hidden
      await tester.tap(toggleButton);
      await tester.pump();
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);
    });

    testWidgets(
      '4. Validates Indian phone prefix and displays error for invalid format',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        String? submittedPhone;
        await tester.pumpWidget(
          _buildTestApp(
            child: PhoneLoginScreen(
              onLoginSubmitted: (phone, password) async {
                submittedPhone = phone;
                return true;
              },
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        final phoneField = find.widgetWithText(TextField, '98765 43210');
        final passwordField = find.widgetWithText(
          TextField,
          'Enter your password',
        );

        // Starts with 3 (invalid Indian mobile number)
        await tester.enterText(phoneField, '3123456789');
        await tester.enterText(passwordField, 'ValidPass8');
        await tester.pump();

        final continueButton = find.byKey(const Key('continue_button'));
        expect(tester.widget<InkWell>(continueButton).onTap, isNull);
        expect(submittedPhone, isNull);
      },
    );

    testWidgets('5. Clear icon clears entered phone number', (tester) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_buildTestApp());
      await tester.pump(const Duration(milliseconds: 200));

      final phoneField = find.widgetWithText(TextField, '98765 43210');
      await tester.enterText(phoneField, '98765');
      await tester.pump();

      final clearIcon = find.byIcon(Icons.cancel_rounded);
      expect(clearIcon, findsOneWidget);

      await tester.tap(clearIcon);
      await tester.pump();

      expect(tester.widget<TextField>(phoneField).controller!.text, isEmpty);
    });

    testWidgets('6. Submits credentials and displays loading state', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool submitCalled = false;
      await tester.pumpWidget(
        _buildTestApp(
          child: PhoneLoginScreen(
            onLoginSubmitted: (phone, password) async {
              submitCalled = true;
              await Future.delayed(const Duration(milliseconds: 300));
              return false; // Stay on screen
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      final phoneField = find.widgetWithText(TextField, '98765 43210');
      final passwordField = find.widgetWithText(
        TextField,
        'Enter your password',
      );

      await tester.enterText(phoneField, '9876543210');
      await tester.enterText(passwordField, 'ValidPass8');
      await tester.pump();

      // Tap Continue
      await tester.tap(find.text('Continue'));
      await tester.pump();

      // Spinner should be visible while submitting
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(submitCalled, isTrue);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
    });

    testWidgets('7. Handles help action and create account navigation', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(393 * 2, 852 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool helpClicked = false;
      bool createAccountClicked = false;

      await tester.pumpWidget(
        _buildTestApp(
          child: PhoneLoginScreen(
            onHelpPressed: () => helpClicked = true,
            onCreateAccountPressed: () => createAccountClicked = true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Help
      await tester.tap(find.text('Help'));
      await tester.pump();
      expect(helpClicked, isTrue);

      // Tap Create account
      await tester.tap(find.textContaining('Create account'));
      await tester.pump();
      expect(createAccountClicked, isTrue);
    });

    testWidgets(
      '8. Responsive layout across multiple viewports without overflow',
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

          await tester.pumpWidget(_buildTestApp(size: size));
          await tester.pump(const Duration(milliseconds: 100));

          expect(tester.takeException(), isNull);
          expect(find.byType(PhoneLoginScreen), findsOneWidget);
        }
        tester.view.resetPhysicalSize();
      },
    );

    testWidgets(
      '9. Handles soft keyboard open (viewInsets 300px) smoothly without overflow',
      (tester) async {
        tester.view.physicalSize = const Size(393 * 2, 852 * 2);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          _buildTestApp(viewInsets: const EdgeInsets.only(bottom: 300)),
        );
        await tester.pump(const Duration(milliseconds: 200));

        expect(tester.takeException(), isNull);
        expect(find.byType(PhoneLoginScreen), findsOneWidget);
      },
    );

    testWidgets(
      '10. Captures high-resolution screenshots for Login (393x852, 375x667, 412x915)',
      (tester) async {
        await tester.runAsync(() async {
          await _loadFonts();
        });

        final configs = [
          {'size': const Size(393, 852), 'name': 'login_screen_393x852.png'},
          {'size': const Size(375, 667), 'name': 'login_screen_375x667.png'},
          {'size': const Size(412, 915), 'name': 'login_screen_412x915.png'},
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
                        child: const LoginScreen(),
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
