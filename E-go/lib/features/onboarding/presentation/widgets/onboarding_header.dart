import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_go/app/app_state.dart';
import 'package:e_go/app/router.dart';
import '../theme/onboarding_constants.dart';

/// Minimalist header bar for the E-GO onboarding experience.
/// Displays the E-GO wordmark with yellow accent dot and a touch-friendly Skip button.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({super.key, this.onSkip, this.showWordmark = true});

  final VoidCallback? onSkip;
  final bool showWordmark;

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
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OnboardingConstants.horizontalPadding,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // E-GO wordmark + yellow accent dot (or empty space when disabled)
            if (showWordmark)
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'E-GO',
                    style: TextStyle(
                      fontFamily: OnboardingConstants.displayFontFamily,
                      fontSize: 24,
                      height: 32 / 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.015 * 24,
                      color: OnboardingConstants.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: OnboardingConstants.yellowCta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink(),

            // Skip action button (min 44x44 touch target)
            Semantics(
              button: true,
              label: 'Skip onboarding flow',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _handleSkip(context),
                  borderRadius: BorderRadius.circular(22),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 44,
                      minHeight: 44,
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: OnboardingConstants.fontFamily,
                          fontSize: 14,
                          height: 16 / 14,
                          fontWeight: FontWeight.w600,
                          color: OnboardingConstants.secondaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
