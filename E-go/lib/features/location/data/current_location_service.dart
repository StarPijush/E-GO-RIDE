// Current-location access for the customer app.
//
// There is no geolocation package in this build. The default service reports
// that current location is unavailable and never invents a coordinate. A real
// implementation can replace it without changing the booking flow.

import 'package:latlong2/latlong.dart';

enum CurrentLocationStatus { available, unavailable, permissionDenied, error }

class CurrentLocationResult {
  const CurrentLocationResult._({
    required this.status,
    this.coordinate,
    this.accuracy,
    this.message,
  });

  const CurrentLocationResult.available(
    LatLng coordinate, {
    double? accuracy,
  }) : this._(
         status: CurrentLocationStatus.available,
         coordinate: coordinate,
         accuracy: accuracy,
       );

  const CurrentLocationResult.unavailable([
    String message =
        'Current location is not available. Choose your pickup manually.',
  ]) : this._(
         status: CurrentLocationStatus.unavailable,
         message: message,
       );

  const CurrentLocationResult.permissionDenied([
    String message =
        'Location permission was denied. Choose your pickup manually.',
  ]) : this._(
         status: CurrentLocationStatus.permissionDenied,
         message: message,
       );

  const CurrentLocationResult.error([
    String message = 'Could not get your current location. Try again.',
  ]) : this._(
         status: CurrentLocationStatus.error,
         message: message,
       );

  final CurrentLocationStatus status;
  final LatLng? coordinate;
  final double? accuracy;
  final String? message;

  bool get isAvailable =>
      status == CurrentLocationStatus.available && coordinate != null;
}

abstract class CurrentLocationService {
  Future<CurrentLocationResult> getCurrentLocation();
}

class UnavailableCurrentLocationService implements CurrentLocationService {
  const UnavailableCurrentLocationService();

  @override
  Future<CurrentLocationResult> getCurrentLocation() async =>
      const CurrentLocationResult.unavailable();
}
