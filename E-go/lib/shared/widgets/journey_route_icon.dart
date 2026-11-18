import 'package:flutter/material.dart';

/// Premium, minimal, outlined journey/route vector icon.
///
/// Communicates ride history and journeys with two subtle journey waypoints
/// connected by an elegant bezier curve, with consistent 2.0 stroke weight.
class JourneyRouteIcon extends StatelessWidget {
  const JourneyRouteIcon({
    super.key,
    required this.color,
    this.size = 26.0,
  });

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _JourneyRouteIconPainter(color: color),
      ),
    );
  }
}

class _JourneyRouteIconPainter extends CustomPainter {
  const _JourneyRouteIconPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..isAntiAlias = true;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final scale = size.width / 26.0;

    // Start Waypoint (Pickup dot at bottom-left: 6.5, 18.5)
    final startCenter = Offset(6.5 * scale, 18.5 * scale);
    final startRadius = 2.4 * scale;
    canvas.drawCircle(startCenter, startRadius, strokePaint);

    // Destination Waypoint (Dropoff node at top-right: 19.5, 7.5)
    final endCenter = Offset(19.5 * scale, 7.5 * scale);
    final endRadius = 2.4 * scale;
    canvas.drawCircle(endCenter, endRadius, strokePaint);

    // Route curve connecting waypoints
    final routePath = Path();
    // Start at top edge of start waypoint
    routePath.moveTo(6.5 * scale, (18.5 - 2.4) * scale);
    // Smooth S-curve to bottom edge of end waypoint
    routePath.cubicTo(
      6.5 * scale,
      10.8 * scale,
      19.5 * scale,
      15.2 * scale,
      19.5 * scale,
      (7.5 + 2.4) * scale,
    );
    canvas.drawPath(routePath, strokePaint);

    // Intermediate waypoint dot on the route for journey feel (13.0, 13.0)
    final midDotCenter = Offset(13.0 * scale, 13.0 * scale);
    canvas.drawCircle(midDotCenter, 1.35 * scale, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _JourneyRouteIconPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

