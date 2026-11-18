/// Authentication mode configuration.
///
/// Set at build time:
/// `flutter run --dart-define=AUTH_MODE=mock`
/// `flutter build apk --dart-define=AUTH_MODE=api`
enum AuthMode { mock, api }

abstract final class AuthConfig {
  /// Compile-time authentication mode. Defaults to mock for local development.
  static const String rawMode = String.fromEnvironment(
    'AUTH_MODE',
    defaultValue: 'mock',
  );

  static AuthMode get mode {
    switch (rawMode.toLowerCase()) {
      case 'mock':
        return AuthMode.mock;
      case 'api':
        return AuthMode.api;
      default:
        throw StateError(
          'Unsupported AUTH_MODE="$rawMode". Use AUTH_MODE=mock or AUTH_MODE=api.',
        );
    }
  }

  static bool get isMockMode => mode == AuthMode.mock;
}
