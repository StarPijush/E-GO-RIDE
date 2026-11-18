import 'package:flutter/material.dart';
import '../theme/onboarding_constants.dart';
import 'onboarding_header.dart';
import 'onboarding_primary_button.dart';
import 'onboarding_progress.dart';

/// Shared canonical layout system for all three E-GO onboarding screens.
///
/// Guarantees identical layout geometry across all screens:
/// - Exact same hero top position, center coordinates, and dimensions (272 × 272 px)
/// - Exact same hero-to-heading spacing (32 px canonical / 16 px compact)
/// - Exact same heading top position and reserved 2-line area (72 px)
/// - Exact same description top position and reserved 3-line area (72 px)
/// - Exact same progress indicator position
/// - Exact same CTA dimensions (58 px), position, and centered text-only styling
class OnboardingScreenLayout extends StatelessWidget {
  const OnboardingScreenLayout({
    super.key,
    required this.hero,
    required this.heading,
    required this.description,
    required this.currentStep,
    required this.ctaLabel,
    required this.onCtaPressed,
    this.showWordmark = false,
    this.onSkip,
  });

  final Widget hero;
  final String heading;
  final String description;
  final int currentStep;
  final String ctaLabel;
  final VoidCallback onCtaPressed;
  final bool showWordmark;
  final VoidCallback? onSkip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OnboardingConstants.background,
      body: SafeArea(
        top: true,
        bottom: true,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxHeight < 680;
            final heroSpacing = isCompact
                ? 16.0
                : OnboardingConstants.heroBottomSpacing;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Header (height 48, identical on all screens) ──────────
                Padding(
                  padding: const EdgeInsets.only(
                    top: OnboardingConstants.headerTopPadding,
                  ),
                  child: OnboardingHeader(
                    showWordmark: showWordmark,
                    onSkip: onSkip,
                  ),
                ),

                // ── Hero + Typography (centered in flex space) ────────────
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OnboardingConstants.horizontalPadding,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Unified Hero (272 × 272 px)
                            hero,

                            SizedBox(height: heroSpacing),

                            // Unified Typography Block (Exact 156 px height on all screens)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Heading with reserved 2-line height (72 px)
                                  SizedBox(
                                    height:
                                        OnboardingConstants.headingAreaHeight,
                                    child: Text(
                                      heading,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily: OnboardingConstants
                                            .displayFontFamily,
                                        fontSize:
                                            OnboardingConstants.headingFontSize,
                                        height:
                                            OnboardingConstants
                                                .headingLineHeight /
                                            OnboardingConstants.headingFontSize,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: OnboardingConstants
                                            .headingLetterSpacing,
                                        color: OnboardingConstants.primary,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 12),

                                  // Standardized Description Region (Reserved 3-line height: 72 px)
                                  // Prevents text length differences from moving hero, heading, or footer.
                                  Container(
                                    width:
                                        OnboardingConstants.supportingMaxWidth,
                                    height: OnboardingConstants
                                        .supportingAreaHeight,
                                    alignment: Alignment.topCenter,
                                    child: Text(
                                      description,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontFamily:
                                            OnboardingConstants.fontFamily,
                                        fontSize: OnboardingConstants
                                            .supportingFontSize,
                                        height:
                                            OnboardingConstants
                                                .supportingLineHeight /
                                            OnboardingConstants
                                                .supportingFontSize,
                                        fontWeight: FontWeight.w400,
                                        letterSpacing: OnboardingConstants
                                            .supportingLetterSpacing,
                                        color:
                                            OnboardingConstants.secondaryText,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Bottom Tray (identical on all screens) ─────────────────
                Padding(
                  padding: const EdgeInsets.only(
                    left: OnboardingConstants.horizontalPadding,
                    right: OnboardingConstants.horizontalPadding,
                    bottom: OnboardingConstants.trayBottomPadding,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      OnboardingProgress(
                        currentStep: currentStep,
                        totalSteps: 3,
                      ),

                      SizedBox(
                        height: isCompact
                            ? 20.0
                            : OnboardingConstants.progressCtaSpacing,
                      ),

                      OnboardingPrimaryButton(
                        onPressed: onCtaPressed,
                        label: ctaLabel,
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
