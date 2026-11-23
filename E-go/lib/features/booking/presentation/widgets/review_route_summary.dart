import 'package:flutter/material.dart';
import 'package:e_go/features/location/domain/location_model.dart';

/// Route summary section immediately below the map.
///
/// Displays:
/// - "YOUR ROUTE" heading
/// - Vertical route connector (white/navy circle -> line -> yellow/navy circle)
/// - Pickup place name and subtitle
/// - Destination place name and subtitle
///
/// NOTE: "Change route" button and its edit icon are completely removed
/// as mandated by the master specification.
class ReviewRouteSummary extends StatelessWidget {
  const ReviewRouteSummary({
    super.key,
    required this.pickup,
    required this.destination,
  });

  final SavedLocation? pickup;
  final SavedLocation? destination;

  @override
  Widget build(BuildContext context) {
    final pickupTitle = pickup?.label ?? 'Current location';
    final pickupSubtitle = pickup?.subtitle ?? 'Pickup point';
    final destTitle = destination?.label ?? 'Select destination';
    final destSubtitle = destination?.subtitle ?? 'Drop point';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Heading (No Change button)
          const Text(
            'YOUR ROUTE',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF142B45),
            ),
          ),
          const SizedBox(height: 12),

          // Aligned Route Row with vertical connector
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vertical route marker column
              SizedBox(
                width: 14,
                child: Column(
                  children: [
                    const SizedBox(height: 3),
                    // Pickup circle: white fill, navy 2px stroke
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF142B45),
                          width: 2,
                        ),
                      ),
                    ),
                    // Vertical connecting line with gradient
                    Container(
                      width: 2,
                      height: 32,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF142B45),
                            Color(0xFFCBD5E1),
                            Color(0xFFFFC928),
                          ],
                        ),
                      ),
                    ),
                    // Destination circle: yellow fill, navy 2px stroke
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFC928),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF142B45),
                          width: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Address text hierarchy
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickupTitle,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF142B45),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          pickupSubtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Destination
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destTitle,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF142B45),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          destSubtitle,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF64748B),
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
