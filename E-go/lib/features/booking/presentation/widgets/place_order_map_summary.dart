import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/routing/domain/models/route_result.dart';
import 'review_map_markers.dart';

/// Real interactive geographic route map for Review Your Ride screen.
///
/// Features:
/// - Real OpenStreetMap raster/vector tiles
/// - Real road-following polyline with navy (#142B45) stroke and yellow (#FFC928) underlay
/// - Verified pickup and destination custom beacon pins with callout labels
/// - Floating distance & duration pill overlay ('3.2 km · 12–15 min')
/// - Visible map attribution complying with provider guidelines
/// - Auto-fitting camera bounds with responsive bottom sheet clearance padding
class PlaceOrderMapSummary extends StatefulWidget {
  const PlaceOrderMapSummary({
    super.key,
    required this.pickup,
    required this.destination,
    this.route,
    this.isRouteLoading = false,
    this.onRetryRoute,
    this.tileProvider,
    this.height,
    this.bottomPadding = 380.0,
    this.mapController,
  });

  final SavedLocation pickup;
  final SavedLocation destination;
  final RouteResult? route;
  final bool isRouteLoading;
  final VoidCallback? onRetryRoute;
  final TileProvider? tileProvider;
  final double? height;
  final double bottomPadding;
  final MapController? mapController;

  @override
  State<PlaceOrderMapSummary> createState() => _PlaceOrderMapSummaryState();
}

class _PlaceOrderMapSummaryState extends State<PlaceOrderMapSummary> {
  late final MapController _effectiveMapController;

  @override
  void initState() {
    super.initState();
    _effectiveMapController = widget.mapController ?? MapController();
  }

  LatLngBounds _computeBounds() {
    final route = widget.route;
    if (route != null && route.isSuccess && route.geometry.isNotEmpty) {
      return route.bounds;
    }
    return LatLngBounds.fromPoints([
      widget.pickup.coordinate,
      widget.destination.coordinate,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.route;
    final hasRouteGeometry =
        route != null && route.isSuccess && route.geometry.isNotEmpty;
    final routePoints = hasRouteGeometry ? route.geometry : <LatLng>[];
    final bounds = _computeBounds();

    final routeKey = ValueKey(
      '${widget.pickup.coordinate.latitude.toStringAsFixed(4)}-'
      '${widget.pickup.coordinate.longitude.toStringAsFixed(4)}-'
      '${widget.destination.coordinate.latitude.toStringAsFixed(4)}-'
      '${widget.destination.coordinate.longitude.toStringAsFixed(4)}-'
      '${route?.geometry.length ?? 0}',
    );

    final mapWidget = Container(
      width: double.infinity,
      height: widget.height,
      color: const Color(0xFFEAF0F6),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base Interactive Map
          FlutterMap(
            key: routeKey,
            mapController: _effectiveMapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: bounds,
                padding: EdgeInsets.fromLTRB(40, 72, 40, widget.bottomPadding),
                maxZoom: 17,
              ),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                    InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom,
              ),
            ),
            children: [
              // 1. OpenStreetMap Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ego.customer',
                tileProvider: widget.tileProvider,
                maxNativeZoom: 19,
                subdomains: const ['a', 'b', 'c'],
              ),

              // 2. Real Road Polyline Layer (Yellow Underlay + Deep Navy Foreground)
              if (hasRouteGeometry)
                PolylineLayer(
                  polylines: [
                    // Warm yellow underlay for high contrast against town roads
                    Polyline(
                      points: routePoints,
                      strokeWidth: 7.0,
                      color: const Color(0xFFFFC928).withValues(alpha: 0.45),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                    // Deep navy official E-GO route stroke (#142B45)
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4.5,
                      color: const Color(0xFF142B45),
                      strokeCap: StrokeCap.round,
                      strokeJoin: StrokeJoin.round,
                    ),
                  ],
                ),

              // 3. Pickup and Destination Markers
              MarkerLayer(
                markers: [
                  // Pickup Marker
                  Marker(
                    point: widget.pickup.coordinate,
                    width: 140,
                    height: 64,
                    alignment: Alignment.bottomCenter,
                    child: ReviewPickupMarker(
                      label: widget.pickup.label.isNotEmpty
                          ? widget.pickup.label
                          : 'PICKUP',
                    ),
                  ),
                  // Destination Marker
                  Marker(
                    point: widget.destination.coordinate,
                    width: 140,
                    height: 64,
                    alignment: Alignment.bottomCenter,
                    child: ReviewDestinationMarker(
                      label: widget.destination.label.isNotEmpty
                          ? widget.destination.label
                          : 'DESTINATION',
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Floating Distance & Estimated Time Pill (bottom-left above sheet)
          Positioned(
            left: 16,
            bottom: widget.bottomPadding + 14,
            child: _DistanceDurationPill(
              route: route,
              isLoading: widget.isRouteLoading,
              onRetry: widget.onRetryRoute,
            ),
          ),

          // OSM Map Attribution (bottom-right above sheet)
          Positioned(
            right: 8,
            bottom: widget.bottomPadding + 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '© OpenStreetMap contributors',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 8.5,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return mapWidget;
  }
}

/// Floating pill overlay displaying distance and travel time.
class _DistanceDurationPill extends StatelessWidget {
  const _DistanceDurationPill({
    required this.route,
    required this.isLoading,
    this.onRetry,
  });

  final RouteResult? route;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9999),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF142B45).withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF142B45)),
              ),
            ),
            SizedBox(width: 8),
            Text(
              'Routing...',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF142B45),
              ),
            ),
          ],
        ),
      );
    }

    if (route == null || !route!.isSuccess) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF142B45).withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF10B981),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            '${route!.formattedDistance} · ${route!.formattedDuration}',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF142B45),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}
