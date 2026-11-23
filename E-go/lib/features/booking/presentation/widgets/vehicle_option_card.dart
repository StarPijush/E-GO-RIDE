import 'package:flutter/material.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';
import 'vehicle_icon_widgets.dart';

/// Simplified, premium vehicle card combining Rapido and Jugnoo patterns.
///
/// Features:
/// - LEFT: Clean vector vehicle artwork + Vehicle name (+ optional badge)
/// - MIDDLE: Short ride description + arrival estimate & passenger capacity
/// - RIGHT: Exactly ONE prominent fare + small information icon (i)
/// - NO duplicate prices or confusing crossed-out figures
/// - Selected state: Crisp Deep Navy outline with subtle elevation
/// - Unselected state: Clean white background with neutral border
class VehicleOptionCard extends StatelessWidget {
  const VehicleOptionCard({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.fareReady,
    required this.onTap,
    this.onInfoTap,
  });

  final VehicleOption vehicle;
  final bool isSelected;
  final bool fareReady;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;

  bool get _isToto => vehicle.type == VehicleType.toto;

  String get _displayName => _isToto ? 'E-Rickshaw' : 'Bike';

  int get _capacity => _isToto ? 3 : 1;

  String get _description =>
      _isToto ? 'Personal E-Rickshaw' : 'Quick Bike rides';

  String get _etaText => _isToto ? '4 mins away' : '2 mins away';

  String get _capacityText =>
      _capacity == 1 ? '1 passenger' : '$_capacity passengers';

  @override
  Widget build(BuildContext context) {
    final fare = vehicle.fareBreakdown;
    final fareText = fareReady ? fare.totalFare.toStringAsFixed(0) : '--';

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$_displayName, $_capacityText, $_etaText, ₹$fareText, $_description',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF142B45) // Deep Navy selected outline
                    : const Color(0xFFE2E8F0), // Subtle neutral border
                width: isSelected ? 1.8 : 1.0,
              ),
              boxShadow: [
                if (isSelected)
                  BoxShadow(
                    color: const Color(0xFF142B45).withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                else
                  BoxShadow(
                    color: const Color(0xFF142B45).withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
              ],
            ),
            child: Row(
              children: [
                // 1. Vehicle Artwork Container (52x46)
                Container(
                  width: 52,
                  height: 46,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: _isToto
                        ? const Color(0xFFFFF9E6)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isToto
                          ? const Color(0xFFFFC928).withValues(alpha: 0.35)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Center(
                    child: _isToto
                        ? const TotoIconWidget(size: 38)
                        : const BikeIconWidget(size: 38),
                  ),
                ),
                const SizedBox(width: 10),

                // 2. Center Content: Name, Badge, Description, ETA & Capacity
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Row A: Title + FASTEST Badge (for Bike) + Checkmark
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _displayName,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF142B45),
                                height: 1.1,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (!_isToto) ...[
                            const SizedBox(width: 5),
                            // FASTEST Pill Badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4.5,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE6F7F0), // Mint background
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'FASTEST',
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                  color: Color(0xFF0D8364), // Dark mint/green
                                  height: 1.0,
                                ),
                              ),
                            ),
                          ],
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.check_circle,
                              size: 15,
                              color: Color(0xFF142B45),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 3),

                      // Row B: Supporting Description
                      Text(
                        _description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),

                      // Row C: Arrival Estimate & Capacity
                      Text(
                        '$_etaText · $_capacityText',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // 3. Trailing: Single Prominent Fare + Information Button (i)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF142B45),
                          ),
                        ),
                        const SizedBox(width: 1),
                        Text(
                          fareText,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF142B45),
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 2),

                    // Information Button (Jugnoo / Rapido pattern)
                    Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onInfoTap,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.info_outline,
                            size: 17,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
