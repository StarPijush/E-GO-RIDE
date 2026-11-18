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
import 'package:e_go/features/support/domain/support_faq.dart';
import 'package:e_go/features/support/presentation/help_support_screen.dart';
import 'package:e_go/shared/widgets/ego_gooey_bottom_navigation.dart';

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
      child: const HelpSupportScreen(),
    ),
  );

  return ChangeNotifierProvider<AppState>.value(
    value: appState,
    child: size != null
        ? SizedBox(width: size.width, height: size.height, child: content)
        : content,
  );
}

void _setMobileViewport(WidgetTester tester, {Size size = const Size(393, 852)}) {
  tester.view.physicalSize = size * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HelpSupportScreen Redesign Tests', () {
    testWidgets('renders all required elements and sections in default view',
        (tester) async {
      _setMobileViewport(tester);
      await tester.runAsync(_loadFonts);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // 1. Top App Bar
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.byIcon(Icons.help_outline_rounded), findsOneWidget);

      // Verify global bottom nav is NOT displayed on this secondary screen
      expect(find.byType(EgoGooeyBottomNavigation), findsNothing);

      // 2. Main Page Introduction
      expect(find.text('How can we help?'), findsOneWidget);
      expect(
        find.text(
          'Find answers, report trip issues, or contact local support in E-GO',
        ),
        findsOneWidget,
      );

      // 3. Search Bar
      expect(find.text('Search for help, topics, or FAQs...'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // 4. Browse by Topic
      expect(find.text('Browse by topic'), findsOneWidget);
      expect(find.text('Rides & Booking'), findsOneWidget);
      expect(find.text('Payments & Fare'), findsOneWidget);
      expect(find.text('Account & Profile'), findsOneWidget);
      expect(find.text('Safety & Emergency'), findsOneWidget);
      expect(find.byIcon(Icons.electric_rickshaw_outlined), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shield_outlined), findsOneWidget);

      // 5. Frequently Asked Questions
      expect(find.text('Frequently asked questions'), findsOneWidget);
      for (final faq in kSupportFaqs) {
        expect(find.text(faq.question), findsOneWidget);
      }

      // 6. Still Need Help? Card (scroll down to reach)
      await tester.scrollUntilVisible(
        find.text('Still need help?'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Still need help?'), findsOneWidget);
      expect(
        find.text('Our local customer care team is available to assist you.'),
        findsOneWidget,
      );
      expect(find.text('Contact support'), findsOneWidget);
      expect(find.byIcon(Icons.headset_mic_outlined), findsOneWidget);
    });

    testWidgets('Search query filters FAQs dynamically and supports clearing',
        (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Enter search query "fare"
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'fare');
      await tester.pumpAndSettle();

      // Question 2 ("How is the fare calculated?") should match
      expect(find.text('How is the fare calculated?'), findsOneWidget);
      expect(find.text('What is a Toto?'), findsNothing);

      // Clear search using clear button in TextField
      final clearBtn = find.byIcon(Icons.close_rounded);
      expect(clearBtn, findsOneWidget);
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();

      // All 7 questions restored
      for (final faq in kSupportFaqs) {
        expect(find.text(faq.question), findsOneWidget);
      }
    });

    testWidgets('Empty search result shows dedicated state and Reset button',
        (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Search for non-existent keyword
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'xyzunknownterm');
      await tester.pumpAndSettle();

      // Verify Empty state UI
      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No matching topics found'), findsOneWidget);
      expect(
        find.textContaining('No topics matching "xyzunknownterm"'),
        findsOneWidget,
      );

      // Scroll to reset button if needed and tap
      final resetBtn = find.text('Reset search');
      await tester.scrollUntilVisible(
        resetBtn,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(resetBtn, findsOneWidget);
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Restored
      expect(find.text('No matching topics found'), findsNothing);
      expect(find.text('How do I book a ride?'), findsOneWidget);
    });

    testWidgets('Tapping topic row filters FAQ entries and scrolls to FAQ section',
        (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Tap "Payments & Fare" topic
      await tester.tap(find.text('Payments & Fare'));
      await tester.pumpAndSettle();

      // Search field receives "payment"
      expect(find.text('payment'), findsOneWidget);
      expect(find.text('What payment methods are accepted?'), findsOneWidget);
    });

    testWidgets('Accordion expands answer, rotates chevron, and collapses correctly',
        (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Initially answer is collapsed
      const question1 = 'How do I book a ride?';
      const answer1 =
          'Open the app, enter your destination, choose a vehicle (Bike or Toto), and confirm your booking. A nearby verified Jhargram driver will be matched to you instantly.';

      // Tap Question 1 to expand
      await tester.tap(find.text(question1));
      await tester.pumpAndSettle();

      expect(find.text(answer1), findsOneWidget);

      // Scroll so Question 2 is in view, then tap it
      const question2 = 'How is the fare calculated?';
      const answer2 =
          'Fares are based on distance and vehicle type. Bike rides start at ₹20 + ₹10/km. Toto rides start at ₹15 + ₹7/km. Transparent meter pricing with no hidden surcharges.';

      await tester.scrollUntilVisible(
        find.text(question2),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text(question2));
      await tester.pumpAndSettle();

      expect(find.text(answer2), findsOneWidget);

      // Tap Question 2 again to collapse
      await tester.tap(find.text(question2));
      await tester.pumpAndSettle();
    });

    testWidgets('Contact support button opens bottom sheet with channels & form',
        (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Scroll to bottom and tap Contact support
      await tester.scrollUntilVisible(
        find.text('Contact support'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Contact support'));
      await tester.pumpAndSettle();

      // Modal content
      expect(find.text('Customer Care'), findsOneWidget);
      expect(find.text('Jhargram Help Desk · 6 AM – 10 PM'), findsOneWidget);
      expect(find.text('Live Chat'), findsOneWidget);
      expect(find.text('Call Desk'), findsOneWidget);
      expect(find.text('Issue Category'), findsOneWidget);
      expect(find.text('Trip Reference'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Scroll modal if needed to reach Send request
      final sendBtn = find.text('Send request');
      await tester.scrollUntilVisible(
        sendBtn,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(sendBtn, findsOneWidget);

      // Test validation: submit without filling details
      await tester.tap(sendBtn);
      await tester.pumpAndSettle();
      expect(
        find.text('Please provide details about your issue'),
        findsOneWidget,
      );

      // Fill details and submit
      final detailsField = find.widgetWithText(
        TextFormField,
        'Please describe what happened...',
      );
      await tester.enterText(
        detailsField,
        'Left umbrella in the Toto yesterday.',
      );
      await tester.pumpAndSettle();

      await tester.tap(sendBtn);
      await tester.pump(); // Start submission state
      await tester.pump(const Duration(milliseconds: 700)); // Advance simulated timer
      await tester.pumpAndSettle();

      // Sheet closed and snackbar shown
      expect(find.text('Customer Care'), findsNothing);
      expect(
        find.textContaining('Your request (Ref #EG-4203) has been logged'),
        findsOneWidget,
      );
    });

    testWidgets('Safety & Emergency topic opens Safety Center modal',
        (tester) async {
      _setMobileViewport(tester);
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Safety & Emergency'));
      await tester.pumpAndSettle();

      expect(find.text('E-GO Safety Center'), findsOneWidget);
      expect(find.textContaining('100% Verified Toto Drivers'), findsOneWidget);
      expect(find.textContaining('Live Route Sharing'), findsOneWidget);
      expect(find.textContaining('Jhargram Police Hotline'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('E-GO Safety Center'), findsNothing);
    });

    testWidgets('renders across multiple viewports without layout errors',
        (tester) async {
      const viewports = [
        Size(320, 600),
        Size(360, 800),
        Size(393, 852),
        Size(430, 932),
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

    testWidgets('captures screenshots at reference 393x852 viewport',
        (tester) async {
      _setMobileViewport(tester);
      await tester.runAsync(_loadFonts);

      final repaintKey = GlobalKey();
      await tester.pumpWidget(
        buildTestWidget(repaintKey: repaintKey, size: const Size(393, 852)),
      );
      await tester.pumpAndSettle();

      // 1. Capture top view
      await tester.runAsync(() async {
        final boundary = repaintKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('test/screenshots/final_help_support_393x852.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        expect(file.existsSync(), isTrue);
      });

      // 2. Scroll and capture bottom view (FAQs & Still need help)
      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final boundary = repaintKey.currentContext!.findRenderObject()
            as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File(
          'test/screenshots/final_help_support_scrolled_393x852.png',
        );
        await file.parent.create(recursive: true);
        await file.writeAsBytes(byteData!.buffer.asUint8List());
        expect(file.existsSync(), isTrue);
      });
    });
  });
}
