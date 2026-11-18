import 'package:flutter/material.dart';
import 'colors.dart';
import 'typography.dart';
import 'spacing.dart';

/// E-GO application theme.
abstract class EGoTheme {
  static ThemeData get light {
    final buttonTextStyle = EGoTypography.labelLarge.copyWith(
      fontWeight: FontWeight.w700,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: EGoColors.brandPrimary,
        onPrimary: EGoColors.onPrimary,
        primaryContainer: EGoColors.brandPrimaryLight,
        onPrimaryContainer: EGoColors.onPrimaryContainer,
        secondary: EGoColors.brandSecondary,
        onSecondary: EGoColors.white,
        secondaryContainer: EGoColors.surfaceContainer,
        onSecondaryContainer: EGoColors.onPrimaryContainer,
        tertiary: EGoColors.info,
        onTertiary: EGoColors.white,
        tertiaryContainer: EGoColors.infoLight,
        onTertiaryContainer: EGoColors.info,
        surface: EGoColors.surface,
        onSurface: EGoColors.onSurface,
        surfaceContainerHighest: EGoColors.surfaceVariant,
        onSurfaceVariant: EGoColors.onSurfaceVariant,
        outline: EGoColors.outline,
        outlineVariant: EGoColors.outlineVariant,
        error: EGoColors.error,
        onError: EGoColors.white,
        errorContainer: EGoColors.errorLight,
        onErrorContainer: EGoColors.error,
        shadow: EGoColors.shadow,
        inverseSurface: EGoColors.brandNavy,
        onInverseSurface: EGoColors.white,
        inversePrimary: EGoColors.brandPrimaryLight,
      ),
      scaffoldBackgroundColor: EGoColors.brandBackground,
      textTheme: const TextTheme(
        displayLarge: EGoTypography.displayLarge,
        displayMedium: EGoTypography.displayMedium,
        displaySmall: EGoTypography.displaySmall,
        headlineLarge: EGoTypography.headlineLarge,
        headlineMedium: EGoTypography.headlineMedium,
        headlineSmall: EGoTypography.headlineSmall,
        titleLarge: EGoTypography.titleLarge,
        titleMedium: EGoTypography.titleMedium,
        titleSmall: EGoTypography.titleSmall,
        bodyLarge: EGoTypography.bodyLarge,
        bodyMedium: EGoTypography.bodyMedium,
        bodySmall: EGoTypography.bodySmall,
        labelLarge: EGoTypography.labelLarge,
        labelMedium: EGoTypography.labelMedium,
        labelSmall: EGoTypography.labelSmall,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: EGoColors.white,
        foregroundColor: EGoColors.onSurface,
        elevation: EGoSpacing.elevation0,
        scrolledUnderElevation: EGoSpacing.elevation1,
        surfaceTintColor: EGoColors.white,
        centerTitle: false,
        titleTextStyle: EGoTypography.headlineSmall,
        iconTheme: IconThemeData(
          color: EGoColors.onSurface,
          size: EGoSpacing.iconMedium,
        ),
        actionsIconTheme: IconThemeData(
          color: EGoColors.onSurface,
          size: EGoSpacing.iconMedium,
        ),
      ),
      cardTheme: CardThemeData(
        color: EGoColors.surface,
        surfaceTintColor: EGoColors.surface,
        elevation: EGoSpacing.elevation1,
        shadowColor: EGoColors.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(EGoSpacing.radiusCard),
          ),
          side: BorderSide(color: EGoColors.outlineVariant),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: EGoColors.brandPrimary,
          foregroundColor: EGoColors.onPrimary,
          disabledBackgroundColor: EGoColors.disabledBackground,
          disabledForegroundColor: EGoColors.disabledForeground,
          elevation: EGoSpacing.elevation1,
          shadowColor: EGoColors.shadow,
          minimumSize: const Size(double.infinity, EGoSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: EGoSpacing.xl,
            vertical: EGoSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(EGoSpacing.radiusButton),
            ),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: EGoColors.brandPrimary,
          foregroundColor: EGoColors.onPrimary,
          disabledBackgroundColor: EGoColors.disabledBackground,
          disabledForegroundColor: EGoColors.disabledForeground,
          minimumSize: const Size(double.infinity, EGoSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: EGoSpacing.xl,
            vertical: EGoSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(EGoSpacing.radiusButton),
            ),
          ),
          textStyle: buttonTextStyle,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: EGoColors.onSurface,
          disabledForegroundColor: EGoColors.disabledForeground,
          side: const BorderSide(color: EGoColors.brandNavy, width: 1.5),
          minimumSize: const Size(double.infinity, EGoSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: EGoSpacing.xl,
            vertical: EGoSpacing.md,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(EGoSpacing.radiusButton),
            ),
          ),
          textStyle: buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: EGoColors.onSurface,
          disabledForegroundColor: EGoColors.disabledForeground,
          minimumSize: const Size(64, EGoSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(
            horizontal: EGoSpacing.lg,
            vertical: EGoSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(
              Radius.circular(EGoSpacing.radiusButton),
            ),
          ),
          textStyle: buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: EGoColors.brandPrimary,
        foregroundColor: EGoColors.onPrimary,
        elevation: EGoSpacing.elevation3,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: EGoColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: EGoSpacing.lg,
          vertical: EGoSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EGoSpacing.radiusInput),
          borderSide: const BorderSide(color: EGoColors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EGoSpacing.radiusInput),
          borderSide: const BorderSide(color: EGoColors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EGoSpacing.radiusInput),
          borderSide: const BorderSide(
            color: EGoColors.brandNavy,
            width: EGoSpacing.focusBorderWidth,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EGoSpacing.radiusInput),
          borderSide: const BorderSide(color: EGoColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EGoSpacing.radiusInput),
          borderSide: const BorderSide(
            color: EGoColors.error,
            width: EGoSpacing.focusBorderWidth,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(EGoSpacing.radiusInput),
          borderSide: const BorderSide(color: EGoColors.outlineVariant),
        ),
        labelStyle: EGoTypography.bodyMedium.copyWith(
          color: EGoColors.onSurfaceVariant,
        ),
        hintStyle: EGoTypography.bodyMedium.copyWith(
          color: EGoColors.onSurfaceMuted,
        ),
        floatingLabelStyle: EGoTypography.bodySmall.copyWith(
          color: EGoColors.brandNavy,
        ),
        errorStyle: EGoTypography.bodySmall.copyWith(color: EGoColors.error),
        helperStyle: EGoTypography.bodySmall,
        prefixIconColor: EGoColors.onSurfaceMuted,
        suffixIconColor: EGoColors.onSurfaceMuted,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: EGoColors.surface,
        surfaceTintColor: EGoColors.surface,
        elevation: EGoSpacing.elevation4,
        shadowColor: EGoColors.shadow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(EGoSpacing.radiusCard),
          ),
        ),
        titleTextStyle: EGoTypography.headlineSmall,
        contentTextStyle: EGoTypography.bodyMedium.copyWith(
          color: EGoColors.onSurfaceVariant,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: EGoColors.surface,
        surfaceTintColor: EGoColors.surface,
        modalBackgroundColor: EGoColors.surface,
        elevation: EGoSpacing.elevation0,
        modalElevation: EGoSpacing.elevation0,
        shadowColor: EGoColors.shadow,
        dragHandleColor: EGoColors.outline,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(EGoSpacing.radiusSheet),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: EGoColors.brandNavy,
        contentTextStyle: EGoTypography.bodyMedium.copyWith(
          color: EGoColors.white,
        ),
        actionTextColor: EGoColors.brandPrimary,
        elevation: EGoSpacing.elevation4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(EGoSpacing.radiusCard),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: EGoColors.surface,
        surfaceTintColor: EGoColors.surface,
        indicatorColor: EGoColors.brandPrimary,
        elevation: EGoSpacing.elevation0,
        indicatorShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(EGoSpacing.radiusPill),
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return EGoTypography.navigationLabel.copyWith(
              color: EGoColors.onPrimary,
              fontWeight: FontWeight.w700,
            );
          }
          return EGoTypography.navigationLabel;
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(WidgetState.selected)
                ? EGoColors.onPrimary
                : EGoColors.onSurfaceMuted,
            size: EGoSpacing.iconMedium,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: EGoColors.surfaceVariant,
        selectedColor: EGoColors.brandPrimary,
        disabledColor: EGoColors.disabledBackground,
        labelStyle: EGoTypography.labelMedium.copyWith(
          color: EGoColors.onSurfaceVariant,
        ),
        secondaryLabelStyle: EGoTypography.labelMedium.copyWith(
          color: EGoColors.onPrimary,
        ),
        checkmarkColor: EGoColors.onPrimary,
        side: const BorderSide(color: EGoColors.outlineVariant),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: EGoSpacing.md,
          vertical: EGoSpacing.sm,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: EGoColors.divider,
        thickness: EGoSpacing.borderWidth,
        space: EGoSpacing.borderWidth,
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: EGoColors.onSurface,
        textColor: EGoColors.onSurface,
        subtitleTextStyle: EGoTypography.bodyMedium,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: EGoColors.brandPrimary,
        linearTrackColor: EGoColors.outlineVariant,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: EGoColors.brandNavy,
          borderRadius: BorderRadius.circular(EGoSpacing.radiusMedium),
        ),
        textStyle: EGoTypography.bodySmall.copyWith(color: EGoColors.white),
      ),
    );
  }
}
