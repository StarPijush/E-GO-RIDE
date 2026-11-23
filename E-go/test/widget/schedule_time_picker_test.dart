import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/features/location/presentation/location_selection_screen.dart';
import 'package:e_go/features/location/presentation/widgets/schedule_time_picker_dialog.dart';

void main() {
  group('ScheduleTimePickerDialog Tests', () {
    Widget buildTestPicker({
      TimeOfDay initialTime = const TimeOfDay(hour: 6, minute: 58),
      bool initialIsDigital = true,
      ValueChanged<TimeOfDay?>? onResult,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () async {
                    final res = await ScheduleTimePickerDialog.show(
                      context: context,
                      initialTime: initialTime,
                      initialIsDigital: initialIsDigital,
                    );
                    onResult?.call(res);
                  },
                  child: const Text('Open Picker'),
                ),
              );
            },
          ),
        ),
      );
    }

    // ── LOOP 1: Quick-adjust buttons are removed ──────────────────────────────

    testWidgets('Quick-adjust pills (-15m, -5m, +5m, +15m) are absent', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestPicker(initialIsDigital: true));
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('-15m'), findsNothing);
      expect(find.text('-5m'), findsNothing);
      expect(find.text('+5m'), findsNothing);
      expect(find.text('+15m'), findsNothing);
    });

    // ── LOOP 2: Digital layout – no overflow ───────────────────────────────────

    testWidgets('Digital mode has no RenderFlex overflow at 320px width', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestPicker(initialIsDigital: true));
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // All key elements visible and not clipped
      expect(find.text('HOUR'), findsOneWidget);
      expect(find.text('MINUTE'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Digital mode renders correctly at all responsive widths', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 360.0, 375.0, 393.0, 412.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 812));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestPicker(initialIsDigital: true));
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        expect(find.text('HOUR'), findsOneWidget, reason: 'at ${width}px');
        expect(find.text('MINUTE'), findsOneWidget, reason: 'at ${width}px');
        expect(find.text('AM'), findsOneWidget, reason: 'at ${width}px');
        expect(find.text('PM'), findsOneWidget, reason: 'at ${width}px');
        expect(tester.takeException(), isNull, reason: 'overflow at ${width}px');
      }
    });

    // ── Core digital-mode tests ───────────────────────────────────────────────

    testWidgets('Renders centered dialog with header and buttons in digital mode', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(buildTestPicker(initialIsDigital: true));
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Schedule pickup'), findsOneWidget);
      expect(find.text('Choose your preferred pickup time'), findsOneWidget);
      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('06'), findsOneWidget);
      expect(find.text('58'), findsOneWidget);
      expect(find.text('HOUR'), findsOneWidget);
      expect(find.text('MINUTE'), findsOneWidget);
      expect(find.text('AM'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
      expect(find.text('Switch to analog clock'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Confirm time'), findsOneWidget);
    });

    testWidgets('Toggles AM and PM and returns correct 24-hour time', (WidgetTester tester) async {
      TimeOfDay? returnedTime;
      await tester.pumpWidget(
        buildTestPicker(
          initialIsDigital: true,
          initialTime: const TimeOfDay(hour: 6, minute: 58),
          onResult: (val) => returnedTime = val,
        ),
      );
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('PM'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Confirm time'));
      await tester.pumpAndSettle();

      expect(returnedTime, isNotNull);
      expect(returnedTime!.hour, equals(18));
      expect(returnedTime!.minute, equals(58));
    });

    testWidgets('Switches between digital and analog modes with preserved state', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestPicker(
          initialIsDigital: true,
          initialTime: const TimeOfDay(hour: 7, minute: 40),
        ),
      );
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('07'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);

      // Digital → Analog
      await tester.tap(find.text('Switch to analog clock'));
      await tester.pumpAndSettle();

      // Hour and minute values preserved on the time summary row
      expect(find.text('07'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('Switch to digital input'), findsOneWidget);

      // Analog → Digital
      await tester.tap(find.text('Switch to digital input'));
      await tester.pumpAndSettle();

      expect(find.text('07'), findsOneWidget);
      expect(find.text('40'), findsOneWidget);
      expect(find.text('Switch to analog clock'), findsOneWidget);
    });

    // ── Analog-mode tests ─────────────────────────────────────────────────────

    testWidgets('Analog mode displays cardinal hour dial numbers', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      TimeOfDay? returnedTime;
      await tester.pumpWidget(
        buildTestPicker(
          initialIsDigital: false,
          initialTime: const TimeOfDay(hour: 6, minute: 30),
          onResult: (val) => returnedTime = val,
        ),
      );
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      // Cardinal hours visible
      expect(find.text('12'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      expect(find.text('9'), findsOneWidget);

      // Tap minute in TIME row to switch to minute mode
      final minuteFinder = find.text('30');
      expect(minuteFinder, findsOneWidget);
      await tester.tap(minuteFinder);
      await tester.pumpAndSettle();

      // Cardinal minute labels appear on dial
      expect(find.text('00'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);

      await tester.tap(find.text('Confirm time'));
      await tester.pumpAndSettle();

      expect(returnedTime, isNotNull);
      expect(returnedTime!.hour, equals(6));
      expect(returnedTime!.minute, equals(30));
    });

    testWidgets('Analog mode renders at all responsive widths without overflow', (
      WidgetTester tester,
    ) async {
      for (final width in [320.0, 360.0, 375.0, 393.0, 412.0, 430.0]) {
        await tester.binding.setSurfaceSize(Size(width, 812));
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(buildTestPicker(initialIsDigital: false));
        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        // Clock and controls present
        expect(find.text('TIME'), findsOneWidget, reason: 'at ${width}px');
        expect(find.text('AM'), findsOneWidget, reason: 'at ${width}px');
        expect(find.text('PM'), findsOneWidget, reason: 'at ${width}px');
        expect(tester.takeException(), isNull, reason: 'overflow at ${width}px');
      }
    });

    // ── Cancel / close ────────────────────────────────────────────────────────

    testWidgets('Cancel button and close icon dismiss without applying changes', (
      WidgetTester tester,
    ) async {
      TimeOfDay? returnedTime = const TimeOfDay(hour: 1, minute: 1);
      await tester.pumpWidget(
        buildTestPicker(
          initialIsDigital: true,
          onResult: (val) => returnedTime = val,
        ),
      );
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(returnedTime, isNull);
      expect(find.byType(Dialog), findsNothing);

      // Reopen and tap close icon
      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(returnedTime, isNull);
      expect(find.byType(Dialog), findsNothing);
    });

    // ── Integration: LocationSelectionScreen ──────────────────────────────────

    testWidgets('LocationSelectionScreen opens ScheduleTimePickerDialog on Change tap', (
      WidgetTester tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(393, 852));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final appState = AppState();
      await tester.pumpWidget(
        ChangeNotifierProvider<AppState>.value(
          value: appState,
          child: const MaterialApp(home: LocationSelectionScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Schedule for later'));
      await tester.pumpAndSettle();

      expect(find.text('Change'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text('Schedule pickup'), findsOneWidget);
      expect(find.text('Confirm time'), findsOneWidget);

      await tester.tap(find.text('Confirm time'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(find.textContaining('Pickup at'), findsOneWidget);
    });
  });
}
