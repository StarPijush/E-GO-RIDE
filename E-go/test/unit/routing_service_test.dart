import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:e_go/core/mock_pricing.dart';
import 'package:e_go/features/routing/data/services/caching_route_service.dart';
import 'package:e_go/features/routing/data/services/jhargram_road_network_service.dart';
import 'package:e_go/features/routing/data/services/osrm_route_service.dart';

class _MockHttpClient extends http.BaseClient {
  _MockHttpClient(this._handler);

  final Future<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(utf8.encode(response.body)),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
    );
  }
}

void main() {
  group('Jhargram Road Network Routing Engine', () {
    const roadService = JhargramRoadNetworkService();

    test('Jhargram Bazar to Jhargram Palace follows real road network (~3.2 km, 12-15 min)', () async {
      const pickup = LatLng(22.4701, 86.9152);
      const destination = LatLng(22.4480, 86.8950);

      final result = await roadService.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.toto,
      );

      expect(result.isSuccess, isTrue);
      expect(result.geometry.length, greaterThanOrEqualTo(10));
      // Real road geometry: not a straight line (more than 2 points)
      expect(result.geometry.first, pickup);
      expect(result.geometry.last, destination);

      // Distance is ~3.2 km
      expect(result.distanceKm, closeTo(3.2, 0.15));
      expect(result.formattedDistance, '3.2 km');

      // Duration is 12–15 min (780s = 13 min)
      expect(result.durationMinutes, inInclusiveRange(12, 15));
      expect(result.formattedDuration, anyOf('12–15 min', '11–15 min', '12–14 min'));

      // Bounds enclose both endpoints
      expect(result.bounds.contains(pickup), isTrue);
      expect(result.bounds.contains(destination), isTrue);
    });

    test('Jhargram Station to Bazar follows station road corridor (~2.4 km)', () async {
      const pickup = LatLng(22.4529, 86.9003);
      const destination = LatLng(22.4701, 86.9152);

      final result = await roadService.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.toto,
      );

      expect(result.isSuccess, isTrue);
      expect(result.geometry.length, greaterThanOrEqualTo(8));
      expect(result.distanceKm, closeTo(2.4, 0.2));
      expect(result.formattedDistance, '2.4 km');
    });

    test('Jhargram Station to Palace follows palace road corridor (~1.1 km)', () async {
      const pickup = LatLng(22.4529, 86.9003);
      const destination = LatLng(22.4480, 86.8950);

      final result = await roadService.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.bike,
      );

      expect(result.isSuccess, isTrue);
      expect(result.distanceKm, closeTo(1.1, 0.2));
    });

    test('Fails safely when pickup and destination are identical', () async {
      const same = LatLng(22.4529, 86.9003);

      final result = await roadService.calculateRoute(
        pickup: same,
        destination: same,
      );

      expect(result.isSuccess, isFalse);
      expect(result.errorMessage, contains('identical'));
    });
  });

  group('Composite & Caching Route Service', () {
    late CompositeRouteService compositeService;

    setUp(() {
      compositeService = CompositeRouteService(
        fallbackService: const JhargramRoadNetworkService(),
      );
    });

    test('Caches calculated route in memory and returns isFromCache true on second request', () async {
      const pickup = LatLng(22.4701, 86.9152);
      const destination = LatLng(22.4480, 86.8950);

      final first = await compositeService.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.toto,
      );
      expect(first.isSuccess, isTrue);
      expect(first.isFromCache, isFalse);

      final second = await compositeService.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.toto,
      );
      expect(second.isSuccess, isTrue);
      expect(second.isFromCache, isTrue);
      expect(second.distanceMeters, first.distanceMeters);
      expect(second.durationSeconds, first.durationSeconds);
      expect(second.geometry.length, first.geometry.length);
    });

    test('Deduplicates simultaneous identical in-flight route requests', () async {
      const pickup = LatLng(22.4529, 86.9003);
      const destination = LatLng(22.4701, 86.9152);

      final future1 = compositeService.calculateRoute(
        pickup: pickup,
        destination: destination,
      );
      final future2 = compositeService.calculateRoute(
        pickup: pickup,
        destination: destination,
      );

      final results = await Future.wait([future1, future2]);
      expect(results[0].isSuccess, isTrue);
      expect(results[1].isSuccess, isTrue);
      expect(results[0].distanceMeters, results[1].distanceMeters);
    });
  });

  group('OSRM Cross-Platform Route Service', () {
    const pickup = LatLng(22.4701, 86.9152);
    const destination = LatLng(22.4480, 86.8950);

    const validOsrmJson = '''
{
  "code": "Ok",
  "routes": [
    {
      "geometry": {
        "coordinates": [
          [86.9152, 22.4701],
          [86.9120, 22.4650],
          [86.9050, 22.4550],
          [86.8950, 22.4480]
        ],
        "type": "LineString"
      },
      "legs": [],
      "weight_name": "routability",
      "weight": 800,
      "duration": 780.0,
      "distance": 3200.0
    }
  ],
  "waypoints": []
}
''';

    test('successfully calculates route from valid OSRM response', () async {
      final client = _MockHttpClient((request) async {
        expect(request.url.toString(), contains('/route/v1/driving/'));
        expect(request.headers['User-Agent'], contains('E-GO-Urban-Mobility'));
        return http.Response(validOsrmJson, 200);
      });

      final service = OsrmRouteService(client: client);
      final result = await service.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.toto,
      );

      expect(result.isSuccess, isTrue);
      expect(result.distanceMeters, 3200.0);
      expect(result.durationSeconds, 780);
      expect(result.geometry.length, 4);
      expect(result.geometry.first, pickup);
      expect(result.geometry.last, destination);
      expect(result.providerName, 'OSRM (driving)');
      service.dispose();
    });

    test('selects bike profile for bike vehicle type', () async {
      String? requestedUrl;
      final client = _MockHttpClient((request) async {
        requestedUrl = request.url.toString();
        return http.Response(validOsrmJson, 200);
      });

      final service = OsrmRouteService(client: client);
      await service.calculateRoute(
        pickup: pickup,
        destination: destination,
        vehicleType: VehicleType.bike,
      );

      expect(requestedUrl, contains('/route/v1/bike/'));
      service.dispose();
    });

    test('throws ClientException on HTTP non-200 status', () async {
      final client = _MockHttpClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final service = OsrmRouteService(client: client);
      expect(
        () => service.calculateRoute(pickup: pickup, destination: destination),
        throwsA(isA<http.ClientException>()),
      );
      service.dispose();
    });

    test('throws TimeoutException when request exceeds timeout duration', () async {
      final client = _MockHttpClient((request) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return http.Response(validOsrmJson, 200);
      });

      final service = OsrmRouteService(
        client: client,
        timeout: const Duration(milliseconds: 10),
      );

      expect(
        () => service.calculateRoute(pickup: pickup, destination: destination),
        throwsA(isA<TimeoutException>()),
      );
      service.dispose();
    });

    test('throws FormatException when response code is not Ok or routes is empty', () async {
      final client = _MockHttpClient((request) async {
        return http.Response(jsonEncode({'code': 'NoRoute', 'routes': []}), 200);
      });

      final service = OsrmRouteService(client: client);
      expect(
        () => service.calculateRoute(pickup: pickup, destination: destination),
        throwsA(isA<FormatException>()),
      );
      service.dispose();
    });

    test('throws FormatException when coordinates array is empty', () async {
      final emptyCoordsJson = jsonEncode({
        'code': 'Ok',
        'routes': [
          {
            'geometry': {'coordinates': []},
            'distance': 0.0,
            'duration': 0.0,
          }
        ],
      });

      final client = _MockHttpClient((request) async {
        return http.Response(emptyCoordsJson, 200);
      });

      final service = OsrmRouteService(client: client);
      expect(
        () => service.calculateRoute(pickup: pickup, destination: destination),
        throwsA(isA<FormatException>()),
      );
      service.dispose();
    });

    test('network exception during request is rethrown for fallback handling', () async {
      final client = _MockHttpClient((request) async {
        throw http.ClientException('Connection refused', request.url);
      });

      final service = OsrmRouteService(client: client);
      expect(
        () => service.calculateRoute(pickup: pickup, destination: destination),
        throwsA(isA<http.ClientException>()),
      );
      service.dispose();
    });
  });
}
