import 'package:flutter/material.dart';

/// Pickup marker pin matching the master reference design.
/// Features a dark navy callout chip with 'PICKUP · 3m' above a navy/yellow beacon pin.
class ReviewPickupMarker extends StatelessWidget {
  const ReviewPickupMarker({
    super.key,
    this.label = 'PICKUP · 3m',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Floating label callout chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: const Color(0xFF142B45),
            borderRadius: BorderRadius.circular(5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 3),
        // Pin base dot
        SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Contact shadow
              Positioned(
                bottom: 1,
                child: Container(
                  width: 14,
                  height: 6,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1E31).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
              ),
              // Navy circle with white stroke
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFF142B45),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Center(
                  // Center yellow dot
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFC928),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Destination marker pin matching the master reference design.
/// Features a crisp white callout chip above a yellow/navy teardrop location pin.
class ReviewDestinationMarker extends StatelessWidget {
  const ReviewDestinationMarker({
    super.key,
    this.label = 'JHARGRAM PALACE',
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Floating label callout chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFCBD5E1), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: Color(0xFF142B45),
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        // Teardrop pin
        SizedBox(
          width: 24,
          height: 28,
          child: CustomPaint(painter: _DestinationPinPainter()),
        ),
      ],
    );
  }
}

class _DestinationPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Contact shadow
    final shadowPaint = Paint()
      ..color = const Color(0xFF0D1E31).withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - 2),
        width: 14,
        height: 5,
      ),
      shadowPaint,
    );

    // Teardrop pin body
    final pinPath = Path();
    final cx = size.width / 2;
    const top = 2.0;
    const r = 9.0;
    const tipY = 24.0;

    pinPath.moveTo(cx, tipY);
    pinPath.cubicTo(cx - 3, tipY - 5, cx - r, top + r + 3, cx - r, top + r);
    pinPath.arcToPoint(
      Offset(cx + r, top + r),
      radius: const Radius.circular(r),
      clockwise: true,
    );
    pinPath.cubicTo(cx + r, top + r + 3, cx + 3, tipY - 5, cx, tipY);
    pinPath.close();

    final fillPaint = Paint()
      ..color = const Color(0xFFFFC928)
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final centerDotPaint = Paint()
      ..color = const Color(0xFF142B45)
      ..style = PaintingStyle.fill;

    canvas.drawPath(pinPath, fillPaint);
    canvas.drawPath(pinPath, strokePaint);
    canvas.drawCircle(Offset(cx, top + r), 3.5, centerDotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
