import 'platform_env_stub.dart'
    if (dart.library.io) 'platform_env_io.dart';

/// Returns true if currently running within a Flutter test environment.
/// Safe for cross-platform usage (never accesses `dart:io` on Web).
bool isFlutterTest() => isFlutterTestImpl();
