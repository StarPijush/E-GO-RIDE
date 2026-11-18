import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'journey_route_icon.dart';

/// E-GO Gooey Bottom Navigation Component.
///
/// Native Flutter implementation of the React Bits GooeyNav concept,
/// adhering strictly to the official E-GO design system.
///
/// Features:
/// - Exactly four destinations: Home, Rides, Safety, Account.
/// - Fluid active-pill animation with organic stretch, liquid metaball bridge,
///   traveling droplet particles, and spring wobble landing.
/// - Premium custom outlined JourneyRouteIcon for Rides.
/// - Selected icon sits inside a yellow rounded pill (#FFC928) with deep navy (#142B45).
/// - Stable labels below icons with consistent typography (Inter 13px).
/// - Full accessibility and reduced motion support.
class EgoGooeyBottomNavigation extends StatefulWidget {
  const EgoGooeyBottomNavigation({
    super.key,
    required this.selectedIndex,
    this.onTap,
    this.profileLabel = 'Account',
    this.animationDuration = const Duration(milliseconds: 520),
    this.gooeyness = 0.5,
    this.wobble = 0.35,
  });

  /// The currently active navigation index (0: Home, 1: Rides, 2: Safety, 3: Account).
  final int selectedIndex;

  /// Callback when a navigation destination is tapped.
  final ValueChanged<int>? onTap;

  /// Visible label for the 4th destination (defaults to 'Account').
  final String profileLabel;

  /// Duration of the gooey traveling transition.
  final Duration animationDuration;

  /// Organic gooeyness factor (0.0 to 1.0).
  final double gooeyness;

  /// Landing spring wobble factor (0.0 to 1.0).
  final double wobble;

  // ── Official E-GO Colors ───────────────────────────────────────────────────
  static const Color brandYellow = Color(0xFFFFC928);
  static const Color brandNavy = Color(0xFF142B45);
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color mutedSlate = Color(0xFF8491A2);
  static const Color topDivider = Color(0xFFE7EBF0);

  // ── Pill Dimensions ────────────────────────────────────────────────────────
  static const double pillWidth = 54.0;
  static const double pillHeight = 48.0;
  static const double pillRadius = 24.0;
  static const double iconSize = 26.0;

  @override
  State<EgoGooeyBottomNavigation> createState() =>
      _EgoGooeyBottomNavigationState();
}

class _EgoGooeyBottomNavigationState extends State<EgoGooeyBottomNavigation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late int _fromIndex;
  late int _toIndex;

  @override
  void initState() {
    super.initState();
    _fromIndex = widget.selectedIndex;
    _toIndex = widget.selectedIndex;
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    )..value = 1.0; // Starts at resting state
  }

  @override
  void didUpdateWidget(covariant EgoGooeyBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != _toIndex) {
      _startTransition(widget.selectedIndex);
    }
  }

  void _startTransition(int newIndex) {
    if (newIndex == _toIndex && _controller.isCompleted) return;

    final reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reducedMotion) {
      setState(() {
        _fromIndex = newIndex;
        _toIndex = newIndex;
        _controller.value = 1.0;
      });
      return;
    }

    setState(() {
      _fromIndex = _toIndex;
      _toIndex = newIndex;
    });

    _controller.forward(from: 0.0);
  }

  void _handleTap(int index) {
    if (index == _toIndex) return;
    widget.onTap?.call(index);
    _startTransition(index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EgoGooeyBottomNavigation.surfaceWhite,
        border: Border(
          top: BorderSide(
            color: EgoGooeyBottomNavigation.topDivider,
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final itemWidth = totalWidth / 4.0;
            // The icon box is 48px high, top padding 6px, so center is 6 + 24 = 30px
            const double iconBoxHeight = EgoGooeyBottomNavigation.pillHeight;
            const double topPad = 6.0;
            const double pillCenterY = topPad + (iconBoxHeight / 2.0);

            return SizedBox(
              height: 80.0,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // 1. Gooey Active Pill Layer
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        return CustomPaint(
                          painter: _GooeyPillPainter(
                            progress: _controller.value,
                            fromIndex: _fromIndex,
                            toIndex: _toIndex,
                            itemWidth: itemWidth,
                            centerY: pillCenterY,
                            pillWidth: EgoGooeyBottomNavigation.pillWidth,
                            pillHeight: EgoGooeyBottomNavigation.pillHeight,
                            pillRadius: EgoGooeyBottomNavigation.pillRadius,
                            pillColor: EgoGooeyBottomNavigation.brandYellow,
                            gooeyness: widget.gooeyness,
                            wobble: widget.wobble,
                          ),
                        );
                      },
                    ),
                  ),

                  // 2. Interactive Navigation Items Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildNavItem(
                        index: 0,
                        itemWidth: itemWidth,
                        icon: Icons.home_outlined,
                        label: 'Home',
                      ),
                      _buildNavItem(
                        index: 1,
                        itemWidth: itemWidth,
                        isRides: true,
                        label: 'Rides',
                      ),
                      _buildNavItem(
                        index: 2,
                        itemWidth: itemWidth,
                        icon: Icons.shield_outlined,
                        label: 'Safety',
                      ),
                      _buildNavItem(
                        index: 3,
                        itemWidth: itemWidth,
                        icon: Icons.person_outline_rounded,
                        label: widget.profileLabel,
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required double itemWidth,
    IconData? icon,
    bool isRides = false,
    required String label,
  }) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Compute active interpolation fraction for this item
        double activeFraction;
        final t = _controller.value;
        if (_fromIndex == _toIndex) {
          activeFraction = (index == _toIndex) ? 1.0 : 0.0;
        } else if (index == _toIndex) {
          activeFraction = Curves.easeIn.transform(t);
        } else if (index == _fromIndex) {
          activeFraction = 1.0 - Curves.easeOut.transform(t);
        } else {
          activeFraction = 0.0;
        }

        final itemColor = Color.lerp(
          EgoGooeyBottomNavigation.mutedSlate,
          EgoGooeyBottomNavigation.brandNavy,
          activeFraction,
        )!;

        final isSelected = activeFraction > 0.5;

        return SizedBox(
          width: itemWidth,
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: () => _handleTap(index),
              containedInkWell: true,
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              splashFactory: NoSplash.splashFactory,
              radius: itemWidth * 0.45,
              child: Padding(
                padding: const EdgeInsets.only(top: 6.0, bottom: 6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon Zone (48px high, perfectly matches active pill height)
                    SizedBox(
                      height: EgoGooeyBottomNavigation.pillHeight,
                      width: EgoGooeyBottomNavigation.pillWidth,
                      child: Center(
                        child: isRides
                            ? JourneyRouteIcon(
                                color: itemColor,
                                size: EgoGooeyBottomNavigation.iconSize,
                              )
                            : Icon(
                                icon,
                                size: EgoGooeyBottomNavigation.iconSize,
                                color: itemColor,
                              ),
                      ),
                    ),
                    const SizedBox(height: 4.0),
                    // Label Zone (positioned below icon area, never inside pill)
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13.0,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: itemColor,
                        letterSpacing: -0.1,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gooey Active Pill Custom Painter
// ─────────────────────────────────────────────────────────────────────────────

class _GooeyPillPainter extends CustomPainter {
  const _GooeyPillPainter({
    required this.progress,
    required this.fromIndex,
    required this.toIndex,
    required this.itemWidth,
    required this.centerY,
    required this.pillWidth,
    required this.pillHeight,
    required this.pillRadius,
    required this.pillColor,
    required this.gooeyness,
    required this.wobble,
  });

  final double progress;
  final int fromIndex;
  final int toIndex;
  final double itemWidth;
  final double centerY;
  final double pillWidth;
  final double pillHeight;
  final double pillRadius;
  final Color pillColor;
  final double gooeyness;
  final double wobble;

  // React Bits travelEase curve: cubic in/out
  static double _travelEase(double t) {
    final x = t.clamp(0.0, 1.0);
    return x < 0.5 ? 4.0 * x * x * x : 1.0 - math.pow(-2.0 * x + 2.0, 3) / 2.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = pillColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final startX = (fromIndex + 0.5) * itemWidth;
    final endX = (toIndex + 0.5) * itemWidth;

    // Resting state (when animation is idle or indexes match)
    if (fromIndex == toIndex || progress >= 1.0) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(endX, centerY),
          width: pillWidth,
          height: pillHeight,
        ),
        Radius.circular(pillRadius),
      );
      canvas.drawRRect(rect, paint);
      return;
    }

    final t = progress.clamp(0.0, 1.0);
    final distance = (endX - startX).abs();
    final direction = endX > startX ? 1.0 : -1.0;

    // 1. Traveling Main Body
    final eased = _travelEase(t);
    final currentX = startX + (endX - startX) * eased;

    // Fluid horizontal stretch during transit (anticipation + flight stretch)
    final stretchAmount = math.sin(math.pi * t) * math.min(distance * 0.22, 22.0);
    final currentW = pillWidth + stretchAmount;
    final currentH = pillHeight - (stretchAmount * 0.24);

    // 2. Landing Wobble in final phase (t in [0.7, 1.0])
    double wobbleW = 0.0;
    double wobbleH = 0.0;
    if (t > 0.7) {
      final tau = (t - 0.7) / 0.3;
      final damped = wobble * math.exp(-4.2 * tau) * math.sin(3.5 * math.pi * tau);
      wobbleW = pillWidth * damped * 0.28;
      wobbleH = -pillHeight * damped * 0.28;
    }

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(currentX, centerY),
        width: currentW + wobbleW,
        height: currentH + wobbleH,
      ),
      Radius.circular(pillRadius),
    );

    // 3. Departing source mass & liquid metaball neck during early phase (t in [0.0, 0.42])
    if (t < 0.42 && distance > 20.0) {
      final decay = (1.0 - (t / 0.42)).clamp(0.0, 1.0);
      final srcRadius = pillRadius * math.pow(decay, 0.85);

      if (srcRadius > 2.0) {
        // Draw remaining source mass
        canvas.drawCircle(Offset(startX, centerY), srcRadius, paint);

        // Draw gooey metaball bridge if distance between edges is within reach
        final delta = (currentX - startX).abs();
        final maxBridgeDist = (srcRadius + pillRadius + 38.0 * gooeyness);

        if (delta < maxBridgeDist) {
          final bridgeRatio = (delta / maxBridgeDist).clamp(0.0, 1.0);
          final waistH = math.max(
            0.0,
            srcRadius * (1.0 - math.pow(bridgeRatio, 1.35)) * gooeyness,
          );

          if (waistH > 1.0) {
            final bridgePath = Path();
            final srcEdgeX = startX + direction * (srcRadius * 0.6);
            final bodyEdgeX = currentX - direction * (currentW * 0.35);
            final midX = (srcEdgeX + bodyEdgeX) / 2.0;

            // Top contour of liquid neck
            bridgePath.moveTo(srcEdgeX, centerY - srcRadius * 0.9);
            bridgePath.quadraticBezierTo(
              midX,
              centerY - waistH,
              bodyEdgeX,
              centerY - (currentH / 2.0) * 0.9,
            );
            // Connect to bottom
            bridgePath.lineTo(bodyEdgeX, centerY + (currentH / 2.0) * 0.9);
            // Bottom contour of liquid neck
            bridgePath.quadraticBezierTo(
              midX,
              centerY + waistH,
              srcEdgeX,
              centerY + srcRadius * 0.9,
            );
            bridgePath.close();

            canvas.drawPath(bridgePath, paint);
          }
        }
      }
    }

    // Draw main body
    canvas.drawRRect(bodyRect, paint);

    // 4. Fluid Droplet Particles (React Bits inspired droplet swarm)
    // 5 droplets flying with staggered timings and vertical arcs
    const particleCount = 5;
    for (int i = 0; i < particleCount; i++) {
      final startDelay = 0.10 + i * 0.055;
      const flightDuration = 0.44;
      final endWindow = startDelay + flightDuration;

      if (t >= startDelay && t <= endWindow) {
        final tau = (t - startDelay) / flightDuration;
        final dropEased = _travelEase(tau);

        // Position along journey
        final dropX = startX + (endX - startX) * dropEased;

        // Vertical arc dispersion
        final arcSign = (i % 2 == 0) ? -1.0 : 1.0;
        final arcHeight = (4.0 + (i * 2.2)) * arcSign;
        final dropY = centerY + math.sin(math.pi * tau) * arcHeight;

        // Droplet radius: emerges, flies at full scale, then absorbs
        final peakRadius = 2.2 + (i % 3) * 0.8;
        final dropRadius = peakRadius * math.sin(math.pi * tau.clamp(0.0, 1.0));

        if (dropRadius > 0.4) {
          canvas.drawCircle(Offset(dropX, dropY), dropRadius, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GooeyPillPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.fromIndex != fromIndex ||
        oldDelegate.toIndex != toIndex ||
        oldDelegate.itemWidth != itemWidth ||
        oldDelegate.centerY != centerY;
  }
}

