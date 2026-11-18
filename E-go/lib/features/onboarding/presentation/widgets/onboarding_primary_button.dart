import 'package:flutter/material.dart';
import '../theme/onboarding_constants.dart';
import 'package:e_go/app/theme/colors.dart';

/// Signature primary CTA button for all three E-GO onboarding screens.
///
/// Design spec:
/// - 58 px height, 16 px corner radius
/// - Official yellow background, navy label, soft navy shadow
/// - Text-only (no icon) — centered Inter bold
/// - Uniform across all screens; only [label] changes
class OnboardingPrimaryButton extends StatefulWidget {
  const OnboardingPrimaryButton({
    super.key,
    required this.onPressed,
    required this.label,
  });

  final VoidCallback onPressed;
  final String label;

  @override
  State<OnboardingPrimaryButton> createState() =>
      _OnboardingPrimaryButtonState();
}

class _OnboardingPrimaryButtonState extends State<OnboardingPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: _isPressed ? 0.985 : 1.0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: double.infinity,
        height: OnboardingConstants.ctaHeight,
        decoration: BoxDecoration(
          color: OnboardingConstants.yellowCta,
          borderRadius: BorderRadius.circular(
            OnboardingConstants.ctaBorderRadius,
          ),
          boxShadow: const [
            BoxShadow(
              color: OnboardingConstants.shadow,
              blurRadius: 16,
              offset: Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            borderRadius: BorderRadius.circular(
              OnboardingConstants.ctaBorderRadius,
            ),
            splashColor: EGoColors.brandNavy.withValues(alpha: 0.08),
            highlightColor: EGoColors.brandNavy.withValues(alpha: 0.04),
            child: Center(
              child: Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: OnboardingConstants.fontFamily,
                  fontSize: OnboardingConstants.ctaFontSize,
                  height: 28 / OnboardingConstants.ctaFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.01 * OnboardingConstants.ctaFontSize,
                  color: OnboardingConstants.primary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
