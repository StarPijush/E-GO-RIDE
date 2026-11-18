import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import '../widgets/onboarding_hero.dart';
import '../widgets/onboarding_screen_layout.dart';
import '../widgets/onboarding_illustrations/location_illustration.dart';

/// E-GO Onboarding — Screen 01: "Move your way, every day".
///
/// Uses [OnboardingScreenLayout] to guarantee 100% pixel-aligned geometry
/// with Screens 2 and 3.
class OnboardingScreenOne extends StatelessWidget {
  const OnboardingScreenOne({
    super.key,
    this.onNext,
    this.onSkip,
    this.enableAnimations = true,
  });

  /// Override for navigation (defaults to [EGoRouter.onboardingTwo]).
  final VoidCallback? onNext;

  /// Override for skip (defaults to completing onboarding → login).
  final VoidCallback? onSkip;

  /// Set [false] to disable ambient animations (deterministic tests).
  final bool enableAnimations;

  void _handleNext(BuildContext context) {
    if (onNext != null) {
      onNext!();
      return;
    }
    Navigator.pushNamed(context, EGoRouter.onboardingTwo);
  }

  Future<void> _handleSkip(BuildContext context) async {
    if (onSkip != null) {
      onSkip!();
      return;
    }
    await context.read<AppState>().markOnboardingComplete();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, EGoRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingScreenLayout(
      showWordmark: true,
      onSkip: () => _handleSkip(context),
      hero: OnboardingHero(
        illustration: const LocationIllustration(),
        badgeText: 'Urban Flow',
        enableAnimations: enableAnimations,
      ),
      heading: 'Move your way,\nevery day',
      description:
          "Set your pickup, choose a vehicle, and ride — it's that simple.",
      currentStep: 0,
      ctaLabel: 'Get started',
      onCtaPressed: () => _handleNext(context),
    );
  }
}
