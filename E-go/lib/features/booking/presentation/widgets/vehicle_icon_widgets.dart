import 'package:flutter/material.dart';

/// Crisp vector icon for E-Rickshaw matching the reference SVG (viewBox: 0 0 48 48).
class TotoIconWidget extends StatelessWidget {
  const TotoIconWidget({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _TotoIconPainter()),
    );
  }
}

class _TotoIconPainter extends CustomPainter {
  const _TotoIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.scale(scale, scale);

    final navyPaint = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.fill;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFFC928)
      ..style = PaintingStyle.fill;

    final whiteWindowPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final whiteWindow2Paint = Paint()
      ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    // Main body
    final bodyPath = Path()
      ..moveTo(12, 34)
      ..lineTo(36, 34)
      ..cubicTo(38, 34, 40, 32, 40, 30)
      ..lineTo(40, 22)
      ..cubicTo(40, 18, 36, 12, 30, 11)
      ..lineTo(14, 11)
      ..cubicTo(10, 11, 8, 15, 8, 20)
      ..lineTo(8, 30)
      ..cubicTo(8, 32, 10, 34, 12, 34)
      ..close();
    canvas.drawPath(bodyPath, navyPaint);

    // Yellow top / canopy visor
    final roofPath = Path()
      ..moveTo(12, 11)
      ..lineTo(32, 11)
      ..cubicTo(35, 11, 38, 13, 39, 16)
      ..lineTo(9, 16)
      ..cubicTo(10, 13, 11, 11, 12, 11)
      ..close();
    canvas.drawPath(roofPath, yellowPaint);

    // Front window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(12, 18, 12, 10),
        const Radius.circular(2),
      ),
      whiteWindowPaint,
    );

    // Passenger window cutout
    final sideWinPath = Path()
      ..moveTo(28, 18)
      ..lineTo(36, 18)
      ..cubicTo(37, 18, 38, 19, 38, 21)
      ..lineTo(38, 25)
      ..lineTo(28, 25)
      ..close();
    canvas.drawPath(sideWinPath, whiteWindow2Paint);

    // Interior yellow accent dot
    canvas.drawCircle(const Offset(18, 23), 3, yellowPaint);

    // Wheels
    final wheelBasePaint = Paint()
      ..color = const Color(0xFF0D1E31)
      ..style = PaintingStyle.fill;

    final wheelBorderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Front wheel
    canvas.drawCircle(const Offset(14, 34), 5, wheelBasePaint);
    canvas.drawCircle(const Offset(14, 34), 5, wheelBorderPaint);
    canvas.drawCircle(const Offset(14, 34), 2, yellowPaint);

    // Rear wheel
    canvas.drawCircle(const Offset(34, 34), 5, wheelBasePaint);
    canvas.drawCircle(const Offset(34, 34), 5, wheelBorderPaint);
    canvas.drawCircle(const Offset(34, 34), 2, yellowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Crisp vector icon for Bike matching the reference SVG (viewBox: 0 0 48 48).
class BikeIconWidget extends StatelessWidget {
  const BikeIconWidget({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _BikeIconPainter()),
    );
  }
}

class _BikeIconPainter extends CustomPainter {
  const _BikeIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 48.0;
    canvas.scale(scale, scale);

    final navyStroke3 = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final navyStroke22 = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final navyStroke15 = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final navyFill = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.fill;

    final whiteFill = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.fill;

    final yellowFill = Paint()
      ..color = const Color(0xFFFFC928)
      ..style = PaintingStyle.fill;

    // Front wheel
    canvas.drawCircle(const Offset(11, 30), 7, whiteFill);
    canvas.drawCircle(const Offset(11, 30), 7, navyStroke3);
    canvas.drawCircle(const Offset(11, 30), 2.5, navyFill);

    // Rear wheel
    canvas.drawCircle(const Offset(37, 30), 7, whiteFill);
    canvas.drawCircle(const Offset(37, 30), 7, navyStroke3);
    canvas.drawCircle(const Offset(37, 30), 2.5, navyFill);

    // Main frame
    final framePath = Path()
      ..moveTo(11, 30)
      ..lineTo(22, 22)
      ..lineTo(30, 22)
      ..lineTo(37, 30);
    canvas.drawPath(framePath, navyStroke3);

    // Center post
    final postPath = Path()
      ..moveTo(22, 22)
      ..lineTo(24, 16)
      ..lineTo(28, 16);
    canvas.drawPath(postPath, navyStroke22);

    // Yellow fuel tank
    final tankPath = Path()
      ..moveTo(20, 20)
      ..cubicTo(22, 17, 27, 17, 29, 20)
      ..close();
    canvas.drawPath(tankPath, yellowFill);
    canvas.drawPath(tankPath, navyStroke15);

    // Engine block line
    final enginePath = Path()
      ..moveTo(16, 21)
      ..lineTo(22, 21);
    canvas.drawPath(enginePath, navyStroke22);

    // Handlebar
    final handlePath = Path()
      ..moveTo(28, 14)
      ..lineTo(30, 16)
      ..lineTo(33, 16);
    canvas.drawPath(handlePath, navyStroke22);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
