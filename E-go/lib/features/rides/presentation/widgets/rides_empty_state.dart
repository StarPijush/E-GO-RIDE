import 'package:flutter/material.dart';

const Color _kNavy = Color(0xFF142B45);
const Color _kYellow = Color(0xFFFFC928);
const Color _kSecondaryText = Color(0xFF8490A0);
const String _kFontInter = 'Inter';
const String _kFontManrope = 'Manrope';

/// Empty state for E-GO Your Rides screen.
/// Balanced, compact, and cleanly centered slightly above the viewport midpoint.
class RidesEmptyState extends StatelessWidget {
  const RidesEmptyState({
    super.key,
    required this.onBookPressed,
  });

  final VoidCallback onBookPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Positioned slightly above the vertical center of the content area
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'No rides yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: _kFontManrope,
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: _kNavy,
                            letterSpacing: -0.3,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: const Text(
                            'Your completed and cancelled rides will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: _kFontInter,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: _kSecondaryText,
                              height: 1.45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: onBookPressed,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _kYellow,
                                foregroundColor: _kNavy,
                                elevation: 0,
                                shadowColor: const Color(0x1A142B45),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Book Your',
                                    style: TextStyle(
                                      fontFamily: _kFontInter,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _kNavy,
                                      height: 1.15,
                                    ),
                                  ),
                                  Text(
                                    'Ride',
                                    style: TextStyle(
                                      fontFamily: _kFontInter,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: _kNavy,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
