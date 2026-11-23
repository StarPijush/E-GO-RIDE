import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:e_go/mock_data/mock_data.dart';

/// Persistent store for customer saved places.
/// Defaults to the 3 canonical Jhargram reference places if no user places are stored.
class SavedPlacesStore {
  SavedPlacesStore({SharedPreferences? preferences})
      : _preferences = preferences;

  static const String storageKey = 'ego.saved_places.v1';

  final SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async =>
      _preferences ?? await SharedPreferences.getInstance();

  /// Canonical defaults matching Reference Set B
  static List<SavedPlace> get defaultSavedPlaces => const [
        SavedPlace(
          id: 'home',
          label: 'Home',
          address: 'Ward 8, Kadamkanan, Jhargram',
          icon: Icons.home,
          type: SavedPlaceType.home,
          coordinate: LatLng(22.4580, 86.9080),
        ),
        SavedPlace(
          id: 'work',
          label: 'Work',
          address: 'Jhargram Court Complex, DM Office Rd',
          icon: Icons.work,
          type: SavedPlaceType.work,
          coordinate: LatLng(22.4510, 86.8990),
        ),
        SavedPlace(
          id: 'station',
          label: 'Jhargram Railway Station',
          address: 'Station Road, SER Zone',
          icon: Icons.star,
          type: SavedPlaceType.other,
          coordinate: LatLng(22.4529, 86.9003),
        ),
      ];

  Future<List<SavedPlace>> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      return List<SavedPlace>.from(defaultSavedPlaces);
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return List<SavedPlace>.from(defaultSavedPlaces);

      final loaded = <SavedPlace>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic> && item is! Map) continue;
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['id'] as String?;
        final label = map['label'] as String?;
        final address = map['address'] as String?;
        final lat = (map['lat'] as num?)?.toDouble();
        final lng = (map['lng'] as num?)?.toDouble();
        final typeStr = map['type'] as String?;
        final iconCode = map['iconCode'] as int?;

        if (id == null || label == null) continue;

        SavedPlaceType type = SavedPlaceType.other;
        if (typeStr == 'home') type = SavedPlaceType.home;
        if (typeStr == 'work') type = SavedPlaceType.work;

        IconData icon;
        if (iconCode != null) {
          icon = IconData(iconCode, fontFamily: 'MaterialIcons');
        } else if (type == SavedPlaceType.home) {
          icon = Icons.home;
        } else if (type == SavedPlaceType.work) {
          icon = Icons.work;
        } else {
          icon = Icons.star;
        }

        loaded.add(
          SavedPlace(
            id: id,
            label: label,
            address: address ?? '',
            icon: icon,
            type: type,
            coordinate: lat != null && lng != null ? LatLng(lat, lng) : null,
          ),
        );
      }
      return loaded.isEmpty ? List<SavedPlace>.from(defaultSavedPlaces) : loaded;
    } catch (_) {
      return List<SavedPlace>.from(defaultSavedPlaces);
    }
  }

  Future<void> save(List<SavedPlace> places) async {
    final prefs = await _prefs();
    final list = places.map((p) => {
          'id': p.id,
          'label': p.label,
          'address': p.address,
          'lat': p.coordinate?.latitude,
          'lng': p.coordinate?.longitude,
          'type': p.type.name,
          'iconCode': p.icon.codePoint,
        }).toList(growable: false);

    await prefs.setString(storageKey, jsonEncode(list));
  }

  Future<void> addPlace(SavedPlace place) async {
    final places = await load();
    places.add(place);
    await save(places);
  }

  Future<void> updatePlace(SavedPlace updated) async {
    final places = await load();
    final index = places.indexWhere((p) => p.id == updated.id);
    if (index >= 0) {
      places[index] = updated;
      await save(places);
    }
  }

  Future<void> deletePlace(String id) async {
    final places = await load();
    places.removeWhere((p) => p.id == id);
    await save(places);
  }
}
