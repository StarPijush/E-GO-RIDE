// Popular destinations sourced from the curated Jhargram place dataset.
// No coordinates or places are invented here.

import 'package:e_go/features/location/domain/location_model.dart';
import 'package:e_go/features/location/domain/popular_destination_model.dart';
import 'package:e_go/mock_data/mock_data.dart';

abstract class PopularDestinations {
  /// Exactly the four reference IDs in reference order:
  /// 1. s3: Jhargram Palace
  /// 2. s2: Jhargram Station
  /// 3. s6: Central Bus Stand
  /// 4. s13: Kanak Durga Temple
  static const List<String> ids = ['s3', 's2', 's6', 's13'];
  static const int maxItems = 4;

  /// Display name overrides matching the master design reference.
  static const Map<String, String> displayNames = {
    's3': 'Jhargram Palace',
    's2': 'Jhargram Station',
    's6': 'Central Bus Stand',
    's13': 'Kanak Durga Temple',
  };

  /// Resolves the curated popular places as [PopularDestinationModel]s.
  static List<PopularDestinationModel> resolveModels() {
    return PopularDestinationModel.defaultPopular;
  }

  /// Resolves the curated popular places from [places] as [SavedLocation]s.
  ///
  /// Missing ids are skipped; the result never exceeds [maxItems].
  static List<SavedLocation> resolve({
    List<SuggestedPlace>? places,
  }) {
    final source = places ?? MockData.suggestedPlaces;
    final resolved = <SavedLocation>[];

    for (final id in ids) {
      for (final place in source) {
        if (place.id != id) continue;
        final label = displayNames[id] ?? place.name;
        resolved.add(
          SavedLocation(
            id: place.id,
            label: label,
            subtitle: place.address,
            coordinate: place.coordinate,
            icon: iconForPlaceType(place.type),
            type: place.type,
          ),
        );
        break;
      }
      if (resolved.length == maxItems) break;
    }

    return resolved;
  }
}
