import 'package:flutter_test/flutter_test.dart';

import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/features/location/data/popular_destinations.dart';
import 'package:e_go/mock_data/mock_data.dart';

void main() {
  test('resolves exactly the four reference Jhargram places', () {
    final places = PopularDestinations.resolve();

    expect(places.length, 4);
    expect(
      places.map((place) => place.id).toSet(),
      {'s3', 's2', 's6', 's13'},
    );
    expect(
      places.map((place) => place.label).toList(),
      equals([
        'Jhargram Palace',
        'Jhargram Station',
        'Central Bus Stand',
        'Kanak Durga Temple',
      ]),
    );
    for (final place in places) {
      expect(isValidCoordinate(place.coordinate), isTrue);
      expect(place.subtitle, isNotEmpty);
    }
  });

  test('resolves structured PopularDestinationModels with bundled assets', () {
    final models = PopularDestinations.resolveModels();

    expect(models.length, 4);
    expect(models.map((m) => m.displayName).toList(), [
      'Jhargram Palace',
      'Jhargram Station',
      'Central Bus Stand',
      'Kanak Durga Temple',
    ]);
    for (final model in models) {
      expect(model.imageAsset, startsWith('assets/destinations/'));
      expect(model.fullAddress, isNotEmpty);
      expect(isValidCoordinate(model.coordinate), isTrue);

      final saved = model.toSavedLocation();
      expect(saved.id, model.id);
      expect(saved.label, model.displayName);
      expect(saved.coordinate, model.coordinate);
    }
  });

  test('never invents places that are missing from the dataset', () {
    final places = PopularDestinations.resolve(
      places: MockData.suggestedPlaces
          .where((place) => place.id == 's3')
          .toList(),
    );

    expect(places.length, 1);
    expect(places.first.id, 's3');
    expect(places.first.label, 'Jhargram Palace');
  });
}
