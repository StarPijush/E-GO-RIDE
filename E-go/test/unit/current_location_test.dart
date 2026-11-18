import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/app/app_state.dart';
import 'package:e_go/features/location/data/current_location_service.dart';

class _AvailableCurrentLocationService implements CurrentLocationService {
  const _AvailableCurrentLocationService(this.coordinate);

  final LatLng coordinate;

  @override
  Future<CurrentLocationResult> getCurrentLocation() async =>
      CurrentLocationResult.available(coordinate, accuracy: 12);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('default service reports unavailable and returns no coordinate', () async {
    const service = UnavailableCurrentLocationService();

    final result = await service.getCurrentLocation();

    expect(result.isAvailable, isFalse);
    expect(result.coordinate, isNull);
    expect(result.message, isNotEmpty);
  });

  test('unavailable location never writes a pickup', () async {
    final state = AppState();

    await state.refreshCurrentLocation();

    expect(state.currentLocation.coordinate, isNull);
    expect(state.currentLocation.error, isNotNull);
    expect(state.pickupLocation, isNull);
  });

  test('available location updates the map state but not the pickup', () async {
    const coordinate = LatLng(22.4550, 86.9020);
    final state = AppState(
      currentLocationService: const _AvailableCurrentLocationService(coordinate),
    );

    await state.refreshCurrentLocation();

    expect(state.currentLocation.coordinate, coordinate);
    expect(state.currentLocation.error, isNull);
    expect(state.pickupLocation, isNull);
    expect(state.hasConfirmedRoute, isFalse);
  });
}
