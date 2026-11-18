import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:e_go/app/theme/index.dart';

void main() {
  group('Official palette', () {
    test('uses the approved brand colors', () {
      expect(EgoBrandColors.yellow, const Color(0xFFFFC928));
      expect(EgoBrandColors.background, const Color(0xFFF5F7FA));
      expect(EgoBrandColors.navy, const Color(0xFF142B45));
      expect(EgoBrandColors.white, const Color(0xFFFFFFFF));
    });

    test('exposes palette roles without duplicating brand values', () {
      expect(EGoColors.brandPrimary, EgoBrandColors.yellow);
      expect(EGoColors.brandBackground, EgoBrandColors.background);
      expect(EGoColors.brandNavy, EgoBrandColors.navy);
      expect(EGoColors.grey50, EgoBrandColors.background);
      expect(EGoColors.brandBlack, EgoBrandColors.navy);
      expect(EGoColors.brandSecondary, EgoBrandColors.navy);
    });

    test('preserves semantic status colors', () {
      expect(EGoColors.success, const Color(0xFF059669));
      expect(EGoColors.warning, const Color(0xFFD97706));
      expect(EGoColors.error, const Color(0xFFDC2626));
      expect(EGoColors.info, const Color(0xFF0284C7));
      expect(EGoColors.successLight, const Color(0xFFD1FAE5));
      expect(EGoColors.warningLight, const Color(0xFFFEF3C7));
      expect(EGoColors.errorLight, const Color(0xFFFEE2E2));
      expect(EGoColors.infoLight, const Color(0xFFE0F2FE));
    });
  });

  group('Typography', () {
    test('binds Poppins to display and headings and Inter to UI text', () {
      expect(EGoTypography.fontFamilyDisplay, 'Poppins');
      expect(EGoTypography.fontFamilyBody, 'Inter');
      expect(EGoTypography.fontFamilyNumbers, 'Inter');
      expect(EGoTypography.fontFamilyPrimary, 'Inter');

      expect(EGoTypography.displayLarge.fontFamily, 'Poppins');
      expect(EGoTypography.headlineLarge.fontFamily, 'Poppins');
      expect(EGoTypography.titleLarge.fontFamily, 'Poppins');
      expect(EGoTypography.brandTitle.fontFamily, 'Poppins');

      expect(EGoTypography.titleMedium.fontFamily, 'Inter');
      expect(EGoTypography.bodyLarge.fontFamily, 'Inter');
      expect(EGoTypography.labelLarge.fontFamily, 'Inter');
      expect(EGoTypography.navigationLabel.fontFamily, 'Inter');
    });
  });

  group('Theme bindings', () {
    final theme = EGoTheme.light;

    test('maps brand and semantic colors into the color scheme', () {
      expect(theme.colorScheme.primary, EgoBrandColors.yellow);
      expect(theme.colorScheme.onPrimary, EgoBrandColors.navy);
      expect(theme.colorScheme.secondary, EgoBrandColors.navy);
      expect(theme.colorScheme.surface, EgoBrandColors.white);
      expect(theme.colorScheme.onSurface, EgoBrandColors.navy);
      expect(theme.colorScheme.outline, EGoColors.outline);
      expect(theme.colorScheme.error, EgoBrandColors.error);
      expect(theme.scaffoldBackgroundColor, EGoColors.grey50);
    });

    test('binds the typography scale', () {
      expect(theme.textTheme.displayLarge?.fontFamily, 'Poppins');
      expect(theme.textTheme.titleLarge?.fontFamily, 'Poppins');
      expect(theme.textTheme.bodyMedium?.fontFamily, 'Inter');
      expect(theme.textTheme.labelLarge?.fontFamily, 'Inter');
      expect(theme.appBarTheme.titleTextStyle?.fontFamily, 'Poppins');
    });

    test('styles primary buttons with brand yellow and navy', () {
      final style = theme.filledButtonTheme.style!;
      expect(
        style.backgroundColor?.resolve(<WidgetState>{}),
        EgoBrandColors.yellow,
      );
      expect(
        style.foregroundColor?.resolve(<WidgetState>{}),
        EgoBrandColors.navy,
      );
      expect(
        style.backgroundColor?.resolve(<WidgetState>{WidgetState.disabled}),
        EGoColors.disabledBackground,
      );
      expect(style.textStyle?.resolve(<WidgetState>{})?.fontFamily, 'Inter');
    });

    test('styles inputs with a navy focus border and semantic error', () {
      final focused =
          theme.inputDecorationTheme.focusedBorder! as OutlineInputBorder;
      final error =
          theme.inputDecorationTheme.errorBorder! as OutlineInputBorder;

      expect(focused.borderSide.color, EgoBrandColors.navy);
      expect(error.borderSide.color, EgoBrandColors.error);
      expect(theme.inputDecorationTheme.fillColor, EgoBrandColors.white);
    });

    test('styles surfaces, navigation, and overlays', () {
      final cardShape = theme.cardTheme.shape! as RoundedRectangleBorder;
      final cardRadius = cardShape.borderRadius as BorderRadius;

      expect(theme.appBarTheme.backgroundColor, EgoBrandColors.white);
      expect(theme.cardTheme.color, EgoBrandColors.white);
      expect(cardRadius.topLeft.x, EGoSpacing.radiusCard);
      expect(theme.dialogTheme.backgroundColor, EgoBrandColors.white);
      expect(theme.bottomSheetTheme.backgroundColor, EgoBrandColors.white);
      expect(theme.snackBarTheme.backgroundColor, EgoBrandColors.navy);
      expect(theme.navigationBarTheme.indicatorColor, EgoBrandColors.yellow);
      expect(theme.chipTheme.selectedColor, EgoBrandColors.yellow);
    });

    test('defines shared shape tokens', () {
      expect(EGoSpacing.radiusInput, EGoSpacing.radiusXLarge);
      expect(EGoSpacing.radiusCard, EGoSpacing.radiusXLarge);
      expect(EGoSpacing.radiusSheet, EGoSpacing.xxl);
    });
  });
}
