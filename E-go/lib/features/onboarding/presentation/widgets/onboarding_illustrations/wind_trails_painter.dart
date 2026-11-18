import 'package:flutter/material.dart';
import '../../theme/onboarding_constants.dart';

/// CustomPainter rendering the dynamic dashed wind trails behind the bike
/// matching the SVG reference in `viewBox="0 0 280 280"`.
class WindTrailsPainter extends CustomPainter {
  const WindTrailsPainter({required this.animationProgress});

  /// Normalized animation progress from 0.0 to 1.0 (2.4s linear cycle).
  final double animationProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 280.0;
    canvas.save();
    canvas.scale(scale, scale);

    // Trail 1: (32, 126) -> (110, 126), width 2.5, opacity 0.18
    final paint1 = Paint()
      ..color = OnboardingConstants.darkGraphite.withValues(alpha: 0.18)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _drawWindLine(canvas, 32.0, 110.0, 126.0, paint1, animationProgress);

    // Trail 2: (48, 148) -> (96, 148), width 3.0, opacity 0.25
    final paint2 = Paint()
      ..color = OnboardingConstants.darkGraphite.withValues(alpha: 0.25)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _drawWindLine(canvas, 48.0, 96.0, 148.0, paint2, animationProgress);

    // Trail 3: (28, 170) -> (124, 170), width 2.0, opacity 0.15
    final paint3 = Paint()
      ..color = OnboardingConstants.darkGraphite.withValues(alpha: 0.15)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    _drawWindLine(canvas, 28.0, 124.0, 170.0, paint3, animationProgress);

    canvas.restore();
  }

  void _drawWindLine(
    Canvas canvas,
    double x1,
    double x2,
    double y,
    Paint paint,
    double progress,
  ) {
    final length = x2 - x1;
    const dashLength = 40.0;
    const gapLength = 80.0;
    const cycleLength = dashLength + gapLength; // 120.0

    // In CSS: 0% { stroke-dashoffset: 0; } 100% { stroke-dashoffset: -120; }
    // A negative offset moves the dash pattern along +x direction
    final offset = (progress * cycleLength) % cycleLength;

    var start = -offset;
    while (start < length) {
      final dashStart = start;
      final dashEnd = start + dashLength;

      final visibleStart = dashStart < 0.0 ? 0.0 : dashStart;
      final visibleEnd = dashEnd > length ? length : dashEnd;

      if (visibleEnd > visibleStart + 0.5) {
        canvas.drawLine(
          Offset(x1 + visibleStart, y),
          Offset(x1 + visibleEnd, y),
          paint,
        );
      }
      start += cycleLength;
    }
  }

  @override
  bool shouldRepaint(covariant WindTrailsPainter oldDelegate) =>
      oldDelegate.animationProgress != animationProgress;
}
