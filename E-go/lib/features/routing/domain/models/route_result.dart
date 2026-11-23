import 'package:flutter/foundation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Represents the calculated road route between pickup and destination.
@immutable
class RouteResult {
  const RouteResult({
    required this.geometry,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.bounds,
    required this.isSuccess,
    this.errorMessage,
    required this.providerName,
    required this.timestamp,
    this.isFromCache = false,
  });

  /// Factory for a failed or unavailable route calculation.
  factory RouteResult.failed({
    required String errorMessage,
    required LatLng pickup,
    required LatLng destination,
    String providerName = 'Unavailable',
  }) {
    return RouteResult(
      geometry: [pickup, destination],
      distanceMeters: 0,
      durationSeconds: 0,
      bounds: LatLngBounds.fromPoints([pickup, destination]),
      isSuccess: false,
      errorMessage: errorMessage,
      providerName: providerName,
      timestamp: DateTime.now(),
      isFromCache: false,
    );
  }

  /// Factory for empty/initial state.
  static RouteResult empty() => RouteResult(
    geometry: const [],
    distanceMeters: 0,
    durationSeconds: 0,
    bounds: LatLngBounds(const LatLng(0, 0), const LatLng(0, 0)),
    isSuccess: false,
    errorMessage: null,
    providerName: 'None',
    timestamp: DateTime.fromMillisecondsSinceEpoch(0),
    isFromCache: false,
  );

  /// Points representing the road polyline.
  final List<LatLng> geometry;

  /// Road distance in meters.
  final double distanceMeters;

  /// Estimated duration in seconds.
  final int durationSeconds;

  /// Geographic bounds enclosing the route geometry and waypoints.
  final LatLngBounds bounds;

  /// True if routing succeeded and valid road geometry is present.
  final bool isSuccess;

  /// Error message when route generation failed.
  final String? errorMessage;

  /// The provider that generated this route (e.g. OSRM, RoadNetwork, Cached).
  final String providerName;

  /// Time when this route was computed.
  final DateTime timestamp;

  /// Whether this result was served from an in-memory cache.
  final bool isFromCache;

  /// Distance in kilometers.
  double get distanceKm => distanceMeters / 1000.0;

  /// Estimated duration in whole minutes.
  int get durationMinutes => (durationSeconds / 60).round();

  /// Formatted distance string (e.g., '3.2 km').
  String get formattedDistance {
    if (!isSuccess || distanceMeters <= 0) return '-- km';
    if (distanceKm < 1.0) {
      return '${(distanceKm * 1000).round()} m';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  /// Formatted travel duration string (e.g., '12–15 min').
  String get formattedDuration {
    if (!isSuccess || durationSeconds <= 0) return '-- min';
    final mins = durationMinutes;
    if (mins <= 1) return '1–2 min';
    final lower = (mins * 0.9).floor();
    final upper = (mins * 1.15).ceil();
    if (lower == upper) return '$mins min';
    return '$lower–$upper min';
  }
}
