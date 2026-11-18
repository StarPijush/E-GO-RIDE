import 'package:flutter/material.dart';
import '../theme/onboarding_constants.dart';

/// Reusable multi-step progress indicator for onboarding screens.
/// Features animated width transition between active (32×8) and inactive (8×8) capsules.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    this.onStepTap,
  });

  /// Zero-based active step index (0, 1, or 2).
  final int currentStep;
  final int totalSteps;
  final ValueChanged<int>? onStepTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Onboarding progress, step ${currentStep + 1} of $totalSteps',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(totalSteps, (index) {
          final isActive = index == currentStep;
          final widget = AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isActive ? 32 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: isActive
                  ? OnboardingConstants.yellowCta
                  : OnboardingConstants.surfaceVariant,
              borderRadius: BorderRadius.circular(4),
              boxShadow: isActive
                  ? const [
                      BoxShadow(
                        color: OnboardingConstants.shadow,
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
          );

          if (onStepTap != null) {
            return Padding(
              padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
              child: GestureDetector(
                onTap: () => onStepTap!(index),
                child: widget,
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            child: widget,
          );
        }),
      ),
    );
  }
}
