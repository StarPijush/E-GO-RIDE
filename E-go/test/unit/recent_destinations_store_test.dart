import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/features/location/data/recent_destinations_store.dart';
import 'package:e_go/features/location/domain/location_model.dart';

SavedLocation _place(
  String id, {
  String label = 'Place',
  double lat = 22.45,
  double lng = 86.90,
  PlaceType type = PlaceType.other,
}) {
  return SavedLocation(
    id: id,
    label: label,
    subtitle: 'Jhargram',
    coordinate: LatLng(lat, lng),
    type: type,
  );
}

Future<RecentDestinationsStore> _store() async {
  final prefs = await SharedPreferences.getInstance();
  return RecentDestinationsStore(preferences: prefs);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('starts empty with no fake history', () async {
    final store = await _store();

    expect(await store.load(), isEmpty);
    expect(await store.latest(), isNull);
  });

  test('records destinations newest-first', () async {
    final store = await _store();

    await store.record(_place('a', label: 'First', lat: 22.45));
    await store.record(_place('b', label: 'Second', lat: 22.46));

    final loaded = await store.load();
    expect(loaded.length, 2);
    expect(loaded.first.label, 'Second');
    expect((await store.latest())?.label, 'Second');
  });

  test('deduplicates by id and by coordinates', () async {
    final store = await _store();
    await store.record(_place('a', label: 'Old label'));

    await store.record(_place('a', label: 'New label'));
    expect((await store.load()).length, 1);
    expect((await store.load()).first.label, 'New label');

    await store.record(
      _place('other-id', label: 'Same point', lat: 22.45, lng: 86.90),
    );
    expect((await store.load()).length, 1);
    expect((await store.load()).first.label, 'Same point');
  });

  test('keeps at most ten entries', () async {
    final store = await _store();

    for (var i = 0; i < 12; i++) {
      await store.record(
        _place('place-$i', label: 'Place $i', lat: 22.4 + i / 1000),
      );
    }

    final loaded = await store.load();
    expect(loaded.length, RecentDestinationsStore.maxEntries);
    expect(loaded.first.label, 'Place 11');
    expect(loaded.last.label, 'Place 2');
  });

  test('persists across store instances', () async {
    final store = await _store();
    await store.record(_place('a', label: 'Persisted'));

    final reopened = await _store();
    final loaded = await reopened.load();
    expect(loaded.length, 1);
    expect(loaded.first.label, 'Persisted');
    expect(loaded.first.type, PlaceType.other);
  });

  test('corrupt stored data returns an empty list', () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(RecentDestinationsStore.storageKey, '{not json');
    final store = RecentDestinationsStore(preferences: prefs);

    expect(await store.load(), isEmpty);
  });

  test('invalid coordinates are never stored', () async {
    final store = await _store();

    await store.record(
      const SavedLocation(
        id: 'bad',
        label: 'Null island',
        coordinate: LatLng(0, 0),
      ),
    );

    expect(await store.load(), isEmpty);
  });
}
