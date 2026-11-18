import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/location/domain/location_model.dart';

/// A saved/popular/recent location row.
///
/// There is deliberately no remove action: recent history is managed by
/// successful orders only.
class LocationTile extends StatelessWidget {
  const LocationTile({
    super.key,
    required this.location,
    required this.onTap,
    this.trailing,
  });

  final SavedLocation location;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${location.label}. ${location.subtitle ?? ''}',
      child: Material(
        color: EGoColors.surface,
        borderRadius: BorderRadius.circular(EGoSpacing.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(EGoSpacing.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: EGoSpacing.md,
              vertical: EGoSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(EGoSpacing.sm),
                  decoration: BoxDecoration(
                    color: EGoColors.brandPrimaryLight,
                    borderRadius: BorderRadius.circular(
                      EGoSpacing.radiusMedium,
                    ),
                  ),
                  child: Icon(
                    location.icon ?? iconForPlaceType(location.type),
                    color: EGoColors.brandNavy,
                    size: EGoSpacing.iconSmall,
                  ),
                ),
                const SizedBox(width: EGoSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        location.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: EGoTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (location.subtitle != null &&
                          location.subtitle!.isNotEmpty) ...[
                        const SizedBox(height: EGoSpacing.xs / 2),
                        Text(
                          location.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: EGoTypography.bodySmall.copyWith(
                            color: EGoColors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: EGoSpacing.sm),
                trailing ??
                    const Icon(
                      Icons.chevron_right,
                      color: EGoColors.grey400,
                      size: EGoSpacing.iconMedium,
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
