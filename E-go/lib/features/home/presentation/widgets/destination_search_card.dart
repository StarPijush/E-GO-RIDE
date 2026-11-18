import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';

/// Reference-accurate Destination Search Card.
///
/// Layout:
/// - 64px height
/// - Pure white surface with 16px corner radius
/// - Fine border: #E8ECF2
/// - Subtle shadow: 0 8px 24px -4px rgba(20, 43, 69, 0.06)
/// - Left 40×40px pale-yellow well with #142B45 search icon
/// - "Choose your destination" text in 16px semibold navy
/// - Right chevron icon in translucent navy
class DestinationSearchCard extends StatelessWidget {
  const DestinationSearchCard({
    super.key,
    required this.onTap,
    this.label = 'Choose your destination',
  });

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: EGoColors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: EGoColors.brandPrimary.withValues(alpha: 0.12),
          highlightColor: EGoColors.brandPrimary.withValues(alpha: 0.06),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFFE8ECF2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF142B45).withValues(alpha: 0.06),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: Row(
              children: [
                // Leading pale yellow icon container
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFC928).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.search,
                      size: 22,
                      color: Color(0xFF142B45),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Destination label
                Expanded(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF142B45),
                    ),
                  ),
                ),

                // Trailing chevron
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0x66142B45),
                    ),
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
