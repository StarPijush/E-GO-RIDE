import 'package:flutter/material.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/presentation/widgets/route_marker_column.dart';

/// Pixel-accurate Pickup and Destination Routing Card matching Reference Sets A & B.
class LocationRouteCard extends StatelessWidget {
  const LocationRouteCard({
    super.key,
    required this.pickupLocation,
    required this.destinationLocation,
    required this.onPickupTap,
    required this.onDestinationTap,
    this.pickupError,
    this.destinationError,
  });

  final SavedLocation? pickupLocation;
  final SavedLocation? destinationLocation;
  final VoidCallback onPickupTap;
  final VoidCallback onDestinationTap;
  final String? pickupError;
  final String? destinationError;

  @override
  Widget build(BuildContext context) {
    const navyColor = Color(0xFF142B45);
    const slateColor = Color(0xFF778397);
    const dividerColor = Color(0xFFECEEF1);
    const buttonBg = Color(0xFFF2F4F7);

    final hasDestination = destinationLocation != null;

    final pickupTitle = pickupLocation?.label ?? 'Choose pickup location';
    final pickupSubtitle = pickupLocation?.subtitle ??
        (pickupLocation != null ? 'Jhargram area' : 'Tap to select pickup point');

    final destinationTitle =
        hasDestination ? destinationLocation!.label : 'Where are you going?';
    final destinationSubtitle = destinationLocation?.subtitle ?? '';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A142B45),
            blurRadius: 20.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed-width coaxial route marker column
            const RouteMarkerColumn(),
            const SizedBox(width: 12.0),
            // Location text rows & action buttons
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                // ── Pickup Row ──
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onPickupTap,
                    borderRadius: BorderRadius.circular(10.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  'PICKUP',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: slateColor,
                                    letterSpacing: 0.8,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  pickupTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w700,
                                    color: pickupLocation == null
                                        ? slateColor
                                        : navyColor,
                                    height: 1.25,
                                  ),
                                ),
                                if (pickupSubtitle.isNotEmpty) ...[
                                  const SizedBox(height: 1.0),
                                  Text(
                                    pickupSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w400,
                                      color: slateColor,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                                if (pickupError != null) ...[
                                  const SizedBox(height: 2.0),
                                  Text(
                                    pickupError!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.0,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // Edit button
                          Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: const BoxDecoration(
                              color: buttonBg,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18.0,
                              icon: const Icon(Icons.edit_outlined),
                              color: navyColor,
                              tooltip: 'Edit pickup location',
                              onPressed: onPickupTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Hairline Divider
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: Divider(
                    height: 1.0,
                    thickness: 1.0,
                    color: dividerColor,
                  ),
                ),

                // ── Destination Row ──
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDestinationTap,
                    borderRadius: BorderRadius.circular(10.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DESTINATION',
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: hasDestination
                                        ? const Color(0xFF765A00)
                                        : slateColor,
                                    letterSpacing: 0.8,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  destinationTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 16.0,
                                    fontWeight: hasDestination
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: hasDestination
                                        ? navyColor
                                        : const Color(0xFF191C1E),
                                    height: 1.25,
                                  ),
                                ),
                                if (hasDestination &&
                                    destinationSubtitle.isNotEmpty) ...[
                                  const SizedBox(height: 1.0),
                                  Text(
                                    destinationSubtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w400,
                                      color: slateColor,
                                      height: 1.25,
                                    ),
                                  ),
                                ],
                                if (destinationError != null) ...[
                                  const SizedBox(height: 2.0),
                                  Text(
                                    destinationError!,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 11.0,
                                      color: Color(0xFFDC2626),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8.0),
                          // Action button (search when empty, swap/change when populated)
                          Container(
                            width: 36.0,
                            height: 36.0,
                            decoration: const BoxDecoration(
                              color: buttonBg,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              iconSize: 18.0,
                              icon: Icon(
                                hasDestination
                                    ? Icons.swap_vert
                                    : Icons.search,
                              ),
                              color: hasDestination ? navyColor : slateColor,
                              tooltip: hasDestination
                                  ? 'Change destination'
                                  : 'Search destination',
                              onPressed: onDestinationTap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  }
}
