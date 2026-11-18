import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// Returns an in-memory transparent tile so map widget tests never touch the
/// network.
class TestTileProvider extends TileProvider {
  TestTileProvider();

  static final ImageProvider _tile = MemoryImage(
    base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAAXNSR0IArs4c'
      '6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAALSURB'
      'VBhXY2AAAgAABQABqtXIUQAAAABJRU5ErkJggg==',
    ),
  );

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      _tile;
}
