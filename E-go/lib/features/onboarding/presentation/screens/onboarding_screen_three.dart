import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import '../widgets/onboarding_hero.dart';
import '../widgets/onboarding_screen_layout.dart';
import '../widgets/onboarding_illustrations/toto_illustration.dart';

/// E-GO Onboarding — Screen 03: "Ride across Jhargram".
///
/// Uses [OnboardingScreenLayout] to guarantee 100% pixel-aligned geometry
/// with Screens 1 and 2. Tapping "Next" marks onboarding complete and navigates
/// to [EGoRouter.login].
class OnboardingScreenThree extends StatelessWidget {
  const OnboardingScreenThree({
    super.key,
    this.onNext,
    this.onSkip,
    this.enableAnimations = true,
  });

  /// Override for the final CTA (defaults to completing onboarding → login).
  final VoidCallback? onNext;

  /// Override for skip (defaults to completing onboarding → login).
  final VoidCallback? onSkip;

  /// Set [false] to disable ambient animations (deterministic tests).
  final bool enableAnimations;

  Future<void> _handleNext(BuildContext context) async {
    if (onNext != null) {
      onNext!();
      return;
    }
    await context.read<AppState>().markOnboardingComplete();
    if (context.mounted) {
      Navigator.pushReplacementNamed(context, EGoRouter.login);
    }
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
      showWordmark: false,
      onSkip: () => _handleSkip(context),
      hero: const OnboardingHero.toto(illustration: TotoIllustration()),
      heading: 'Ride across\nJhargram',
      description:
          'Book affordable Toto (E-Rickshaw) and Bike rides anywhere in Jhargram city.',
      currentStep: 2,
      ctaLabel: 'Next',
      onCtaPressed: () => _handleNext(context),
    );
  }
}
