import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:e_go/core/mock_pricing.dart';
import '../../domain/models/route_result.dart';
import '../../domain/services/route_service.dart';

/// OSRM-based routing service for live road routing.
/// Cross-platform: fully compatible with Android, iOS, and Flutter Web.
class OsrmRouteService implements RouteService {
  OsrmRouteService({
    this.baseUrl = 'https://router.project-osrm.org',
    this.timeout = const Duration(seconds: 4),
    http.Client? client,
  }) : _client = client ?? http.Client(),
       _ownsClient = client == null;

  final String baseUrl;
  final Duration timeout;
  final http.Client _client;
  final bool _ownsClient;

  /// Closes the HTTP client if it was created internally.
  void dispose() {
    if (_ownsClient) {
      _client.close();
    }
  }

  @override
  Future<RouteResult> calculateRoute({
    required LatLng pickup,
    required LatLng destination,
    VehicleType? vehicleType,
  }) async {
    final profile = vehicleType == VehicleType.bike ? 'bike' : 'driving';
    final url = Uri.parse(
      '$baseUrl/route/v1/$profile/'
      '${pickup.longitude.toStringAsFixed(6)},${pickup.latitude.toStringAsFixed(6)};'
      '${destination.longitude.toStringAsFixed(6)},${destination.latitude.toStringAsFixed(6)}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'E-GO-Urban-Mobility/1.0 (Customer App)',
        },
      ).timeout(timeout);

      if (response.statusCode != 200) {
        throw http.ClientException(
          'OSRM responded with status ${response.statusCode}',
          url,
        );
      }

      final body = response.body;
      final data = jsonDecode(body) as Map<String, dynamic>;

      if (data['code'] != 'Ok' || (data['routes'] as List).isEmpty) {
        throw const FormatException('No route found in OSRM response');
      }

      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).round();
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coordinates = geometry['coordinates'] as List;

      final points = coordinates.map<LatLng>((coord) {
        final pair = coord as List;
        return LatLng(
          (pair[1] as num).toDouble(),
          (pair[0] as num).toDouble(),
        );
      }).toList();

      if (points.isEmpty) {
        throw const FormatException('Empty coordinates in route');
      }

      return RouteResult(
        geometry: points,
        distanceMeters: distance,
        durationSeconds: duration,
        bounds: LatLngBounds.fromPoints(points),
        isSuccess: true,
        providerName: 'OSRM ($profile)',
        timestamp: DateTime.now(),
        isFromCache: false,
      );
    } catch (e) {
      // Re-throw so caller/fallback service can handle seamlessly
      rethrow;
    }
  }
}
