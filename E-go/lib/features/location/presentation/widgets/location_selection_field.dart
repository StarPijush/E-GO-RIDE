import 'package:flutter/material.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/location_selection_target.dart';

/// Tappable pickup/drop field used by the location selection step.
class LocationSelectionField extends StatelessWidget {
  const LocationSelectionField({
    super.key,
    required this.target,
    required this.location,
    required this.onTap,
    required this.onMapTap,
    this.errorText,
  });

  final LocationSelectionTarget target;
  final SavedLocation? location;
  final VoidCallback onTap;
  final VoidCallback onMapTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final value = location?.label;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          button: true,
          label: '${target.fieldLabel}: ${value ?? target.hint}',
          child: Material(
            color: EGoColors.surface,
            borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
              child: Container(
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.fromLTRB(
                  EGoSpacing.lg,
                  EGoSpacing.md,
                  EGoSpacing.xs,
                  EGoSpacing.md,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
                  border: Border.all(
                    color: hasError ? EGoColors.error : EGoColors.outline,
                    width: hasError
                        ? EGoSpacing.focusBorderWidth
                        : EGoSpacing.borderWidth,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      target.leadingIcon,
                      color: hasError
                          ? EGoColors.error
                          : EGoColors.onSurfaceMuted,
                      size: EGoSpacing.iconMedium,
                    ),
                    const SizedBox(width: EGoSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            target.fieldLabel,
                            style: EGoTypography.labelSmall.copyWith(
                              color: EGoColors.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: EGoSpacing.xs / 2),
                          Text(
                            value ?? target.hint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: EGoTypography.bodyLarge.copyWith(
                              color: value == null
                                  ? EGoColors.onSurfaceVariant
                                  : EGoColors.onSurface,
                              fontWeight: value == null
                                  ? FontWeight.w400
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onMapTap,
                      tooltip: target.mapAction,
                      icon: const Icon(Icons.map_outlined),
                      color: EGoColors.onSurface,
                      iconSize: EGoSpacing.iconMedium,
                      constraints: const BoxConstraints(
                        minWidth: 48,
                        minHeight: 48,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: EGoSpacing.xs),
          Padding(
            padding: const EdgeInsets.only(left: EGoSpacing.lg),
            child: Text(
              errorText!,
              style: EGoTypography.bodySmall.copyWith(color: EGoColors.error),
            ),
          ),
        ],
      ],
    );
  }
}
