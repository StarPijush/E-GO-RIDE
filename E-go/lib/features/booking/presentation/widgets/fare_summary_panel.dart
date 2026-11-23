import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/core/booking_stage.dart';
import 'package:e_go/core/mock_pricing.dart';

/// Fare states for the Place Order screen.
///
/// A number is only rendered when a fare is actually ready for the selected
/// vehicle.
class FareSummaryPanel extends StatelessWidget {
  const FareSummaryPanel({
    super.key,
    required this.fareState,
    required this.fare,
    required this.hasSelection,
    required this.error,
    required this.onRetry,
  });

  final FareCalculationState fareState;
  final FareBreakdown? fare;
  final bool hasSelection;
  final String? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(EGoSpacing.lg),
      decoration: BoxDecoration(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
        border: Border.all(color: EGoColors.outlineVariant),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (fareState == FareCalculationState.loading) {
      return Row(
        children: [
          const SizedBox(
            width: EGoSpacing.iconSmall,
            height: EGoSpacing.iconSmall,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: EGoSpacing.md),
          Text('Estimating fare...', style: EGoTypography.bodyMedium),
        ],
      );
    }

    if (fareState == FareCalculationState.unavailable) {
      return _message(
        title: 'No vehicles available for this route.',
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    if (fareState == FareCalculationState.error) {
      return _message(
        title: error ?? 'Could not calculate fare.',
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    if (fareState != FareCalculationState.ready ||
        !hasSelection ||
        fare == null) {
      return Text(
        'Select a vehicle to see the fare.',
        style: EGoTypography.bodyMedium.copyWith(
          color: EGoColors.onSurfaceMuted,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimated fare (demo)',
                    style: EGoTypography.labelMedium.copyWith(
                      color: EGoColors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: EGoSpacing.xs),
                  Text(
                    '₹${fare!.totalFare.toStringAsFixed(0)}',
                    style: EGoTypography.headlineSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Text(
                'Approx. distance\n'
                '${fare!.distanceKm.toStringAsFixed(1)} km',
                textAlign: TextAlign.right,
                style: EGoTypography.bodySmall.copyWith(
                  color: EGoColors.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: EGoSpacing.md),
        const Divider(height: 1),
        const SizedBox(height: EGoSpacing.md),
        _row('Base fare', '₹${fare!.baseFare.toStringAsFixed(0)}'),
        _row('Distance fare', '₹${fare!.distanceFare.toStringAsFixed(0)}'),
        _row('Platform fee', '₹${fare!.platformFee.toStringAsFixed(0)}'),
        const SizedBox(height: EGoSpacing.sm),
        Text(
          'Demo pricing - not a live quote.',
          style: EGoTypography.labelSmall.copyWith(
            color: EGoColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }

  Widget _message({
    required String title,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        const Icon(
          Icons.info_outline,
          color: EGoColors.warning,
          size: EGoSpacing.iconMedium,
        ),
        const SizedBox(width: EGoSpacing.md),
        Expanded(child: Text(title, style: EGoTypography.bodyMedium)),
        TextButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: EGoSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: EGoTypography.bodySmall.copyWith(
              color: EGoColors.onSurfaceMuted,
            ),
          ),
          Text(value, style: EGoTypography.bodySmall),
        ],
      ),
    );
  }
}
