import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/account/presentation/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestWidget({AppState? state}) {
    SharedPreferences.setMockInitialValues({});
    final appState = state ?? AppState();
    return ChangeNotifierProvider<AppState>.value(
      value: appState,
      child: MaterialApp(
        theme: EGoTheme.light,
        onGenerateRoute: EGoRouter.generateRoute,
        home: const ProfileScreen(),
      ),
    );
  }

  group('ProfileScreen Widget Tests', () {
    testWidgets('renders all expected sections and labels', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      // Top app bar
      expect(find.text('Account'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);

      // Hero profile card (fallback reference values)
      expect(find.text('Pijush Mahato'), findsOneWidget);
      expect(find.text('+91 98765 43210'), findsOneWidget);
      expect(find.text('P'), findsOneWidget);
      expect(find.byIcon(Icons.edit), findsOneWidget);

      // Section titles
      expect(find.text('ACTIVITY'), findsOneWidget);
      expect(find.text('My rides'), findsOneWidget);
      expect(find.text('Saved places'), findsOneWidget);

      expect(find.text('PAYMENTS'), findsOneWidget);
      expect(find.text('Payment methods'), findsOneWidget);

      expect(find.text('PREFERENCES'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('App settings'), findsOneWidget);

      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('Help & support'), findsOneWidget);
      expect(find.text('About E-GO'), findsOneWidget);

      // Scroll to logout button
      await tester.scrollUntilVisible(
        find.text('Log out'),
        500,
        scrollable: find.byType(Scrollable),
      );
      expect(find.text('Log out'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('displays active profile data when available in AppState',
        (tester) async {
      final state = AppState();
      await tester.pumpWidget(buildTestWidget(state: state));
      await tester.pumpAndSettle();

      // Log in demo user and update profile
      await tester.runAsync(() async {
        await state.loginWithPassword(
          phone: '9000000001',
          password: 'EgoDemo@123',
        );
        await state.updateProfile(
          name: 'Ananya Roy',
          email: 'ananya@example.com',
        );
      });
      await tester.pumpAndSettle();

      expect(find.text('Ananya Roy'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('logout button opens confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Log out'),
        500,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel dismisses dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsNothing);
    });

    testWidgets('renders properly across various viewports without errors',
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

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      }
    });
  });
}
