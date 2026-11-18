import 'package:flutter/material.dart';
import '../../core/branding/ego_brand_colors.dart';

/// E-GO semantic color roles.
abstract class EGoColors {
  // Official brand tokens
  static const Color brandPrimary = EgoBrandColors.yellow;
  static const Color brandPrimaryDark = EgoBrandColors.yellowDark;
  static const Color brandPrimaryLight = EgoBrandColors.yellowLight;
  static const Color brandBackground = EgoBrandColors.background;
  static const Color brandYellow = EgoBrandColors.yellow;
  static const Color brandYellowLight = EgoBrandColors.yellowLight;
  static const Color brandYellowMuted = EgoBrandColors.yellowMuted;
  static const Color brandYellowDark = EgoBrandColors.yellowDark;
  static const Color brandPrimarySoft = EgoBrandColors.yellowSoft;
  static const Color brandPrimaryBorder = EgoBrandColors.yellowBorder;
  static const Color brandPrimaryHalo = EgoBrandColors.yellowHalo;
  static const Color brandNavy = EgoBrandColors.navy;
  static const Color brandBlack = EgoBrandColors.navy;
  static const Color brandCharcoal = EgoBrandColors.charcoal;

  // Secondary brand accent
  static const Color brandSecondary = EgoBrandColors.navy;
  static const Color brandSecondaryDark = EgoBrandColors.navy;

  // Neutrals
  static const Color white = EgoBrandColors.white;
  static const Color grey50 = EgoBrandColors.background;
  static const Color grey100 = EgoBrandColors.surfaceVariant;
  static const Color grey200 = EgoBrandColors.navyDivider;
  static const Color grey300 = EgoBrandColors.navyBorder;
  static const Color grey400 = EgoBrandColors.navyDisabledText;
  static const Color grey500 = EgoBrandColors.navyMutedText;
  static const Color grey600 = EgoBrandColors.navySecondaryText;
  static const Color grey700 = EgoBrandColors.navyStrongText;
  static const Color grey800 = EgoBrandColors.navy;
  static const Color grey900 = EgoBrandColors.navy;
  static const Color black = EgoBrandColors.navy;

  // Semantic status
  static const Color success = EgoBrandColors.success;
  static const Color successLight = EgoBrandColors.successLight;
  static const Color warning = EgoBrandColors.warning;
  static const Color warningLight = EgoBrandColors.warningLight;
  static const Color error = EgoBrandColors.error;
  static const Color errorLight = EgoBrandColors.errorLight;
  static const Color info = EgoBrandColors.info;
  static const Color infoLight = EgoBrandColors.infoLight;
  static const Color disabledBackground = EgoBrandColors.surfaceStrong;
  static const Color disabledForeground = EgoBrandColors.navyDisabledText;

  // Surfaces
  static const Color surface = EgoBrandColors.surface;
  static const Color surfaceVariant = EgoBrandColors.surfaceVariant;
  static const Color surfaceContainer = EgoBrandColors.navyTint;
  static const Color surfaceContainerLow = EgoBrandColors.background;
  static const Color surfaceElevated = EgoBrandColors.surface;
  static const Color onSurface = EgoBrandColors.textPrimary;
  static const Color onSurfaceVariant = EgoBrandColors.textSecondary;
  static const Color onSurfaceMuted = EgoBrandColors.textMuted;
  static const Color outline = EgoBrandColors.navyBorder;
  static const Color outlineVariant = EgoBrandColors.navyDivider;
  static const Color divider = EgoBrandColors.divider;
  static const Color shadow = EgoBrandColors.shadow;

  // Common aliases
  static const Color transparent = Color(0x00000000);

  // Compatibility aliases
  static const Color surfaceGreen = EgoBrandColors.background;
  static const Color surfaceBright = EgoBrandColors.yellowMuted;
  static const Color primaryDark = EgoBrandColors.navy;
  static const Color primaryContainer = EgoBrandColors.yellow;
  static const Color onPrimary = EgoBrandColors.navy;
  static const Color onPrimaryContainer = EgoBrandColors.navy;
  static const Color onSurfaceText = EgoBrandColors.navy;
  static const Color onSurfaceVariantText = EgoBrandColors.textSecondary;
  static const Color outlineGreen = EgoBrandColors.yellowDark;
  static const Color outlineVariantGreen = EgoBrandColors.navyDivider;

  // Map-specific
  static const Color mapMarkerPrimary = brandYellow;
  static const Color mapMarkerSecondary = brandNavy;
  static const Color mapControlBackground = white;
  static const Color mapControlShadow = EgoBrandColors.shadow;
}
