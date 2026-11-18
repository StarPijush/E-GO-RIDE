import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/onboarding_constants.dart';

/// Pixel-perfect vector reproduction of the E-GO electric motorcycle graphic
/// from the HTML/CSS reference with 3.8s floating motion animation.
class BikeIllustration extends StatefulWidget {
  const BikeIllustration({
    super.key,
    this.size = OnboardingConstants.bikeIllustrationSize,
    this.enableAnimations = true,
  });

  final double size;
  final bool enableAnimations;

  @override
  State<BikeIllustration> createState() => _BikeIllustrationState();
}

class _BikeIllustrationState extends State<BikeIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _translateAnimation;
  late final Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    // 3.8s full cycle: 0% -> 50% (-4px, 0.5deg) -> 100% (0px, 0deg)
    // Modeled as a 1900ms reversing animation with easeInOut curve
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    if (widget.enableAnimations) {
      _floatController.repeat(reverse: true);
    }

    _translateAnimation = Tween<double>(begin: 0.0, end: -4.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // 0.5 degrees in radians = 0.5 * pi / 180 = ~0.00872665 rad
    _rotateAnimation = Tween<double>(begin: 0.0, end: 0.5 * (math.pi / 180.0))
        .animate(
          CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
        );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _translateAnimation.value),
          child: Transform.rotate(angle: _rotateAnimation.value, child: child),
        );
      },
      child: CustomPaint(
        size: Size(widget.size, widget.size),
        painter: const _BikePainter(),
      ),
    );
  }
}

/// CustomPainter rendering the exact SVG motorcycle artwork from viewBox="0 0 200 200".
class _BikePainter extends CustomPainter {
  const _BikePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 200.0;
    canvas.save();
    canvas.scale(scale, scale);

    final darkPaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.fill;

    // 1. Rear Wheel (Center: 56, 132)
    final rearTirePaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;
    canvas.drawCircle(const Offset(56, 132), 30.0, rearTirePaint);
    canvas.drawCircle(const Offset(56, 132), 14.0, darkPaint);
    final rearAxlePaint = Paint()
      ..color = OnboardingConstants.yellowTop
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(56, 132), 6.0, rearAxlePaint);

    // 2. Front Wheel (Center: 148, 132)
    final frontTirePaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0;
    canvas.drawCircle(const Offset(148, 132), 30.0, frontTirePaint);
    canvas.drawCircle(const Offset(148, 132), 14.0, darkPaint);
    final frontAxlePaint = Paint()
      ..color = OnboardingConstants.yellowTop
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(148, 132), 6.0, frontAxlePaint);

    // 3. Front Fork & Steering Column Suspension
    final forkPaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 8.0;
    canvas.drawLine(const Offset(148, 132), const Offset(124, 68), forkPaint);

    final handlebarPaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 7.0;
    final handlebarPath = Path()
      ..moveTo(124, 68)
      ..lineTo(114, 62)
      ..lineTo(102, 62);
    canvas.drawPath(handlebarPath, handlebarPaint);

    // 4. Aerodynamic Monocoque Body Frame & Powertrain Shell
    // Path: M56 132L78 106L108 94L124 80L130 92L116 112L84 132H56Z
    final framePath = Path()
      ..moveTo(56, 132)
      ..lineTo(78, 106)
      ..lineTo(108, 94)
      ..lineTo(124, 80)
      ..lineTo(130, 92)
      ..lineTo(116, 112)
      ..lineTo(84, 132)
      ..close();
    canvas.drawPath(framePath, darkPaint);

    // 5. Battery Cell Core Pack
    // rect x="76" y="104" width="34" height="28" rx="6"
    final batteryRRect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(76, 104, 34, 28),
      const Radius.circular(6),
    );
    canvas.drawRRect(batteryRRect, darkPaint);

    // 6. Sculpted Low-Profile Saddle Seat
    // Path: M60 88C60 84 66 82 76 82C90 82 106 88 114 92L108 102L74 96C65 94 60 92 60 88Z
    final seatPath = Path()
      ..moveTo(60, 88)
      ..cubicTo(60, 84, 66, 82, 76, 82)
      ..cubicTo(90, 82, 106, 88, 114, 92)
      ..lineTo(108, 102)
      ..lineTo(74, 96)
      ..cubicTo(65, 94, 60, 92, 60, 88)
      ..close();
    canvas.drawPath(seatPath, darkPaint);

    // 7. Signature E-GO Electric Accent Band (Warm Yellow Energy Core)
    // Path: M84 100L112 94, stroke-width: 3
    final energyBandPaint = Paint()
      ..color = OnboardingConstants.yellowCta
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;
    canvas.drawLine(
      const Offset(84, 100),
      const Offset(112, 94),
      energyBandPaint,
    );

    // 8. Rear Swingarm & Drive Chain
    // Path: M56 132L88 126, stroke-width: 7
    final swingarmPaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 7.0;
    canvas.drawLine(
      const Offset(56, 132),
      const Offset(88, 126),
      swingarmPaint,
    );

    // 9. Compact Aerodynamic Mirrors & Instrument Cockpit
    canvas.drawCircle(const Offset(120, 58), 3.0, darkPaint);
    final mirrorStalkPaint = Paint()
      ..color = OnboardingConstants.darkGraphite
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.0;
    canvas.drawLine(
      const Offset(120, 58),
      const Offset(124, 64),
      mirrorStalkPaint,
    );

    // 10. Sleek Front Headlamp Bezel Accent
    // Path: M136 78L144 86, stroke-width: 3.5
    final headlampPaint = Paint()
      ..color = OnboardingConstants.yellowCta
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    canvas.drawLine(
      const Offset(136, 78),
      const Offset(144, 86),
      headlampPaint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
