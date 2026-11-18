import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import 'package:e_go/app/theme/index.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/shared/widgets/location_components.dart';

/// Read-only route map for the Place Order screen.
///
/// There is deliberately no polyline: the app has no road-route data.
class PlaceOrderMapSummary extends StatelessWidget {
  const PlaceOrderMapSummary({
    super.key,
    required this.pickup,
    required this.destination,
    this.tileProvider,
  });

  final SavedLocation pickup;
  final SavedLocation destination;
  final TileProvider? tileProvider;

  @override
  Widget build(BuildContext context) {
    final routeKey = ValueKey(
      '${pickup.coordinate.latitude.toStringAsFixed(5)}-'
      '${pickup.coordinate.longitude.toStringAsFixed(5)}-'
      '${destination.coordinate.latitude.toStringAsFixed(5)}-'
      '${destination.coordinate.longitude.toStringAsFixed(5)}',
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(EGoSpacing.radiusXLarge),
      child: SizedBox(
        height: 180,
        child: Stack(
          children: [
            Container(color: EGoColors.surfaceVariant),
            FlutterMap(
              key: routeKey,
              options: MapOptions(
                initialCameraFit: CameraFit.coordinates(
                  coordinates: [pickup.coordinate, destination.coordinate],
                  padding: const EdgeInsets.fromLTRB(
                    EGoSpacing.xxxl,
                    EGoSpacing.xxxl,
                    EGoSpacing.xxxl,
                    72,
                  ),
                  maxZoom: 17,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ego.customer',
                  tileProvider: tileProvider,
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: pickup.coordinate,
                      width: 44,
                      height: 44,
                      child: const EGoPickupMarker(size: 34),
                    ),
                    Marker(
                      point: destination.coordinate,
                      width: 44,
                      height: 44,
                      child: const EGoDestinationMarker(size: 38),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              left: EGoSpacing.sm,
              right: EGoSpacing.sm,
              bottom: EGoSpacing.sm,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: EGoSpacing.md,
                  vertical: EGoSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: EGoColors.surface.withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(EGoSpacing.radiusMedium),
                  border: Border.all(color: EGoColors.outlineVariant),
                ),
                child: Text(
                  'Route preview unavailable. Showing pickup and destination '
                  'markers.',
                  style: EGoTypography.bodySmall.copyWith(
                    color: EGoColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
