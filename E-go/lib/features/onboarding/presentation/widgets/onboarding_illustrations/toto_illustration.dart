import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/onboarding_constants.dart';

/// Pixel-perfect vector reproduction of the official E-GO Electric TOTO (E-Rickshaw)
/// silhouette graphic from the HTML/CSS reference (viewBox="0 0 320 220").
class TotoIllustration extends StatelessWidget {
  const TotoIllustration({
    super.key,
    this.width = OnboardingConstants.totoIllustrationWidth,
    this.height = OnboardingConstants.totoIllustrationHeight,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const CustomPaint(painter: _TotoPainter()),
    );
  }
}

/// CustomPainter rendering the exact SVG TOTO artwork with negative-space cutouts and wheels.
class _TotoPainter extends CustomPainter {
  const _TotoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // Preserve 320 x 220 viewBox with uniform aspect-ratio contain scaling
    final scale = math.min(size.width / 320.0, size.height / 220.0);
    final dx = (size.width - 320.0 * scale) / 2.0;
    final dy = (size.height - 220.0 * scale) / 2.0;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale, scale);

    final darkPaint = Paint()
      ..color = OnboardingConstants.mainText
      ..style = PaintingStyle.fill;

    final yellowPaint = Paint()
      ..color = OnboardingConstants.secondaryFixed
      ..style = PaintingStyle.fill;

    // 1. Main Body Silhouette
    final bodyPath = Path()
      ..moveTo(120, 28)
      ..cubicTo(155, 27, 185, 30, 196, 46)
      ..cubicTo(202, 54, 207, 72, 214, 96)
      ..cubicTo(217, 106, 211, 114, 202, 114)
      ..lineTo(196, 114)
      ..cubicTo(198, 124, 195, 133, 186, 138)
      ..cubicTo(178, 141, 170, 137, 166, 128)
      ..lineTo(152, 128)
      ..cubicTo(150, 128, 148, 126, 148, 123)
      ..lineTo(148, 116)
      ..lineTo(124, 116)
      ..lineTo(124, 125)
      ..cubicTo(124, 128, 121, 130, 118, 130)
      ..lineTo(76, 130)
      ..cubicTo(74, 122, 70, 114, 62, 114)
      ..lineTo(50, 114)
      ..cubicTo(44, 114, 42, 108, 42, 98)
      ..cubicTo(42, 80, 43, 56, 64, 38)
      ..cubicTo(78, 28, 98, 28, 120, 28)
      ..close();
    canvas.drawPath(bodyPath, darkPaint);

    // 2. Rear Passenger Entry Cutout (Interior Yellow)
    final rearCutoutPath = Path()
      ..moveTo(88, 42)
      ..cubicTo(104, 40, 116, 41, 122, 43)
      ..cubicTo(128, 45, 130, 52, 130, 62)
      ..lineTo(130, 96)
      ..cubicTo(130, 102, 126, 106, 120, 106)
      ..lineTo(112, 106)
      ..lineTo(112, 76)
      ..cubicTo(112, 71, 108, 68, 103, 68)
      ..lineTo(88, 68)
      ..cubicTo(83, 68, 80, 71, 80, 76)
      ..lineTo(80, 104)
      ..cubicTo(80, 106, 78, 108, 76, 108)
      ..cubicTo(70, 108, 67, 104, 67, 96)
      ..lineTo(67, 58)
      ..cubicTo(67, 48, 74, 43, 88, 42)
      ..close();
    canvas.drawPath(rearCutoutPath, yellowPaint);

    // 3. Windshield Cutout
    final windshieldPath = Path()
      ..moveTo(174, 46)
      ..cubicTo(168, 38, 158, 35, 142, 35)
      ..lineTo(142, 80)
      ..cubicTo(154, 80, 166, 79, 171, 76)
      ..cubicTo(175, 73, 179, 58, 174, 46)
      ..close();
    canvas.drawPath(windshieldPath, yellowPaint);

    // 4. Rear Wheel & Rim Assembly (Center: 74, 140)
    canvas.drawCircle(const Offset(74, 140), 26.0, darkPaint);
    canvas.drawCircle(const Offset(74, 140), 15.0, yellowPaint);
    canvas.drawCircle(const Offset(74, 140), 7.0, darkPaint);

    // 5. Front Mudguard Assembly
    final frontMudguardPath = Path()
      ..moveTo(206, 124)
      ..cubicTo(220, 124, 228, 135, 227, 150)
      ..lineTo(214, 150)
      ..cubicTo(213, 142, 208, 138, 202, 138)
      ..cubicTo(195, 138, 190, 143, 190, 150)
      ..lineTo(178, 150)
      ..cubicTo(178, 135, 189, 124, 206, 124)
      ..close();
    canvas.drawPath(frontMudguardPath, darkPaint);

    // 6. Front Wheel Assembly (Center: 204, 150)
    canvas.drawCircle(const Offset(204, 150), 20.0, darkPaint);
    canvas.drawCircle(const Offset(204, 150), 10.0, yellowPaint);
    canvas.drawCircle(const Offset(204, 150), 4.5, darkPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
