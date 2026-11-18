import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/booking/data/vehicle_repository.dart';

/// One of the two booking options: E-Rickshaw or Bike.
class VehicleOptionCard extends StatelessWidget {
  const VehicleOptionCard({
    super.key,
    required this.vehicle,
    required this.isSelected,
    required this.fareReady,
    required this.onTap,
  });

  final VehicleOption vehicle;
  final bool isSelected;
  final bool fareReady;
  final VoidCallback onTap;

  String get _displayName =>
      vehicle.type == VehicleType.toto ? 'E-Rickshaw' : 'Bike';

  String get _displaySubtitle => vehicle.type == VehicleType.toto
      ? 'Electric · up to 3 passengers'
      : 'Fast · 1 passenger';

  IconData get _icon => vehicle.type == VehicleType.toto
      ? Icons.electric_rickshaw
      : Icons.two_wheeler;

  @override
  Widget build(BuildContext context) {
    final fare = vehicle.fareBreakdown;

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '$_displayName. $_displaySubtitle. '
          '${fareReady ? 'Fare ${fare.totalFare.toStringAsFixed(0)} rupees' : 'Fare not calculated'}',
      child: Material(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(EGoSpacing.lg),
            decoration: BoxDecoration(
              color: isSelected
                  ? EGoColors.brandYellowMuted
                  : EGoColors.surface,
              borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
              border: Border.all(
                color: isSelected
                    ? EGoColors.brandPrimary
                    : EGoColors.outlineVariant,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? EGoColors.brandPrimaryLight
                        : EGoColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(EGoSpacing.radiusLarge),
                  ),
                  child: Icon(_icon, size: 30, color: EGoColors.brandNavy),
                ),
                const SizedBox(width: EGoSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _displayName,
                              style: EGoTypography.titleMedium.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: EGoSpacing.sm),
                            const Icon(
                              Icons.check_circle,
                              color: EGoColors.brandNavy,
                              size: EGoSpacing.iconSmall,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _displaySubtitle,
                        style: EGoTypography.bodySmall.copyWith(
                          color: EGoColors.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fareReady) ...[
                        const SizedBox(height: EGoSpacing.xs),
                        Text(
                          '${fare.estimatedArrivalMinutes} min away · '
                          '${fare.estimatedMinutes} min trip',
                          style: EGoTypography.labelSmall.copyWith(
                            color: EGoColors.onSurfaceMuted,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: EGoSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fareReady ? '₹${fare.totalFare.toStringAsFixed(0)}' : '—',
                      style: EGoTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: EGoColors.onSurface,
                      ),
                    ),
                    if (fareReady)
                      Text(
                        '${fare.distanceKm.toStringAsFixed(1)} km',
                        style: EGoTypography.labelSmall.copyWith(
                          color: EGoColors.onSurfaceMuted,
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
