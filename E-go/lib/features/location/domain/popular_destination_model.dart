import 'package:latlong2/latlong.dart';

import 'package:e_go/features/location/domain/location_model.dart';

/// Structured domain model for curated popular destinations on the Home screen.
class PopularDestinationModel {
  const PopularDestinationModel({
    required this.id,
    required this.displayName,
    required this.fullAddress,
    required this.coordinate,
    required this.imageAsset,
    this.category = PlaceType.landmark,
  });

  /// Stable unique identifier matching the mock places catalog.
  final String id;

  /// Reference-accurate display name.
  final String displayName;

  /// Full locality / address for subtitle display.
  final String fullAddress;

  /// Verified geographic coordinate in Jhargram.
  final LatLng coordinate;

  /// Bundled local asset reference.
  final String imageAsset;

  /// Category place type for icon fallbacks and booking classification.
  final PlaceType category;

  /// Converts this curated popular destination into a [SavedLocation]
  /// consumable by the shared E-GO booking state machine.
  SavedLocation toSavedLocation() {
    return SavedLocation(
      id: id,
      label: displayName,
      subtitle: fullAddress,
      coordinate: coordinate,
      icon: iconForPlaceType(category),
      type: category,
    );
  }

  /// Exactly the four reference destinations required by the design reference:
  /// 1. Jhargram Palace
  /// 2. Jhargram Station
  /// 3. Central Bus Stand
  /// 4. Kanak Durga Temple
  static const List<PopularDestinationModel> defaultPopular = [
    PopularDestinationModel(
      id: 's3',
      displayName: 'Jhargram Palace',
      fullAddress: 'Palace Road, Jhargram',
      coordinate: LatLng(22.4480, 86.8950),
      imageAsset: 'assets/destinations/jhargram_palace.jpg',
      category: PlaceType.landmark,
    ),
    PopularDestinationModel(
      id: 's2',
      displayName: 'Jhargram Station',
      fullAddress: 'Station Road, Jhargram',
      coordinate: LatLng(22.4529, 86.9003),
      imageAsset: 'assets/destinations/jhargram_station.jpg',
      category: PlaceType.transport,
    ),
    PopularDestinationModel(
      id: 's6',
      displayName: 'Central Bus Stand',
      fullAddress: 'Bus Stand Road, Jhargram',
      coordinate: LatLng(22.4580, 86.9050),
      imageAsset: 'assets/destinations/central_bus_stand.jpg',
      category: PlaceType.transport,
    ),
    PopularDestinationModel(
      id: 's13',
      displayName: 'Kanak Durga Temple',
      fullAddress: 'Chilkigarh, Jhargram',
      coordinate: LatLng(22.4633, 86.8122),
      imageAsset: 'assets/destinations/kanak_durga_temple.jpg',
      category: PlaceType.landmark,
    ),
  ];
}
