import 'package:flutter/material.dart';
import 'package:e_go/app/theme/index.dart';

/// Design tokens and layout constants for the E-GO onboarding experience.
///
/// ALL three onboarding screens share these exact values to form one
/// consistent visual system. Per-screen overrides are forbidden — only
/// illustration content, text and the active progress step change.
abstract class OnboardingConstants {
  // ── Screen Geometry ────────────────────────────────────────────────────────
  static const double canonicalWidth = 393.0;
  static const double canonicalHeight = 852.0;
  static const double horizontalPadding = 24.0;
  static const double headerTopPadding = 16.0;

  // ── Hero Dimensions ────────────────────────────────────────────────────────
  /// Outer hero container: identical on every onboarding screen.
  static const double heroAreaSize = 272.0;

  /// Inner filled circle (disk): identical on every onboarding screen.
  static const double heroDiskSize = 236.0;

  /// Energy / ambient ring diameter (= heroDiskSize − 2 × ringInset).
  static const double heroRingInset = 10.0;
  static const double heroRingSize = heroDiskSize - heroRingInset * 2; // 216.0

  /// Ring border thickness: identical on every screen.
  static const double heroRingBorderWidth = 1.0;

  /// Vertical gap between hero container bottom and heading text top.
  static const double heroBottomSpacing = 32.0;

  // ── Illustration fit sizes (each illustration scales to fit the shared disk) ─
  /// Location illustration fills the disk at 1:1 (236 logical px).
  static const double locationIllustrationSize = 236.0;

  /// Bike illustration (200×200 viewBox) rendered at this logical size.
  static const double bikeIllustrationSize = 196.0;

  /// TOTO illustration (320×220 viewBox, ~1.45:1 ratio) rendered to fit disk.
  static const double totoIllustrationWidth = 184.0;
  static const double totoIllustrationHeight = 142.0;

  // ── Typography ─────────────────────────────────────────────────────────────
  static const String fontFamily = EGoTypography.fontFamilyBody;
  static const String displayFontFamily = EGoTypography.fontFamilyDisplay;
  static const double headingFontSize = 28.0;
  static const double headingLineHeight = 36.0;
  static const double headingLetterSpacing = -0.02 * 28.0; // −0.56 px
  static const double headingAreaHeight = 72.0; // 2 lines × 36px line height

  static const double supportingFontSize = 16.0;
  static const double supportingLineHeight = 24.0;
  static const double supportingLetterSpacing = 0.0;
  static const double supportingMaxWidth = 280.0;
  static const double supportingAreaHeight = 72.0; // 3 lines × 24px line height

  // ── CTA Button ─────────────────────────────────────────────────────────────
  static const double ctaHeight = 58.0;
  static const double ctaBorderRadius = 16.0;
  static const double ctaFontSize = 18.0;

  // ── Bottom Tray Spacing ────────────────────────────────────────────────────
  /// Gap between progress indicator and CTA button.
  static const double progressCtaSpacing = 28.0;

  /// Bottom padding inside the tray (above SafeArea boundary).
  static const double trayBottomPadding = 20.0;

  // ── Colors ─────────────────────────────────────────────────────────────────
  static const Color background = EGoColors.brandBackground;
  static const Color surface = EGoColors.surface;
  static const Color primary = EGoColors.brandNavy;
  static const Color primaryContainer = EGoColors.brandNavy;
  static const Color secondary = EGoColors.brandPrimaryDark;
  static const Color yellowCta = EGoColors.brandPrimary;
  static const Color yellowAccent = EGoColors.brandPrimary;
  static const Color yellowTop = EGoColors.brandPrimaryLight;
  static const Color yellowBottom = EGoColors.brandYellowMuted;
  static const Color yellowHalo = EGoColors.brandPrimaryHalo;
  static const Color mainText = EGoColors.onSurface;
  static const Color secondaryText = EGoColors.onSurfaceVariant;
  static const Color surfaceVariant = EGoColors.surfaceContainer;
  static const Color surfaceContainer = EGoColors.surfaceContainerLow;
  static const Color surfaceContainerHigh = EGoColors.outlineVariant;
  static const Color border = EGoColors.brandPrimaryLight;
  static const Color secondaryFixed = EGoColors.brandPrimary;
  static const Color secondaryFixedDim = EGoColors.brandPrimaryDark;
  static const Color shadow = EGoColors.shadow;

  // Hero disk / ring colors (shared across screens)
  static const Color diskBackground = EGoColors.brandPrimarySoft;
  static const Color ringBorder = EGoColors.brandPrimaryBorder;

  // Legacy aliases kept so existing test files compile without changes
  static const Color bikeDiskBackground = diskBackground;
  static const Color bikeEnergyRingBorder = ringBorder;
  static const Color totoEnergyRingBorder = ringBorder;

  // Maps to official navy (#142B45) for bike/illustration frame rendering
  static const Color darkGraphite = EGoColors.onSurface;
}
