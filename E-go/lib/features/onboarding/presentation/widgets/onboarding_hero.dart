import 'package:flutter/material.dart';
import '../theme/onboarding_constants.dart';
import 'onboarding_illustrations/wind_trails_painter.dart';

/// Hero style variants supported by the onboarding system.
enum OnboardingHeroVariant {
  /// Screen 01: gradient disk, ambient ring, halo pulse, and telemetry capsule.
  location,

  /// Screen 02: pale-yellow disk, ambient ring, wind trails, lightning badge.
  bike,

  /// Screen 03: pale-yellow disk, ambient ring, TOTO silhouette.
  toto,
}

/// Reusable hero container for all three onboarding screens.
///
/// ALL variants share the exact same outer [OnboardingConstants.heroAreaSize] (272 × 272 px),
/// the exact same [OnboardingConstants.heroDiskSize] (236 px) background circle,
/// and the exact same [OnboardingConstants.heroRingSize] (216 px) ambient ring with
/// [OnboardingConstants.heroRingBorderWidth] (1 px) stroke.
class OnboardingHero extends StatefulWidget {
  // ── Screen 01 constructor ──────────────────────────────────────────────────
  const OnboardingHero({
    super.key,
    required this.illustration,
    this.badgeText = 'Urban Flow',
    this.showBadge = true,
    this.enableAnimations = true,
  }) : variant = OnboardingHeroVariant.location;

  // ── Screen 02 constructor ──────────────────────────────────────────────────
  const OnboardingHero.bike({
    super.key,
    required this.illustration,
    this.enableAnimations = true,
  }) : variant = OnboardingHeroVariant.bike,
       badgeText = '',
       showBadge = false;

  // ── Screen 03 constructor ──────────────────────────────────────────────────
  const OnboardingHero.toto({
    super.key,
    required this.illustration,
    this.enableAnimations = true,
  }) : variant = OnboardingHeroVariant.toto,
       badgeText = '',
       showBadge = false;

  final Widget illustration;
  final String badgeText;
  final bool showBadge;
  final bool enableAnimations;
  final OnboardingHeroVariant variant;

  @override
  State<OnboardingHero> createState() => _OnboardingHeroState();
}

class _OnboardingHeroState extends State<OnboardingHero>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  AnimationController? _windController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.variant == OnboardingHeroVariant.location) {
      _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2000),
      );
      if (widget.enableAnimations) {
        _pulseController!.repeat(reverse: true);
      }
      _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
      _opacityAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
      );
    } else if (widget.variant == OnboardingHeroVariant.bike) {
      _windController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      );
      if (widget.enableAnimations) {
        _windController!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _windController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.variant) {
      OnboardingHeroVariant.location => _buildLocationHero(),
      OnboardingHeroVariant.bike => _buildBikeHero(),
      OnboardingHeroVariant.toto => _buildTotoHero(),
    };
  }

  // ── Shared canonical hero shell (272 × 272 px) ───────────────────────────
  Widget _buildSharedShell({
    required Widget disk,
    required List<Widget> children,
    Widget? haloLayer,
  }) {
    return SizedBox(
      width: OnboardingConstants.heroAreaSize,
      height: OnboardingConstants.heroAreaSize,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [if (haloLayer != null) haloLayer, disk, ...children],
      ),
    );
  }

  // ── Screen 1 Gradient Disk (236 × 236 px) ─────────────────────────────────
  Widget _locationDisk({Widget? child}) {
    return Container(
      width: OnboardingConstants.heroDiskSize,
      height: OnboardingConstants.heroDiskSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OnboardingConstants.yellowTop,
            OnboardingConstants.yellowBottom,
          ],
        ),
        border: Border.all(color: OnboardingConstants.border, width: 1.0),
        boxShadow: const [
          BoxShadow(
            color: OnboardingConstants.shadow,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: child ?? const SizedBox.shrink(),
    );
  }

  // ── Screens 2 & 3 Flat Disk (236 × 236 px) ────────────────────────────────
  Widget _flatDisk({required Color color, Widget? child}) {
    return Container(
      width: OnboardingConstants.heroDiskSize,
      height: OnboardingConstants.heroDiskSize,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: child ?? const SizedBox.shrink(),
    );
  }

  // ── Shared Ambient Ring (216 × 216 px, 1 px border) ───────────────────────
  Widget _ambientRing({required Color color}) {
    return Container(
      width: OnboardingConstants.heroRingSize,
      height: OnboardingConstants.heroRingSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: color,
          width: OnboardingConstants.heroRingBorderWidth,
        ),
      ),
    );
  }

  // ── Screen 01: Location Hero ──────────────────────────────────────────────
  Widget _buildLocationHero() {
    Widget? halo;
    if (_pulseController != null) {
      halo = AnimatedBuilder(
        animation: _pulseController!,
        builder: (context, _) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: Container(
                width: OnboardingConstants.heroDiskSize + 24,
                height: OnboardingConstants.heroDiskSize + 24,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: OnboardingConstants.yellowHalo,
                      blurRadius: 40,
                      spreadRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return _buildSharedShell(
      haloLayer: halo,
      disk: _locationDisk(),
      children: [
        // 216 px Ring (1 px border) — explicitly present on Screen 1
        _ambientRing(color: OnboardingConstants.ringBorder),

        // Centered artwork
        Center(child: widget.illustration),

        // Floating URBAN FLOW badge at bottom right
        if (widget.showBadge)
          Positioned(
            bottom:
                (OnboardingConstants.heroAreaSize -
                        OnboardingConstants.heroDiskSize) /
                    2 +
                8,
            right:
                (OnboardingConstants.heroAreaSize -
                        OnboardingConstants.heroDiskSize) /
                    2 +
                12,
            child: _TelemetryBadge(
              label: widget.badgeText,
              enableAnimations: widget.enableAnimations,
            ),
          ),
      ],
    );
  }

  // ── Screen 02: Bike Hero ──────────────────────────────────────────────────
  Widget _buildBikeHero() {
    return _buildSharedShell(
      disk: _flatDisk(color: OnboardingConstants.diskBackground),
      children: [
        // 216 px Ring (1 px border)
        _ambientRing(color: OnboardingConstants.ringBorder),

        // Dynamic wind speed lines behind bike
        if (_windController != null)
          AnimatedBuilder(
            animation: _windController!,
            builder: (context, _) {
              return CustomPaint(
                size: const Size(
                  OnboardingConstants.heroAreaSize,
                  OnboardingConstants.heroAreaSize,
                ),
                painter: WindTrailsPainter(
                  animationProgress: _windController!.value,
                ),
              );
            },
          )
        else
          CustomPaint(
            size: const Size(
              OnboardingConstants.heroAreaSize,
              OnboardingConstants.heroAreaSize,
            ),
            painter: const WindTrailsPainter(animationProgress: 0.0),
          ),

        // Centered motorcycle artwork
        Center(child: widget.illustration),

        // Floating waypoint lightning badge at top right
        const Positioned(top: 24, right: 24, child: _WaypointLightningBadge()),
      ],
    );
  }

  // ── Screen 03: TOTO Hero ──────────────────────────────────────────────────
  Widget _buildTotoHero() {
    return _buildSharedShell(
      disk: _flatDisk(color: OnboardingConstants.diskBackground),
      children: [
        // 216 px Ring (1 px border)
        _ambientRing(color: OnboardingConstants.ringBorder),

        // Centered official E-GO TOTO silhouette
        Center(child: widget.illustration),
      ],
    );
  }
}

// ── Upper-right floating waypoint badge (Screen 02 only) ─────────────────
class _WaypointLightningBadge extends StatelessWidget {
  const _WaypointLightningBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: OnboardingConstants.surface,
        shape: BoxShape.circle,
        border: Border.all(
          color: OnboardingConstants.surfaceContainer,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: OnboardingConstants.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Center(child: _LightningBoltIcon()),
    );
  }
}

class _LightningBoltIcon extends StatelessWidget {
  const _LightningBoltIcon();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(18, 18),
      painter: const _LightningBoltPainter(),
    );
  }
}

class _LightningBoltPainter extends CustomPainter {
  const _LightningBoltPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / 18.0;
    final scaleY = size.height / 18.0;
    canvas.save();
    canvas.scale(scaleX, scaleY);

    final path = Path()
      ..moveTo(10.5, 1.5)
      ..lineTo(4.5, 9.5)
      ..lineTo(9.5, 9.5)
      ..lineTo(7.5, 16.5)
      ..lineTo(14.5, 8.5)
      ..lineTo(9.5, 8.5)
      ..close();

    canvas.drawPath(
      path,
      Paint()
        ..color = OnboardingConstants.yellowCta
        ..style = PaintingStyle.fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Telemetry badge (Screen 01 only) ──────────────────────────────────────
class _TelemetryBadge extends StatefulWidget {
  const _TelemetryBadge({required this.label, this.enableAnimations = true});

  final String label;
  final bool enableAnimations;

  @override
  State<_TelemetryBadge> createState() => _TelemetryBadgeState();
}

class _TelemetryBadgeState extends State<_TelemetryBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dotController;
  late final Animation<double> _dotScale;
  late final Animation<double> _dotOpacity;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.enableAnimations) {
      _dotController.repeat(reverse: true);
    }
    _dotScale = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _dotController, curve: Curves.easeInOut));
    _dotOpacity = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dotController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4.5),
      decoration: BoxDecoration(
        color: OnboardingConstants.surface,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: OnboardingConstants.surfaceContainerHigh,
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: OnboardingConstants.shadow,
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _dotController,
            builder: (context, _) {
              return Transform.scale(
                scale: _dotScale.value,
                child: Opacity(
                  opacity: _dotOpacity.value,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: OnboardingConstants.yellowCta,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          Text(
            widget.label.toUpperCase(),
            style: const TextStyle(
              fontFamily: OnboardingConstants.fontFamily,
              fontSize: 11,
              height: 14 / 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.88,
              color: OnboardingConstants.primary,
            ),
          ),
        ],
      ),
    );
  }
}
