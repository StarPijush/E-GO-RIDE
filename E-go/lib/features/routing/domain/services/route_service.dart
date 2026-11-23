import 'package:latlong2/latlong.dart';
import 'package:e_go/core/mock_pricing.dart';
import '../models/route_result.dart';

/// Contract for calculating road-following routes.
abstract class RouteService {
  /// Computes a road-following route from [pickup] to [destination].
  ///
  /// Optionally considers [vehicleType] if the provider supports vehicle-specific
  /// profiles.
  Future<RouteResult> calculateRoute({
    required LatLng pickup,
    required LatLng destination,
    VehicleType? vehicleType,
  });
}
