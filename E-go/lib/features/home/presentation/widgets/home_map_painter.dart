import 'dart:ui';
import 'package:flutter/material.dart';

/// CustomPainter that renders the reference map aesthetics for Jhargram.
///
/// Features:
/// - Background terrain: #E8EDE2
/// - Forest & Green reserves: #D3E4C6 and #D7E8CB
/// - Minor local streets: #FFFFFF
/// - Major highway / state arterial: #FEE588 with #F7BA1E dashed centerline
/// - Railway indicator: #CBD5E1 with #64748B dashes
class HomeMapStylingPainter extends CustomPainter {
  const HomeMapStylingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 400.0;
    final sy = size.height / 320.0;

    // 1. Background terrain
    final bgPaint = Paint()..color = const Color(0xFFE8EDE2);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // 2. Green Forest Reserves 1 (Chilkigarh belt)
    final greenPaint1 = Paint()
      ..color = const Color(0xFFD3E4C6).withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    final p1 = Path()
      ..moveTo(-20 * sx, 0 * sy)
      ..cubicTo(30 * sx, 20 * sy, 80 * sx, -10 * sy, 130 * sx, 15 * sy)
      ..cubicTo(180 * sx, 40 * sy, 210 * sx, 10 * sy, 240 * sx, 5 * sy)
      ..cubicTo(270 * sx, 0 * sy, 310 * sx, 35 * sy, 420 * sx, 20 * sy)
      ..lineTo(420 * sx, 110 * sy)
      ..cubicTo(360 * sx, 120 * sy, 290 * sx, 85 * sy, 240 * sx, 95 * sy)
      ..cubicTo(190 * sx, 105 * sy, 150 * sx, 145 * sy, 80 * sx, 130 * sy)
      ..cubicTo(30 * sx, 120 * sy, 10 * sx, 140 * sy, -20 * sx, 130 * sy)
      ..close();
    canvas.drawPath(p1, greenPaint1);

    // 3. Green Forest Reserves 2 (Deer park belt)
    final greenPaint2 = Paint()
      ..color = const Color(0xFFD7E8CB).withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final p2 = Path()
      ..moveTo(260 * sx, 210 * sy)
      ..cubicTo(300 * sx, 200 * sy, 350 * sx, 220 * sy, 420 * sx, 205 * sy)
      ..lineTo(420 * sx, 340 * sy)
      ..lineTo(220 * sx, 340 * sy)
      ..cubicTo(210 * sx, 300 * sy, 230 * sx, 260 * sy, 260 * sx, 210 * sy)
      ..close();
    canvas.drawPath(p2, greenPaint2);

    // 4. Minor local streets (white)
    void drawStreet(Offset from, Offset to, double width) {
      final paint = Paint()
        ..color = const Color(0xFFFFFFFF)
        ..strokeWidth = width * ((sx + sy) / 2)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawLine(from, to, paint);
    }

    drawStreet(Offset(-40 * sx, 240 * sy), Offset(440 * sx, 180 * sy), 6.0);
    drawStreet(Offset(60 * sx, -20 * sy), Offset(140 * sx, 340 * sy), 5.0);
    drawStreet(Offset(280 * sx, -20 * sy), Offset(220 * sx, 340 * sy), 4.5);

    // Curved minor streets
    final curvedStreetPaint1 = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 5.0 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cs1 = Path()
      ..moveTo(120 * sx, 70 * sy)
      ..quadraticBezierTo(240 * sx, 120 * sy, 380 * sx, 90 * sy);
    canvas.drawPath(cs1, curvedStreetPaint1);

    final curvedStreetPaint2 = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..strokeWidth = 7.0 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final cs2 = Path()
      ..moveTo(-20 * sx, 160 * sy)
      ..quadraticBezierTo(150 * sx, 200 * sy, 420 * sx, 140 * sy);
    canvas.drawPath(cs2, curvedStreetPaint2);

    // 5. Major Highway / State Highway Arterial (Yellow)
    // Path: M-10 60 Q 120 110 210 180 T 430 270
    final hwPath = Path()
      ..moveTo(-10 * sx, 60 * sy)
      ..quadraticBezierTo(120 * sx, 110 * sy, 210 * sx, 180 * sy)
      ..quadraticBezierTo(
        (2 * 210 - 120) * sx,
        (2 * 180 - 110) * sy,
        430 * sx,
        270 * sy,
      );

    // Base highway stroke
    final hwBasePaint = Paint()
      ..color = const Color(0xFFFEE588)
      ..strokeWidth = 8.0 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(hwPath, hwBasePaint);

    // Centerline dashed stroke
    _drawDashedPath(
      canvas: canvas,
      path: hwPath,
      paint: Paint()
        ..color = const Color(0xFFF7BA1E)
        ..strokeWidth = 3.0 * ((sx + sy) / 2)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      dashLength: 8.0 * sx,
      dashSpace: 6.0 * sx,
    );

    // 6. Railway Line Indicator (Slate line with dashes)
    final railFrom = Offset(-10 * sx, 190 * sy);
    final railTo = Offset(410 * sx, 70 * sy);

    final railBasePaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 3.5 * ((sx + sy) / 2)
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(railFrom, railTo, railBasePaint);

    final railPath = Path()
      ..moveTo(railFrom.dx, railFrom.dy)
      ..lineTo(railTo.dx, railTo.dy);

    _drawDashedPath(
      canvas: canvas,
      path: railPath,
      paint: Paint()
        ..color = const Color(0xFF64748B)
        ..strokeWidth = 3.5 * ((sx + sy) / 2)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
      dashLength: 6.0 * sx,
      dashSpace: 6.0 * sx,
    );
  }

  void _drawDashedPath({
    required Canvas canvas,
    required Path path,
    required Paint paint,
    required double dashLength,
    required double dashSpace,
  }) {
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      var draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : dashSpace;
        if (draw) {
          final extract = metric.extractPath(
            distance,
            (distance + length).clamp(0.0, metric.length),
          );
          canvas.drawPath(extract, paint);
        }
        distance += length;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
