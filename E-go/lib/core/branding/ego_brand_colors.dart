import 'package:flutter/material.dart';

/// Official E-GO brand palette and its derived neutral tones.
abstract class EgoBrandColors {
  // Official colors
  static const Color yellow = Color(0xFFFFC928);
  static const Color background = Color(0xFFF5F7FA);
  static const Color navy = Color(0xFF142B45);
  static const Color white = Color(0xFFFFFFFF);

  // Logo ink
  static const Color logoInk = Color(0xFF000000);

  // Derived brand tones
  static const Color yellowLight = Color(0xFFFFF7DF);
  static const Color yellowMuted = Color(0xFFFFFBEE);
  static const Color yellowDark = Color(0xFFE8B92B);
  static const Color yellowSoft = Color(0x2EFFC928);
  static const Color yellowBorder = Color(0x80E8B92B);
  static const Color yellowHalo = Color(0x33FFC928);

  // Derived navy tones
  static const Color navyTint = Color(0xFFEAEDF1);
  static const Color navyBorder = Color(0x29142B45);
  static const Color navyDivider = Color(0x1F142B45);
  static const Color navySecondaryText = Color(0xA6142B45);
  static const Color navyStrongText = Color(0xBF142B45);
  static const Color navyMutedText = Color(0x80142B45);
  static const Color navyDisabledText = Color(0x66142B45);
  static const Color shadow = Color(0x1A142B45);

  // Neutral surfaces
  static const Color surface = white;
  static const Color surfaceVariant = Color(0xFFF3F4F6);
  static const Color surfaceStrong = Color(0xFFE3E8EE);
  static const Color cardBackground = white;

  // Typography
  static const Color textPrimary = navy;
  static const Color textSecondary = navySecondaryText;
  static const Color textMuted = navyMutedText;
  static const Color textOnYellow = navy;
  static const Color textOnBlack = white;

  // Borders and dividers
  static const Color border = navyBorder;
  static const Color borderLight = navyDivider;
  static const Color divider = navyDivider;

  // Compatibility aliases
  static const Color black = logoInk;
  static const Color charcoal = navy;

  // Semantic status
  static const Color success = Color(0xFF059669);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFD97706);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF0284C7);
  static const Color infoLight = Color(0xFFE0F2FE);
}
