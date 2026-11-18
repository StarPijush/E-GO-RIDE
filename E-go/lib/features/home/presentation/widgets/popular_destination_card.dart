import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/location/domain/popular_destination_model.dart';

/// Reference-accurate card for the 2x2 Popular Destinations grid.
///
/// Layout:
/// - White container with 16px border radius
/// - 10px internal padding
/// - Fine hairline border: #E8ECF2
/// - Card shadow: 0 8px 24px -4px rgba(20, 43, 69, 0.06)
/// - Top 96px image with 12px rounded corners and BoxFit.cover
/// - Fallback placeholder container if image asset fails to load
/// - Destination title: 14px bold in deep navy (#142B45)
class PopularDestinationCard extends StatelessWidget {
  const PopularDestinationCard({
    super.key,
    required this.destination,
    required this.onTap,
  });

  final PopularDestinationModel destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: destination.displayName,
      child: Material(
        color: EGoColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: EGoColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: EGoColors.brandPrimary.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8ECF2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF142B45).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top image container: height 96px, rounded 12px
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 96,
                    width: double.infinity,
                    child: Image.asset(
                      destination.imageAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFFF0F3F7),
                          child: Center(
                            child: Icon(
                              Icons.location_on,
                              size: 32,
                              color: EGoColors.brandPrimary,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Destination title: 14px bold navy
                Text(
                  destination.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    color: Color(0xFF142B45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
