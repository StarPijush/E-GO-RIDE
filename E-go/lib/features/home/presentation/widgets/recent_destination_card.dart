import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/location/domain/location_model.dart';

/// Data-driven card for the latest recent destination.
///
/// Only shown when real historical destination data exists.
/// Never displays fake seed data or empty reserved placeholders.
class RecentDestinationCard extends StatelessWidget {
  const RecentDestinationCard({
    super.key,
    required this.location,
    required this.onTap,
  });

  final SavedLocation location;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Recent destination: ${location.label}',
      child: Material(
        color: EGoColors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: EGoColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: EGoColors.brandPrimary.withValues(alpha: 0.06),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE8ECF2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF142B45).withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // History icon container
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.history,
                      size: 20,
                      color: Color(0xFF142B45),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Name and address
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF142B45),
                        ),
                      ),
                      if (location.subtitle != null &&
                          location.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          location.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF778397),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Trailing chevron
                const SizedBox(width: 8),
                const Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: Color(0x66142B45),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
