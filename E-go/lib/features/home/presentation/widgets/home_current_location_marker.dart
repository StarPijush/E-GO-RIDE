import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';

/// Reference-accurate current-location interactive marker.
///
/// Contains:
/// 1. Floating navy tooltip pill: [• Current Location · Jhargram]
/// 2. Pulse pin marker:
///    - Outer soft-yellow pulse ring
///    - 20x20 white circular disk with 2px brand-yellow border
///    - 10x10 deep navy central core dot
class HomeCurrentLocationMarker extends StatefulWidget {
  const HomeCurrentLocationMarker({
    super.key,
    this.label = 'Current Location · Jhargram',
  });

  final String label;

  @override
  State<HomeCurrentLocationMarker> createState() =>
      _HomeCurrentLocationMarkerState();
}

class _HomeCurrentLocationMarkerState extends State<HomeCurrentLocationMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _opacityAnimation = Tween<double>(
      begin: 0.7,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // 1. Floating Tooltip Pill
        Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: EGoColors.brandNavy,
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: EGoColors.brandNavy.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: EGoColors.brandPrimary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                widget.label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                  color: EGoColors.white,
                ),
              ),
            ],
          ),
        ),

        // 2. Pulse Pin Marker
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Pulsing beacon wave
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: EGoColors.brandPrimary.withValues(
                          alpha: _opacityAnimation.value,
                        ),
                      ),
                    ),
                  );
                },
              ),

              // Solid static ring for visibility when animation is disabled
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EGoColors.brandPrimary.withValues(alpha: 0.25),
                ),
              ),

              // White disk with yellow border
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: EGoColors.white,
                  border: Border.all(
                    color: EGoColors.brandPrimary,
                    width: 2.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: EGoColors.brandNavy.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  // Inner navy dot
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: EGoColors.brandNavy,
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
