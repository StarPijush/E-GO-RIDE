import 'dart:io';

/// Native (VM / IO) implementation of platform environment inspection.
bool isFlutterTestImpl() {
  try {
    return Platform.environment.containsKey('FLUTTER_TEST');
  } catch (_) {
    return false;
  }
}
