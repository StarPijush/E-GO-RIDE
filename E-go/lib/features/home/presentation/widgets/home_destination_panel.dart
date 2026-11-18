import 'package:flutter/material.dart';

import 'package:e_go/features/home/presentation/widgets/destination_search_card.dart';
import 'package:e_go/features/home/presentation/widgets/popular_destination_card.dart';
import 'package:e_go/features/home/presentation/widgets/recent_destination_card.dart';
import 'package:e_go/features/location/data/popular_destinations.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/domain/popular_destination_model.dart';

/// Reference-accurate Home Destination Sheet.
///
/// Implements:
/// - White-to-warm-yellow gradient (#FFF4CC -> #FFF8E8)
/// - Rounded top corners (28px) with subtle top border
/// - 48x6px rounded translucent navy drag handle
/// - 32px Manrope ExtraBold "Where to?" heading
/// - 64px Destination Search Card with pale yellow icon well
/// - Conditional Recent Destination Card (data-driven, zero fake placeholders)
/// - "Popular in Jhargram" section heading
/// - 2x2 grid of 4 image destination cards (Jhargram Palace, Jhargram Station,
///   Central Bus Stand, Kanak Durga Temple)
class HomeDestinationPanel extends StatelessWidget {
  const HomeDestinationPanel({
    super.key,
    required this.destination,
    required this.lastUsed,
    this.popular = const [],
    this.popularModels,
    required this.onDestinationTap,
    required this.onLastUsedTap,
    required this.onPopularTap,
  });

  final SavedLocation? destination;
  final SavedLocation? lastUsed;
  final List<SavedLocation> popular;
  final List<PopularDestinationModel>? popularModels;
  final VoidCallback onDestinationTap;
  final ValueChanged<SavedLocation> onLastUsedTap;
  final ValueChanged<SavedLocation> onPopularTap;

  List<PopularDestinationModel> get _resolvedModels {
    if (popularModels != null && popularModels!.isNotEmpty) {
      return popularModels!;
    }
    return PopularDestinations.resolveModels();
  }

  @override
  Widget build(BuildContext context) {
    final items = _resolvedModels;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFF4CC),
            Color(0xFFFFF8E8),
            Color(0xFFFFF8E8),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: Color(0x70F1E5C4),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1F142B45),
            blurRadius: 24,
            spreadRadius: 0,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Centered Drag Handle
                Center(
                  child: Container(
                    width: 48,
                    height: 6,
                    decoration: BoxDecoration(
                      color: const Color(0xFF142B45).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Heading: "Where to?"
                const Text(
                  'Where to?',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.64, // -0.02em
                    height: 1.15,
                    color: Color(0xFF142B45),
                  ),
                ),
                const SizedBox(height: 16),

                // Destination Search Card
                DestinationSearchCard(
                  onTap: onDestinationTap,
                  label: destination?.label ?? 'Choose your destination',
                ),

                // Conditional Recent Destination System
                if (lastUsed != null) ...[
                  const SizedBox(height: 12),
                  RecentDestinationCard(
                    location: lastUsed!,
                    onTap: () => onLastUsedTap(lastUsed!),
                  ),
                ],

                const SizedBox(height: 20),

                // Section Header: "Popular in Jhargram"
                const Text(
                  'Popular in Jhargram',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.1,
                    height: 1.3,
                    color: Color(0xFF142B45),
                  ),
                ),
                const SizedBox(height: 14),

                // 2x2 Grid of Exactly 4 Popular Destination Cards
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.88,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return PopularDestinationCard(
                      destination: item,
                      onTap: () => onPopularTap(item.toSavedLocation()),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
