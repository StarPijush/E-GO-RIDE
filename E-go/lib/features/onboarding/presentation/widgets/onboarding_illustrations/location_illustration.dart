import 'package:flutter/material.dart';
import '../../theme/onboarding_constants.dart';

/// Pixel-perfect vector reproduction of the E-GO Screen 1 urban route geometry
/// and monolithic signature pin emblem from the HTML/CSS reference.
class LocationIllustration extends StatelessWidget {
  const LocationIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: OnboardingConstants.locationIllustrationSize,
      height: OnboardingConstants.locationIllustrationSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // SVG Route Vector Lines and Waypoint Accents
          CustomPaint(
            size: const Size(
              OnboardingConstants.locationIllustrationSize,
              OnboardingConstants.locationIllustrationSize,
            ),
            painter: const _UrbanRoutePainter(),
          ),

          // Monolithic Signature Pin Emblem
          const _SignaturePinEmblem(),
        ],
      ),
    );
  }
}

/// CustomPainter rendering the exact SVG route lines and waypoints from the reference HTML.
class _UrbanRoutePainter extends CustomPainter {
  const _UrbanRoutePainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Dynamic dashed path (40, 160) -> (184, 64)
    final dynamicPath = Path()
      ..moveTo(40, 160)
      ..cubicTo(70, 170, 75, 120, 112, 112)
      ..cubicTo(145, 105, 160, 70, 184, 64);

    final dynamicPaint = Paint()
      ..color = OnboardingConstants.primary.withValues(alpha: 0.16)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, dynamicPath, dynamicPaint, 4.0, 4.0);

    // 2. Secondary subtle dashed path (52, 80) -> (120, 75)
    final secondaryPath = Path()
      ..moveTo(52, 80)
      ..cubicTo(80, 75, 100, 95, 120, 75);

    final secondaryPaint = Paint()
      ..color = OnboardingConstants.primary.withValues(alpha: 0.12)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedPath(canvas, secondaryPath, secondaryPaint, 3.0, 3.0);

    // 3. Waypoint Accents
    final waypointPaint = Paint()
      ..color = OnboardingConstants.primary.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;

    // Outer waypoints
    canvas.drawCircle(const Offset(40, 160), 3.5, waypointPaint);
    canvas.drawCircle(const Offset(184, 64), 3.5, waypointPaint);

    // Center waypoint accent
    final centerWaypointPaint = Paint()
      ..color = OnboardingConstants.yellowAccent
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(112, 112), 2.5, centerWaypointPaint);
  }

  void _drawDashedPath(
    Canvas canvas,
    Path path,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final length = (distance + dashWidth < metric.length)
            ? dashWidth
            : metric.length - distance;
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The monolithic signature pin emblem matching the reference HTML:
/// - 76 × 76px circular black head
/// - 20 × 20px white center waypoint core
/// - Bottom anchor teardrop curve pointing downward
/// - Multi-layer shadow
class _SignaturePinEmblem extends StatelessWidget {
  const _SignaturePinEmblem();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 94,
      child: Stack(
        alignment: Alignment.topCenter,
        clipBehavior: Clip.none,
        children: [
          // Bottom anchor teardrop point (16x16 rotated 45 deg, radius 2)
          Positioned(
            top: 60,
            child: Transform.rotate(
              angle: 0.785398, // 45 degrees in radians
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: OnboardingConstants.primaryContainer,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: const [
                    BoxShadow(
                      color: OnboardingConstants.shadow,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main 76x76 circular black head
          Container(
            width: 76,
            height: 76,
            decoration: const BoxDecoration(
              color: OnboardingConstants.primaryContainer,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: OnboardingConstants.shadow,
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: OnboardingConstants.shadow,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              // Central Waypoint Core (20x20 white circle)
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: OnboardingConstants.surface,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
