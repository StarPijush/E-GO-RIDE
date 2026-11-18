// Persistent "recent destinations" for the customer app.
//
// Only successfully placed orders are recorded. There is no fake seed data.

import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_go/core/booking_validation.dart';
import 'package:e_go/features/location/domain/location_model.dart';

class RecentDestinationsStore {
  RecentDestinationsStore({SharedPreferences? preferences})
    : _preferences = preferences;

  static const String storageKey = 'ego.recent_destinations.v1';
  static const int maxEntries = 10;

  final SharedPreferences? _preferences;

  Future<SharedPreferences> _prefs() async =>
      _preferences ?? await SharedPreferences.getInstance();

  Future<List<SavedLocation>> load() async {
    final prefs = await _prefs();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      final loaded = <SavedLocation>[];
      for (final item in decoded) {
        if (item is! Map) continue;
        final location = _fromJson(item);
        if (location == null) continue;
        if (loaded.any((existing) => _isSamePlace(existing, location))) {
          continue;
        }
        loaded.add(location);
        if (loaded.length == maxEntries) break;
      }
      return loaded;
    } catch (_) {
      return const [];
    }
  }

  Future<SavedLocation?> latest() async {
    final recent = await load();
    return recent.isEmpty ? null : recent.first;
  }

  /// Adds [location] at the front, deduplicates by id/coordinates and keeps
  /// at most [maxEntries].
  Future<void> record(SavedLocation location) async {
    if (!isValidCoordinate(location.coordinate)) return;

    final prefs = await _prefs();
    final existing = await load();
    final updated = <SavedLocation>[
      SavedLocation(
        id: location.id,
        label: location.label,
        subtitle: location.subtitle,
        coordinate: location.coordinate,
        icon: location.icon ?? iconForPlaceType(location.type),
        type: location.type,
        createdAt: DateTime.now(),
      ),
      ...existing.where((item) => !_isSamePlace(item, location)),
    ];

    final trimmed = updated.take(maxEntries).toList(growable: false);
    await prefs.setString(
      storageKey,
      jsonEncode(trimmed.map(_toJson).toList(growable: false)),
    );
  }

  bool _isSamePlace(SavedLocation a, SavedLocation b) {
    if (a.id == b.id) return true;
    return _roundCoordinate(a.coordinate.latitude) ==
            _roundCoordinate(b.coordinate.latitude) &&
        _roundCoordinate(a.coordinate.longitude) ==
            _roundCoordinate(b.coordinate.longitude);
  }

  double _roundCoordinate(double value) =>
      double.parse(value.toStringAsFixed(5));

  Map<String, dynamic> _toJson(SavedLocation location) {
    return {
      'id': location.id,
      'label': location.label,
      'subtitle': location.subtitle,
      'lat': location.coordinate.latitude,
      'lng': location.coordinate.longitude,
      'type': location.type.name,
      'createdAt': location.createdAt?.toIso8601String(),
    };
  }

  SavedLocation? _fromJson(Map<dynamic, dynamic> json) {
    final id = json['id'];
    final label = json['label'];
    final lat = json['lat'];
    final lng = json['lng'];
    if (id is! String || id.isEmpty) return null;
    if (label is! String || label.isEmpty) return null;
    if (lat is! num || lng is! num) return null;

    final coordinate = LatLng(lat.toDouble(), lng.toDouble());
    if (!isValidCoordinate(coordinate)) return null;

    final typeName = json['type'];
    final type = PlaceType.values.firstWhere(
      (value) => value.name == typeName,
      orElse: () => PlaceType.other,
    );
    final subtitle = json['subtitle'];
    final createdAt = json['createdAt'];

    return SavedLocation(
      id: id,
      label: label,
      subtitle: subtitle is String ? subtitle : null,
      coordinate: coordinate,
      icon: iconForPlaceType(type),
      type: type,
      createdAt: createdAt is String ? DateTime.tryParse(createdAt) : null,
    );
  }
}
