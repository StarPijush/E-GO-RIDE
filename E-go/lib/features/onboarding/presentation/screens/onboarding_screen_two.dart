import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import '../widgets/onboarding_hero.dart';
import '../widgets/onboarding_screen_layout.dart';
import '../widgets/onboarding_illustrations/bike_illustration.dart';

/// E-GO Onboarding — Screen 02: "Fast bike rides, anytime".
///
/// Uses [OnboardingScreenLayout] to guarantee 100% pixel-aligned geometry
/// with Screens 1 and 3.
class OnboardingScreenTwo extends StatelessWidget {
  const OnboardingScreenTwo({
    super.key,
    this.onNext,
    this.onSkip,
    this.enableAnimations = true,
  });

  /// Override for navigation (defaults to [EGoRouter.onboardingThree]).
  final VoidCallback? onNext;

  /// Override for skip (defaults to completing onboarding → login).
  final VoidCallback? onSkip;

  /// Set [false] to disable animations (deterministic tests).
  final bool enableAnimations;

  void _handleNext(BuildContext context) {
    if (onNext != null) {
      onNext!();
      return;
    }
    Navigator.pushNamed(context, EGoRouter.onboardingThree);
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
      hero: OnboardingHero.bike(
        illustration: BikeIllustration(enableAnimations: enableAnimations),
        enableAnimations: enableAnimations,
      ),
      heading: 'Fast bike rides,\nanytime',
      description:
          'Need to get somewhere quickly? A bike rider is just a tap away.',
      currentStep: 1,
      ctaLabel: 'Next',
      onCtaPressed: () => _handleNext(context),
    );
  }
}
