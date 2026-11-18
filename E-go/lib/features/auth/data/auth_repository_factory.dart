import 'package:flutter/foundation.dart';

import '../../../core/config/auth_config.dart';
import '../domain/repositories/auth_repository.dart';
import 'repositories/mock_auth_repository.dart';

/// Creates the repository selected by `AUTH_MODE`.
///
/// Mock authentication is development-only. Release builds fail loudly rather
/// than silently shipping a fake authentication system.
AuthRepository createAuthRepository() {
  switch (AuthConfig.mode) {
    case AuthMode.mock:
      if (kReleaseMode) {
        throw StateError(
          'AUTH_MODE=mock is development-only. Implement a real '
          'AuthRepository and build with AUTH_MODE=api.',
        );
      }
      return MockAuthRepository();
    case AuthMode.api:
      throw UnimplementedError(
        'AUTH_MODE=api is not implemented. Add the production AuthRepository '
        'implementation to createAuthRepository().',
      );
  }
}
